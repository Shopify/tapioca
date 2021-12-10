# typed: strict
# frozen_string_literal: true

module Tapioca
  module Generators
    class Dsl < Base
      sig do
        params(
          requested_constants: T::Array[String],
          outpath: Pathname,
          generators: T::Array[String],
          exclude_generators: T::Array[String],
          file_header: T::Boolean,
          compiler_path: String,
          tapioca_path: String,
          default_command: String,
          file_writer: Thor::Actions,
          should_verify: T::Boolean,
          quiet: T::Boolean,
          verbose: T::Boolean,
          number_of_workers: T.nilable(Integer),
        ).void
      end
      def initialize(
        requested_constants:,
        outpath:,
        generators:,
        exclude_generators:,
        file_header:,
        compiler_path:,
        tapioca_path:,
        default_command:,
        file_writer: FileWriter.new,
        should_verify: false,
        quiet: false,
        verbose: false,
        number_of_workers: nil
      )
        @requested_constants = requested_constants
        @outpath = outpath
        @generators = generators
        @exclude_generators = exclude_generators
        @file_header = file_header
        @compiler_path = compiler_path
        @tapioca_path = tapioca_path
        @should_verify = should_verify
        @quiet = quiet
        @verbose = verbose
        @number_of_workers = number_of_workers

        super(default_command: default_command, file_writer: file_writer)

        @loader = T.let(nil, T.nilable(Loader))
      end

      sig { override.void }
      def generate
        load_dsl_extensions
        load_application(eager_load: @requested_constants.empty?)
        abort_if_pending_migrations!
        load_dsl_generators

        if @should_verify
          say("Checking for out-of-date RBIs...")
        else
          say("Compiling DSL RBI files...")
        end
        say("")

        outpath = @should_verify ? Pathname.new(Dir.mktmpdir) : @outpath
        rbi_files_to_purge = existing_rbi_filenames(@requested_constants)

        compiler = Compilers::DslCompiler.new(
          requested_constants: constantize(@requested_constants),
          requested_generators: constantize_generators(@generators),
          excluded_generators: constantize_generators(@exclude_generators),
          error_handler: ->(error) {
            say_error(error, :bold, :red)
          },
          number_of_workers: @number_of_workers
        )

        processed_files = compiler.run do |constant, contents|
          constant_name = T.must(Reflection.name_of(constant))

          if @verbose && !@quiet
            say_status(:processing, constant_name, :yellow)
          end

          compile_dsl_rbi(
            constant_name,
            contents,
            outpath: outpath,
            quiet: @should_verify || @quiet && !@verbose
          )
        end

        processed_files.each { |filename| rbi_files_to_purge.delete(T.must(filename)) }

        say("")

        if @should_verify
          perform_dsl_verification(outpath)
        else
          purge_stale_dsl_rbi_files(rbi_files_to_purge)

          say("Done", :green)

          say("All operations performed in working directory.", [:green, :bold])
          say("Please review changes and commit them.", [:green, :bold])
        end
      end

      private

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
          "#{@compiler_path}/*.rb",
          "#{@tapioca_path}/generators/**/*.rb",
        ]).each do |generator|
          require File.expand_path(generator)
        end

        say("Done", :green)
      end

      sig { params(requested_constants: T::Array[String], path: Pathname).returns(T::Set[Pathname]) }
      def existing_rbi_filenames(requested_constants, path: @outpath)
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
            filename = dsl_rbi_filename(name)
            remove_file(filename) if File.file?(filename)
          end

          exit(1)
        end

        constant_map.values
      end

      sig { params(generator_names: T::Array[String]).returns(T::Array[T.class_of(Compilers::Dsl::Base)]) }
      def constantize_generators(generator_names)
        generator_map = generator_names.to_h do |name|
          [name, Compilers::Dsl::Base.resolve(name)]
        end

        unprocessable_generators = generator_map.select { |_, v| v.nil? }
        unless unprocessable_generators.empty?
          unprocessable_generators.each do |name, _|
            say("Error: Cannot find generator '#{name}'", :red)
          end

          exit(1)
        end

        T.cast(generator_map.values, T::Array[T.class_of(Compilers::Dsl::Base)])
      end

      sig do
        params(
          constant_name: String,
          rbi: RBI::File,
          outpath: Pathname,
          quiet: T::Boolean
        ).returns(T.nilable(Pathname))
      end
      def compile_dsl_rbi(constant_name, rbi, outpath: @outpath, quiet: false)
        return if rbi.empty?

        filename = outpath / rbi_filename_for(constant_name)

        rbi.set_file_header(
          generate_command_for(constant_name),
          reason: "dynamic methods in `#{constant_name}`",
          display_heading: @file_header
        )

        create_file(filename, rbi.transformed_string, verbose: !quiet)

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
            remove_file(filename)
          end
          say("")
        end
      end

      sig { params(constant_name: String).returns(Pathname) }
      def dsl_rbi_filename(constant_name)
        @outpath / "#{underscore(constant_name)}.rbi"
      end

      sig { params(tmp_dir: Pathname).returns(T::Hash[String, Symbol]) }
      def verify_dsl_rbi(tmp_dir:)
        diff = {}

        existing_rbis = rbi_files_in(@outpath)
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
          filename unless FileUtils.identical?(@outpath / filename, tmp_dir / filename)
        end.compact

        changed_files.each do |file|
          diff[file] = :changed
        end

        diff
      end

      sig { params(cause: Symbol, files: T::Array[String]).returns(String) }
      def build_error_for_files(cause, files)
        filenames = files.map do |file|
          @outpath / file
        end.join("\n  - ")

        "  File(s) #{cause}:\n  - #{filenames}"
      end

      sig { params(diff: T::Hash[String, Symbol], command: String).void }
      def report_diff_and_exit_if_out_of_date(diff, command)
        if diff.empty?
          say("Nothing to do, all RBIs are up-to-date.")
        else
          say("RBI files are out-of-date. In your development environment, please run:", :green)
          say("  `#{@default_command} #{command}`", [:green, :bold])
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

      sig { returns(Loader) }
      def loader
        @loader ||= Loader.new
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

      sig { params(constant: String).returns(String) }
      def rbi_filename_for(constant)
        underscore(constant) + ".rbi"
      end

      sig { params(constant: String).returns(String) }
      def generate_command_for(constant)
        "#{@default_command} dsl #{constant}"
      end

      sig { void }
      def load_dsl_extensions
        Dir["#{__dir__}/../compilers/dsl/extensions/*.rb"].sort.each { |f| require(f) }
      end
    end
  end
end
