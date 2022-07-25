# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class Dsl < Command
      include SorbetHelper
      include RBIFilesHelper

      sig do
        params(
          requested_constants: T::Array[String],
          outpath: Pathname,
          only: T::Array[String],
          exclude: T::Array[String],
          file_header: T::Boolean,
          tapioca_path: String,
          should_verify: T::Boolean,
          quiet: T::Boolean,
          verbose: T::Boolean,
          number_of_workers: T.nilable(Integer),
          auto_strictness: T::Boolean,
          gem_dir: String,
          rbi_formatter: RBIFormatter
        ).void
      end
      def initialize(
        requested_constants:,
        outpath:,
        only:,
        exclude:,
        file_header:,
        tapioca_path:,
        should_verify: false,
        quiet: false,
        verbose: false,
        number_of_workers: nil,
        auto_strictness: true,
        gem_dir: DEFAULT_GEM_DIR,
        rbi_formatter: DEFAULT_RBI_FORMATTER
      )
        @requested_constants = requested_constants
        @outpath = outpath
        @only = only
        @exclude = exclude
        @file_header = file_header
        @tapioca_path = tapioca_path
        @should_verify = should_verify
        @quiet = quiet
        @verbose = verbose
        @number_of_workers = number_of_workers
        @auto_strictness = auto_strictness
        @gem_dir = gem_dir
        @rbi_formatter = rbi_formatter

        super()
      end

      sig { override.void }
      def execute
        Loaders::Dsl.load_application(
          tapioca_path: @tapioca_path,
          eager_load: @requested_constants.empty?
        )

        if @should_verify
          say("Checking for out-of-date RBIs...")
        else
          say("Compiling DSL RBI files...")
        end
        say("")

        outpath = @should_verify ? Pathname.new(Dir.mktmpdir) : @outpath
        rbi_files_to_purge = existing_rbi_filenames(@requested_constants)

        pipeline = Tapioca::Dsl::Pipeline.new(
          requested_constants: constantize(@requested_constants),
          requested_compilers: constantize_compilers(@only),
          excluded_compilers: constantize_compilers(@exclude),
          error_handler: ->(error) {
            say_error(error, :bold, :red)
          },
          number_of_workers: @number_of_workers
        )

        processed_files = pipeline.run do |constant, contents|
          constant_name = T.must(Tapioca::Runtime::Reflection.name_of(constant))

          if @verbose && !@quiet
            say_status(:processing, constant_name, :yellow)
          end

          compile_dsl_rbi(
            constant_name,
            contents,
            outpath: outpath,
            quiet: @should_verify || (@quiet && !@verbose)
          )
        end

        processed_files.each { |filename| rbi_files_to_purge.delete(T.must(filename)) }

        say("")

        if @should_verify
          perform_dsl_verification(outpath)
        else
          purge_stale_dsl_rbi_files(rbi_files_to_purge)
          say("Done", :green)

          if @auto_strictness
            say("")
            validate_rbi_files(
              command: default_command(:dsl, @requested_constants.join(" ")),
              gem_dir: @gem_dir,
              dsl_dir: @outpath.to_s,
              auto_strictness: @auto_strictness,
              compilers: pipeline.compilers
            )
          end

          say("All operations performed in working directory.", [:green, :bold])
          say("Please review changes and commit them.", [:green, :bold])
        end
      end

      private

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
        constant_map = constant_names.to_h do |name|
          [name, Object.const_get(name)]
        rescue NameError
          [name, nil]
        end

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

      sig { params(compiler_names: T::Array[String]).returns(T::Array[T.class_of(Tapioca::Dsl::Compiler)]) }
      def constantize_compilers(compiler_names)
        compiler_map = compiler_names.to_h do |name|
          [name, resolve(name)]
        end

        unprocessable_compilers = compiler_map.select { |_, v| v.nil? }
        unless unprocessable_compilers.empty?
          unprocessable_compilers.each do |name, _|
            say("Error: Cannot find compiler '#{name}'", :red)
          end

          exit(1)
        end

        T.cast(compiler_map.values, T::Array[T.class_of(Tapioca::Dsl::Compiler)])
      end

      sig { params(name: String).returns(T.nilable(T.class_of(Tapioca::Dsl::Compiler))) }
      def resolve(name)
        # Try to find built-in tapioca compiler first, then globally defined compiler.
        potentials = Tapioca::Dsl::Compilers::NAMESPACES.map do |namespace|
          Object.const_get(namespace + name)
        rescue NameError
          # Skip if we can't find compiler by the potential name
          nil
        end

        potentials.compact.first
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

        @rbi_formatter.write_header!(
          rbi,
          generate_command_for(constant_name),
          reason: "dynamic methods in `#{constant_name}`"
        ) if @file_header

        rbi_string = @rbi_formatter.print_file(rbi)
        create_file(filename, rbi_string, verbose: !quiet)

        filename
      end

      sig { params(dir: Pathname).void }
      def perform_dsl_verification(dir)
        diff = verify_dsl_rbi(tmp_dir: dir)

        report_diff_and_exit_if_out_of_date(diff, :dsl)
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

      sig { params(diff: T::Hash[String, Symbol], command: Symbol).void }
      def report_diff_and_exit_if_out_of_date(diff, command)
        if diff.empty?
          say("Nothing to do, all RBIs are up-to-date.")
        else
          say("RBI files are out-of-date. In your development environment, please run:", :green)
          say("  `#{default_command(command)}`", [:green, :bold])
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
        default_command(:dsl, constant)
      end
    end
  end
end
