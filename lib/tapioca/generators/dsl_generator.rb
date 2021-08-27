# typed: strict
# frozen_string_literal: true

require "tapioca/generators/base_generator"

module Tapioca
  module Generators
    class DslGenerator < BaseGenerator
      extend(T::Sig)

      sig { override.void }
      def generate
        build_dsl([])
      end

      sig { override.params(error: String).void }
      def error_handler(error)
      end

      private

      sig { params(requested_constants: T::Array[String], should_verify: T::Boolean).void }
      def build_dsl(requested_constants, should_verify: false)
        load_application(eager_load: requested_constants.empty?)
        load_dsl_generators

        outpath = should_verify ? Pathname.new(Dir.mktmpdir) : config.outpath
        rbi_files_to_purge = existing_rbi_filenames(requested_constants)

        compiler = Compilers::DslCompiler.new(
          requested_constants: constantize(requested_constants),
          requested_generators: constantize_generators(config.generators),
          excluded_generators: constantize_generators(config.exclude_generators),
          error_handler: ->(error) { error_handler(error) }
        )

        compiler.run do |constant, contents|
          constant_name = T.must(Reflection.name_of(constant))

          filename = compile_dsl_rbi(
            constant_name,
            contents,
            outpath: outpath,
          )

          if filename
            rbi_files_to_purge.delete(filename)
          end
        end

        if should_verify
          perform_dsl_verification(outpath)
        else
          purge_stale_dsl_rbi_files(rbi_files_to_purge)
        end
      end

      sig { params(eager_load: T::Boolean).void }
      def load_application(eager_load:)
        loader.load_rails(
          environment_load: true,
          eager_load: eager_load
        )
      end

      sig { void }
      def load_dsl_generators
        Dir.glob([
          "#{__dir__}/compilers/dsl/*.rb",
          "#{Config::TAPIOCA_PATH}/generators/**/*.rb",
        ]).each do |generator|
          require File.expand_path(generator)
        end
      end

      sig { params(constant_name: String, contents: String, outpath: Pathname).returns(T.nilable(Pathname)) }
      def compile_dsl_rbi(constant_name, contents, outpath: config.outpath)
        return if contents.nil?

        rbi_name = constant_name.underscore + ".rbi"
        filename = outpath / rbi_name

        out = String.new
        out << rbi_header(
          "#{Config::DEFAULT_COMMAND} dsl #{constant_name}",
          reason: "dynamic methods in `#{constant_name}`"
        )
        out << contents

        FileUtils.mkdir_p(File.dirname(filename))
        File.write(filename, out)

        filename
      end

      sig { params(generator_names: T::Array[String]).returns(T::Array[T.class_of(Compilers::Dsl::Base)]) }
      def constantize_generators(generator_names)
        generator_map = generator_names.map do |name|
          # Try to find built-in tapioca generator first, then globally defined generator. The
          # explicit `break` ensures the class is returned, not the `potential_name`.
          generator_klass = ["Tapioca::Compilers::Dsl::#{name}", name].find do |potential_name|
            break Object.const_get(potential_name)
          rescue NameError
            # Skip if we can't find generator by the potential name
          end

          [name, generator_klass]
        end.to_h

        unprocessable_generators = generator_map.select { |_, v| v.nil? }
        unless unprocessable_generators.empty?
          exit(1)
        end

        generator_map.values
      end

      sig { params(files: T::Set[Pathname]).void }
      def purge_stale_dsl_rbi_files(files)
        if files.any?
          files.sort.each do |filename|
            remove(filename)
          end
        end
      end

      sig { params(path: Pathname).returns(T::Array[Pathname]) }
      def rbi_files_in(path)
        Pathname.glob(path / "**/*.rbi").map do |file|
          file.relative_path_from(path)
        end.sort
      end

      sig { params(tmp_dir: Pathname).returns(T::Hash[String, Symbol]) }
      def verify_dsl_rbi(tmp_dir:)
        diff = {}

        existing_rbis = rbi_files_in(config.outpath)
        new_rbis = rbi_files_in(tmp_dir)

        added_files = (new_rbis - existing_rbis)

        added_files.each do |file|
          diff[file] = :added
        end

        removed_files = (existing_rbis - new_rbis)

        removed_files.each do |file|
          diff[file] = :removed
        end

        common_files = (existing_rbis & new_rbis)

        changed_files = common_files.map do |filename|
          filename unless FileUtils.identical?(config.outpath / filename, tmp_dir / filename)
        end.compact

        changed_files.each do |file|
          diff[file] = :changed
        end

        diff
      end

      sig { params(cause: Symbol, files: T::Array[String]).returns(String) }
      def build_error_for_files(cause, files)
        filenames = files.map do |file|
          config.outpath / file
        end.join("\n  - ")

        "  File(s) #{cause}:\n  - #{filenames}"
      end

      sig { params(diff: T::Hash[String, Symbol]).void }
      def report_diff_and_exit_if_out_of_date(diff)
        unless diff.empty?
          diff.group_by(&:last).sort.each do |cause, diff_for_cause|
            puts(build_error_for_files(cause, diff_for_cause.map(&:first)))
          end

          exit(1)
        end
      end

      sig { params(dir: Pathname).void }
      def perform_dsl_verification(dir)
        diff = verify_dsl_rbi(tmp_dir: dir)

        report_diff_and_exit_if_out_of_date(diff)
      ensure
        FileUtils.remove_entry(dir)
      end
    end
  end
end
