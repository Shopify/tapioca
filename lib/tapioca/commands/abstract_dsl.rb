# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    # @abstract
    class AbstractDsl < CommandWithoutTracker
      include SorbetHelper
      include RBIFilesHelper

      #: (
      #|   requested_constants: Array[String],
      #|   requested_paths: Array[Pathname],
      #|   outpath: Pathname,
      #|   only: Array[String],
      #|   exclude: Array[String],
      #|   file_header: bool,
      #|   tapioca_path: String,
      #|   ?skip_constant: Array[String],
      #|   ?quiet: bool,
      #|   ?verbose: bool,
      #|   ?number_of_workers: Integer?,
      #|   ?auto_strictness: bool,
      #|   ?gem_dir: String,
      #|   ?rbi_formatter: RBIFormatter,
      #|   ?app_root: String,
      #|   ?halt_upon_load_error: bool,
      #|   ?compiler_options: Hash[String, untyped],
      #|   ?lsp_addon: bool
      #| ) -> void
      def initialize(
        requested_constants:,
        requested_paths:,
        outpath:,
        only:,
        exclude:,
        file_header:,
        tapioca_path:,
        skip_constant: [],
        quiet: false,
        verbose: false,
        number_of_workers: nil,
        auto_strictness: true,
        gem_dir: DEFAULT_GEM_DIR,
        rbi_formatter: DEFAULT_RBI_FORMATTER,
        app_root: ".",
        halt_upon_load_error: true,
        compiler_options: {},
        lsp_addon: false
      )
        @requested_constants = requested_constants
        @requested_paths = requested_paths
        @outpath = outpath
        @only = only
        @exclude = exclude
        @file_header = file_header
        @tapioca_path = tapioca_path
        @quiet = quiet
        @verbose = verbose
        @number_of_workers = number_of_workers
        @auto_strictness = auto_strictness
        @gem_dir = gem_dir
        @rbi_formatter = rbi_formatter
        @app_root = app_root
        @halt_upon_load_error = halt_upon_load_error
        @skip_constant = skip_constant
        @compiler_options = compiler_options
        @lsp_addon = lsp_addon

        super()
      end

      private

      #: (Pathname outpath, quiet: bool) -> Set[Pathname]
      def generate_dsl_rbi_files(outpath, quiet:)
        if @lsp_addon
          pipeline.active_compilers.each(&:reset_state)
        end

        existing_rbi_files = existing_rbi_filenames(all_requested_constants)

        generated_files = pipeline.run do |constant, contents|
          constant_name = T.must(Tapioca::Runtime::Reflection.name_of(constant))

          if @verbose && !@quiet
            say_status(:processing, constant_name, :yellow)
          end

          compile_dsl_rbi(
            constant_name,
            contents,
            outpath: outpath,
            quiet: quiet,
          )
        end.compact

        files_to_purge = existing_rbi_files - generated_files

        files_to_purge
      end

      #: -> Array[String]
      def all_requested_constants
        @all_requested_constants ||= @requested_constants + constants_from_requested_paths #: Array[String]?
      end

      #: -> Tapioca::Dsl::Pipeline
      def pipeline
        @pipeline ||= create_pipeline #: Tapioca::Dsl::Pipeline?
      end

      #: -> void
      def load_application
        # Loaded ahead of time when using the add-on to avoid reloading multiple times
        return if @lsp_addon

        Loaders::Dsl.load_application(
          tapioca_path: @tapioca_path,
          eager_load: @requested_constants.empty? && @requested_paths.empty?,
          app_root: @app_root,
          halt_upon_load_error: @halt_upon_load_error,
        )
      end

      #: -> Tapioca::Dsl::Pipeline
      def create_pipeline
        error_handler = if @lsp_addon
          ->(error) {
            say(error)
          }
        else
          ->(error) {
            say_error(error, :bold, :red)
          }
        end
        Tapioca::Dsl::Pipeline.new(
          requested_constants:
            constantize(@requested_constants) + constantize(constants_from_requested_paths, ignore_missing: true),
          requested_paths: @requested_paths,
          requested_compilers: constantize_compilers(@only),
          excluded_compilers: constantize_compilers(@exclude),
          error_handler: error_handler,
          skipped_constants: constantize(@skip_constant, ignore_missing: true),
          number_of_workers: @number_of_workers,
          compiler_options: @compiler_options,
          lsp_addon: @lsp_addon,
        )
      end

      #: (Array[String] requested_constants, ?path: Pathname) -> Set[Pathname]
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

      #: (Array[String] constant_names, ?ignore_missing: bool) -> Array[Module]
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

          raise Tapioca::Error, ""
        end

        processable_constants
          .map { |_, constant| constant }
          .grep(Module)
      end

      #: (Array[String] compiler_names) -> Array[singleton(Tapioca::Dsl::Compiler)]
      def constantize_compilers(compiler_names)
        compiler_map = compiler_names.to_h do |name|
          [name, resolve(name)]
        end

        unprocessable_compilers = compiler_map.select { |_, v| v.nil? }

        unless unprocessable_compilers.empty?
          message = unprocessable_compilers.map do |name, _|
            set_color("Warning: Cannot find compiler '#{name}'", :yellow)
          end.join("\n")

          say(message)
          say("")
        end

        T.cast(compiler_map.values, T::Array[T.class_of(Tapioca::Dsl::Compiler)])
      end

      #: (String name) -> singleton(Tapioca::Dsl::Compiler)?
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

      #: (String constant_name, RBI::File rbi, ?outpath: Pathname, ?quiet: bool) -> Pathname?
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

      #: (Pathname dir) -> void
      def perform_dsl_verification(dir)
        diff = verify_dsl_rbi(tmp_dir: dir)

        report_diff_and_exit_if_out_of_date(diff, :dsl)
      ensure
        FileUtils.remove_entry(dir)
      end

      #: (Set[Pathname] files) -> void
      def purge_stale_dsl_rbi_files(files)
        if files.any?
          say("Removing stale RBI files...")

          files.sort.each do |filename|
            remove_file(filename)
          end
          say("")
        end
      end

      #: (String constant_name) -> Pathname
      def dsl_rbi_filename(constant_name)
        @outpath / "#{underscore(constant_name)}.rbi"
      end

      #: (tmp_dir: Pathname) -> Hash[String, Symbol]
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

      #: (Symbol cause, Array[String] files) -> String
      def build_error_for_files(cause, files)
        filenames = files.map do |file|
          @outpath / file
        end.join("\n  - ")

        "  File(s) #{cause}:\n  - #{filenames}"
      end

      #: (Hash[String, Symbol] diff, Symbol command) -> void
      def report_diff_and_exit_if_out_of_date(diff, command)
        if diff.empty?
          say("Nothing to do, all RBIs are up-to-date.")
        else
          reasons = diff.group_by(&:last).sort.map do |cause, diff_for_cause|
            build_error_for_files(cause, diff_for_cause.map(&:first))
          end.join("\n")

          raise Tapioca::Error, <<~ERROR
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

      #: (Pathname path) -> Array[Pathname]
      def rbi_files_in(path)
        Pathname.glob(path / "**/*.rbi").map do |file|
          file.relative_path_from(path)
        end.sort
      end

      #: (String class_name) -> String
      def underscore(class_name)
        return class_name unless /[A-Z-]|::/.match?(class_name)

        word = class_name.to_s.gsub("::", "/")
        word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        word.tr!("-", "_")
        word.downcase!
        word
      end

      #: (String constant) -> String
      def rbi_filename_for(constant)
        underscore(constant) + ".rbi"
      end

      #: (String constant) -> String
      def generate_command_for(constant)
        default_command(:dsl, constant)
      end

      #: -> Array[String]
      def constants_from_requested_paths
        @constants_from_requested_paths ||=
          Static::SymbolLoader.symbols_from_paths(@requested_paths).to_a #: Array[String]?
      end
    end
  end
end
