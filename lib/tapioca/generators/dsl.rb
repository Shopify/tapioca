# typed: strict
# frozen_string_literal: true

module Tapioca
  module Generators
    class Dsl < Base
      sig { params(config: Tapioca::Config).void }
      def initialize(config)
        @loader = T.let(nil, T.nilable(Tapioca::Loader))
        super(config)
      end

      sig { override.void }
      def generate
      end

      sig { override.params(error: Error).void }
      def handle_error(error)
      end

      sig do
        params(
          requested_constants: T::Array[String],
          should_verify: T::Boolean,
          quiet: T::Boolean,
          verbose: T::Boolean
        ).void
      end
      def build_dsl(requested_constants, should_verify: false, quiet: false, verbose: false)
        load_application(eager_load: requested_constants.empty?)
        abort_if_pending_migrations!
        load_dsl_generators

        if should_verify
          say("Checking for out-of-date RBIs...")
        else
          say("Compiling DSL RBI files...")
        end
        say("")

        outpath = should_verify ? Pathname.new(Dir.mktmpdir) : config.outpath
        rbi_files_to_purge = existing_rbi_filenames(requested_constants)

        compiler = Compilers::DslCompiler.new(
          requested_constants: constantize(requested_constants),
          requested_generators: constantize_generators(config.generators),
          excluded_generators: constantize_generators(config.exclude_generators),
          error_handler: ->(error) {
            say_error(error, :bold, :red)
          }
        )

        compiler.run do |constant, contents|
          constant_name = T.must(Reflection.name_of(constant))

          if verbose && !quiet
            say("Processing: ", [:yellow])
            say(constant_name)
          end

          filename = compile_dsl_rbi(
            constant_name,
            contents,
            outpath: outpath,
            quiet: should_verify || quiet && !verbose
          )

          if filename
            rbi_files_to_purge.delete(filename)
          end
        end
        say("")

        if should_verify
          perform_dsl_verification(outpath)
        else
          purge_stale_dsl_rbi_files(rbi_files_to_purge)

          say("Done", :green)

          say("All operations performed in working directory.", [:green, :bold])
          say("Please review changes and commit them.", [:green, :bold])
        end
      end

      sig { params(eager_load: T::Boolean).void }
      def load_application(eager_load:)
        say("Loading Rails application... ")

        loader.load_rails_application(
          environment_load: true,
          eager_load: eager_load
        )

        say("Done", :green)
      end

      sig { void }
      def abort_if_pending_migrations!
        return unless File.exist?("config/application.rb")
        return unless defined?(::Rake)

        Rails.application.load_tasks
        if Rake::Task.task_defined?("db:abort_if_pending_migrations")
          Rake::Task["db:abort_if_pending_migrations"].invoke
        end
      end

      sig { void }
      def load_dsl_generators
        say("Loading DSL generator classes... ")

        Dir.glob([
          "#{Tapioca::Config::DSL_COMPILERS_PATH}/*.rb",
          "#{Tapioca::Config::TAPIOCA_PATH}/generators/**/*.rb",
        ]).each do |generator|
          require File.expand_path(generator)
        end

        say("Done", :green)
      end

      sig { params(requested_constants: T::Array[String], path: Pathname).returns(T::Set[Pathname]) }
      def existing_rbi_filenames(requested_constants, path: config.outpath)
        filenames = if requested_constants.empty?
          Pathname.glob(path / "**/*.rbi")
        else
          requested_constants.map do |constant_name|
            dsl_rbi_filename(constant_name)
          end
        end

        filenames.to_set
      end

      sig { params(constant_names: T::Array[String]).returns(T::Array[Module]) }
      def constantize(constant_names)
        constant_map = constant_names.map do |name|
          [name, Object.const_get(name)]
        rescue NameError
          [name, nil]
        end.to_h

        unprocessable_constants = constant_map.select { |_, v| v.nil? }
        unless unprocessable_constants.empty?
          unprocessable_constants.each do |name, _|
            say("Error: Cannot find constant '#{name}'", :red)
            remove(dsl_rbi_filename(name))
          end

          exit(1)
        end

        constant_map.values
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
          unprocessable_generators.each do |name, _|
            say("Error: Cannot find generator '#{name}'", :red)
          end

          exit(1)
        end

        generator_map.values
      end

      sig do
        params(constant_name: String, contents: String, outpath: Pathname, quiet: T::Boolean)
          .returns(T.nilable(Pathname))
      end
      def compile_dsl_rbi(constant_name, contents, outpath: config.outpath, quiet: false)
        return if contents.nil?

        rbi_name = underscore(constant_name) + ".rbi"
        filename = outpath / rbi_name

        out = String.new
        out << rbi_header(
          "#{Tapioca::Config::DEFAULT_COMMAND} dsl #{constant_name}",
          reason: "dynamic methods in `#{constant_name}`"
        )
        out << contents

        FileUtils.mkdir_p(File.dirname(filename))
        File.write(filename, out)

        unless quiet
          say("Wrote: ", [:green])
          say(filename)
        end

        filename
      end

      sig { params(dir: Pathname).void }
      def perform_dsl_verification(dir)
        diff = verify_dsl_rbi(tmp_dir: dir)

        report_diff_and_exit_if_out_of_date(diff, "dsl")
      ensure
        FileUtils.remove_entry(dir)
      end

      sig { params(files: T::Set[Pathname]).void }
      def purge_stale_dsl_rbi_files(files)
        if files.any?
          say("Removing stale RBI files...")

          files.sort.each do |filename|
            remove(filename)
          end
          say("")
        end
      end

      sig { params(constant_name: String).returns(Pathname) }
      def dsl_rbi_filename(constant_name)
        config.outpath / "#{underscore(constant_name)}.rbi"
      end

      sig { params(command: String, reason: T.nilable(String), strictness: T.nilable(String)).returns(String) }
      def rbi_header(command, reason: nil, strictness: nil)
        statement = <<~HEAD
          # DO NOT EDIT MANUALLY
          # This is an autogenerated file for #{reason}.
          # Please instead update this file by running `#{command}`.
        HEAD

        sigil = <<~SIGIL if strictness
          # typed: #{strictness}
        SIGIL

        if config.file_header
          [statement, sigil].compact.join("\n").strip.concat("\n\n")
        elsif sigil
          sigil.strip.concat("\n\n")
        else
          ""
        end
      end

      sig { params(class_name: String).returns(String) }
      def underscore(class_name)
        return class_name unless /[A-Z-]|::/.match?(class_name)

        word = class_name.to_s.gsub("::", "/")
        word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        word.tr!("-", "_")
        word.downcase!
        word
      end

      sig { params(filename: Pathname).void }
      def remove(filename)
        return unless filename.exist?
        say("-- Removing: #{filename}")
        filename.unlink
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

      sig { params(diff: T::Hash[String, Symbol], command: String).void }
      def report_diff_and_exit_if_out_of_date(diff, command)
        if diff.empty?
          say("Nothing to do, all RBIs are up-to-date.")
        else
          say("RBI files are out-of-date. In your development environment, please run:", :green)
          say("  `#{Tapioca::Config::DEFAULT_COMMAND} #{command}`", [:green, :bold])
          say("Once it is complete, be sure to commit and push any changes", :green)

          say("")

          say("Reason:", [:red])
          diff.group_by(&:last).sort.each do |cause, diff_for_cause|
            say(build_error_for_files(cause, diff_for_cause.map(&:first)))
          end

          exit(1)
        end
      end

      sig { params(path: Pathname).returns(T::Array[Pathname]) }
      def rbi_files_in(path)
        Pathname.glob(path / "**/*.rbi").map do |file|
          file.relative_path_from(path)
        end.sort
      end

      sig { params(cause: Symbol, files: T::Array[String]).returns(String) }
      def build_error_for_files(cause, files)
        filenames = files.map do |file|
          config.outpath / file
        end.join("\n  - ")

        "  File(s) #{cause}:\n  - #{filenames}"
      end

      sig { params(message: String, color: T.any(Symbol, T::Array[Symbol])).void }
      def say_error(message = "", *color)
        force_new_line = (message.to_s !~ /( |\t)\Z/)
        # NOTE: This is a hack. We're no longer subclassing from Thor::Shell::Color
        # so we no longer have access to the prepare_message call.
        # We should update this to remove this.
        buffer = shell.send(:prepare_message, *T.unsafe([message, *T.unsafe(color)]))
        buffer << "\n" if force_new_line && !message.to_s.end_with?("\n")

        $stderr.print(buffer)
        $stderr.flush
      end

      private

      sig { returns(Tapioca::Loader) }
      def loader
        @loader ||= Tapioca::Loader.new
      end
    end
  end
end
