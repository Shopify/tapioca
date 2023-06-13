# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class Dsl < CommandWithoutTracker
      include SorbetHelper
      include RBIFilesHelper

      sig do
        params(
          requested_constants: T::Array[String],
          requested_paths: T::Array[Pathname],
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
          rbi_formatter: RBIFormatter,
          app_root: String,
          halt_upon_load_error: T::Boolean,
        ).void
      end
      def initialize(
        requested_constants:,
        requested_paths:,
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
        rbi_formatter: DEFAULT_RBI_FORMATTER,
        app_root: ".",
        halt_upon_load_error: true
      )
        @requested_constants = requested_constants
        @requested_paths = requested_paths
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
        @app_root = app_root
        @halt_upon_load_error = halt_upon_load_error

        super()
      end

      sig { void }
      def list_compilers
        Loaders::Dsl.load_application(
          tapioca_path: @tapioca_path,
          eager_load: @requested_constants.empty? && @requested_paths.empty?,
          app_root: @app_root,
          halt_upon_load_error: @halt_upon_load_error,
        )

        pipeline = create_pipeline

        say("")
        say("Loaded DSL compiler classes:")
        say("")

        table = pipeline.compilers.map do |compiler|
          status = if pipeline.active_compilers.include?(compiler)
            set_color("enabled", :green)
          else
            set_color("disabled", :red)
          end

          [compiler.name, status]
        end

        print_table(table, { indent: 2 })
      end

      sig { override.void }
      def execute
        Loaders::Dsl.load_application(
          tapioca_path: @tapioca_path,
          eager_load: @requested_constants.empty? && @requested_paths.empty?,
          app_root: @app_root,
          halt_upon_load_error: @halt_upon_load_error,
        )

        if @should_verify
          say("Checking for out-of-date RBIs...")
        else
          say("Compiling DSL RBI files...")
        end
        say("")

        all_requested_constants = @requested_constants + constants_from_requested_paths

        outpath = @should_verify ? Pathname.new(Dir.mktmpdir) : @outpath
        rbi_files_to_purge = existing_rbi_filenames(all_requested_constants)

        pipeline = create_pipeline

        processed_files = pipeline.run do |constant, contents|
          constant_name = T.must(Tapioca::Runtime::Reflection.name_of(constant))

          if @verbose && !@quiet
            say_status(:processing, constant_name, :yellow)
          end

          compile_dsl_rbi(
            constant_name,
            contents,
            outpath: outpath,
            quiet: @should_verify || (@quiet && !@verbose),
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
              command: default_command(:dsl, all_requested_constants.join(" ")),
              gem_dir: @gem_dir,
              dsl_dir: @outpath.to_s,
              auto_strictness: @auto_strictness,
              compilers: pipeline.active_compilers,
            )
          end

          say("All operations performed in working directory.", [:green, :bold])
          say("Please review changes and commit them.", [:green, :bold])
        end
      end

      private

      sig { returns(Tapioca::Dsl::Pipeline) }
      def create_pipeline
        Tapioca::Dsl::Pipeline.new(
          requested_constants:
            constantize(@requested_constants) + constantize(constants_from_requested_paths, ignore_missing: true),
          requested_paths: @requested_paths,
          requested_compilers: constantize_compilers(@only),
          excluded_compilers: constantize_compilers(@exclude),
          error_handler: ->(error) {
            say_error(error, :bold, :red)
          },
          number_of_workers: @number_of_workers,
        )
      end

      sig { params(requested_constants: T::Array[String], path: Pathname).returns(T::Set[Pathname]) }
      def existing_rbi_filenames(requested_constants, path: @outpath)
        filenames = if requested_constants.empty?
          Pathname.glob(path / "**/*.rbi")
        else
          requested_constants.filter_map do |constant_name|
            filename = dsl_rbi_filename(constant_name)
            filename if File.exist?(filename)
          end
        end

        filenames.to_set
      end

      sig { params(constant_names: T::Array[String], ignore_missing: T::Boolean).returns(T::Array[Module]) }
      def constantize(constant_names, ignore_missing: false)
        constant_map = constant_names.to_h do |name|
          [name, Object.const_get(name)]
        rescue NameError
          [name, nil]
        end

        processable_constants, unprocessable_constants = constant_map.partition { |_, v| !v.nil? }

        unless unprocessable_constants.empty? || ignore_missing
          unprocessable_constants.each do |name, _|
            say("Error: Cannot find constant '#{name}'", :red)
            filename = dsl_rbi_filename(name)
            remove_file(filename) if File.file?(filename)
          end

          raise Thor::Error, ""
        end

        processable_constants.map { |_, constant| constant }
      end

      sig { params(compiler_names: T::Array[String]).returns(T::Array[T.class_of(Tapioca::Dsl::Compiler)]) }
      def constantize_compilers(compiler_names)
        compiler_map = compiler_names.to_h do |name|
          [name, resolve(name)]
        end

        unprocessable_compilers = compiler_map.select { |_, v| v.nil? }

        unless unprocessable_compilers.empty?
          message = unprocessable_compilers.map do |name, _|
            set_color("Error: Cannot find compiler '#{name}'", :red)
          end.join("\n")

          raise Thor::Error, message
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
          quiet: T::Boolean,
        ).returns(T.nilable(Pathname))
      end
      def compile_dsl_rbi(constant_name, rbi, outpath: @outpath, quiet: false)
        return if rbi.empty?

        filename = outpath / rbi_filename_for(constant_name)

        @rbi_formatter.write_header!(
          rbi,
          generate_command_for(constant_name),
          reason: "dynamic methods in `#{constant_name}`",
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

        changed_files = common_files.filter_map do |filename|
          filename unless FileUtils.identical?(@outpath / filename, tmp_dir / filename)
        end

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
          reasons = diff.group_by(&:last).sort.map do |cause, diff_for_cause|
            build_error_for_files(cause, diff_for_cause.map(&:first))
          end.join("\n")

          raise Thor::Error, <<~ERROR
            #{set_color("RBI files are out-of-date. In your development environment, please run:", :green)}
              #{set_color("`#{default_command(command)}`", :green, :bold)}
            #{set_color("Once it is complete, be sure to commit and push any changes", :green)}
            If you don't observe any changes after running the command locally, ensure your database is in a good
            state e.g. run `bin/rails db:reset`

            #{set_color("Reason:", :red)}
            #{reasons}
          ERROR
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

      sig { returns(T::Array[String]) }
      def constants_from_requested_paths
        @constants_from_requested_paths ||= T.let(
          Static::SymbolLoader.symbols_from_paths(@requested_paths).to_a,
          T.nilable(T::Array[String]),
        )
      end
    end
  end
end
