# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class Gem < Command
      include SorbetHelper

      sig do
        params(
          gem_names: T::Array[String],
          exclude: T::Array[String],
          prerequire: T.nilable(String),
          postrequire: String,
          typed_overrides: T::Hash[String, String],
          outpath: Pathname,
          file_header: T::Boolean,
          doc: T::Boolean,
          include_exported_rbis: T::Boolean,
          number_of_workers: T.nilable(Integer),
          auto_strictness: T::Boolean,
          dsl_dir: String,
          rbi_formatter: RBIFormatter
        ).void
      end
      def initialize(
        gem_names:,
        exclude:,
        prerequire:,
        postrequire:,
        typed_overrides:,
        outpath:,
        file_header:,
        doc:,
        include_exported_rbis:,
        number_of_workers: nil,
        auto_strictness: true,
        dsl_dir: DEFAULT_DSL_DIR,
        rbi_formatter: DEFAULT_RBI_FORMATTER
      )
        @gem_names = gem_names
        @exclude = exclude
        @prerequire = prerequire
        @postrequire = postrequire
        @typed_overrides = typed_overrides
        @outpath = outpath
        @file_header = file_header
        @number_of_workers = number_of_workers
        @auto_strictness = auto_strictness
        @dsl_dir = dsl_dir
        @rbi_formatter = rbi_formatter

        super()

        @loader = T.let(nil, T.nilable(Loader))
        @bundle = T.let(nil, T.nilable(Gemfile))
        @existing_rbis = T.let(nil, T.nilable(T::Hash[String, String]))
        @expected_rbis = T.let(nil, T.nilable(T::Hash[String, String]))
        @doc = T.let(doc, T::Boolean)
        @include_exported_rbis = include_exported_rbis
      end

      sig { override.void }
      def execute
        require_gem_file

        gem_queue = gems_to_generate(@gem_names).reject { |gem| @exclude.include?(gem.name) }
        anything_done = [
          perform_removals,
          gem_queue.any?,
        ].any?

        Executor.new(gem_queue, number_of_workers: @number_of_workers).run_in_parallel do |gem|
          shell.indent do
            compile_gem_rbi(gem)
            puts
          end
        end

        if anything_done
          update_strictnesses(gem_queue.map(&:name), gem_dir: @outpath.to_s, dsl_dir: @dsl_dir) if @auto_strictness

          say("All operations performed in working directory.", [:green, :bold])
          say("Please review changes and commit them.", [:green, :bold])
        else
          say("No operations performed, all RBIs are up-to-date.", [:green, :bold])
        end
      end

      sig { params(should_verify: T::Boolean).void }
      def sync(should_verify: false)
        if should_verify
          say("Checking for out-of-date RBIs...")
          say("")
          perform_sync_verification
          return
        end

        anything_done = [
          perform_removals,
          perform_additions,
        ].any?

        if anything_done
          update_strictnesses([], gem_dir: @outpath.to_s, dsl_dir: @dsl_dir) if @auto_strictness

          say("All operations performed in working directory.", [:green, :bold])
          say("Please review changes and commit them.", [:green, :bold])
        else
          say("No operations performed, all RBIs are up-to-date.", [:green, :bold])
        end

        puts
      end

      private

      sig { returns(Loader) }
      def loader
        @loader ||= Loader.new
      end

      sig { returns(Gemfile) }
      def bundle
        @bundle ||= Gemfile.new
      end

      sig { void }
      def require_gem_file
        say("Requiring all gems to prepare for compiling... ")
        begin
          loader.load_bundle(bundle, @prerequire, @postrequire)
        rescue LoadError => e
          explain_failed_require(@postrequire, e)
          exit(1)
        end

        Tapioca::Trackers::Autoload.eager_load_all!

        say(" Done", :green)
        unless bundle.missing_specs.empty?
          say("  completed with missing specs: ")
          say(bundle.missing_specs.join(", "), :yellow)
        end
        puts
      end

      sig { params(gem_names: T::Array[String]).returns(T::Array[Gemfile::GemSpec]) }
      def gems_to_generate(gem_names)
        return bundle.dependencies if gem_names.empty?

        gem_names.map do |gem_name|
          gem = bundle.gem(gem_name)
          if gem.nil?
            say("Error: Cannot find gem '#{gem_name}'", :red)
            exit(1)
          end
          gem
        end
      end

      sig { params(gem: Gemfile::GemSpec).void }
      def compile_gem_rbi(gem)
        gem_name = set_color(gem.name, :yellow, :bold)

        rbi = RBI::File.new(strictness: @typed_overrides[gem.name] || "true")

        @rbi_formatter.write_header!(rbi,
          default_command(:gem, gem.name),
          reason: "types exported from the `#{gem.name}` gem",) if @file_header

        rbi.root = Compilers::SymbolTableCompiler.new(gem, include_doc: @doc).compile

        merge_with_exported_rbi(gem, rbi) if @include_exported_rbis

        if rbi.empty?
          @rbi_formatter.write_empty_body_comment!(rbi)
          say("Compiled #{gem_name} (empty output)", :yellow)
        else
          say("Compiled #{gem_name}", :green)
        end

        rbi_string = @rbi_formatter.print_file(rbi)
        create_file(@outpath / gem.rbi_file_name, rbi_string)

        T.unsafe(Pathname).glob((@outpath / "#{gem.name}@*.rbi").to_s) do |file|
          remove_file(file) unless file.basename.to_s == gem.rbi_file_name
        end
      end

      sig { void }
      def perform_sync_verification
        diff = {}

        removed_rbis.each do |gem_name|
          filename = existing_rbi(gem_name)
          diff[filename] = :removed
        end

        added_rbis.each do |gem_name|
          filename = expected_rbi(gem_name)
          diff[filename] = gem_rbi_exists?(gem_name) ? :changed : :added
        end

        report_diff_and_exit_if_out_of_date(diff, :gem)
      end

      sig { void }
      def perform_removals
        say("Removing RBI files of gems that have been removed:", [:blue, :bold])
        puts

        anything_done = T.let(false, T::Boolean)

        gems = removed_rbis

        shell.indent do
          if gems.empty?
            say("Nothing to do.")
          else
            gems.each do |removed|
              filename = existing_rbi(removed)
              remove_file(filename)
            end

            anything_done = true
          end
        end

        puts

        anything_done
      end

      sig { void }
      def perform_additions
        say("Generating RBI files of gems that are added or updated:", [:blue, :bold])
        puts

        anything_done = T.let(false, T::Boolean)

        gems = added_rbis

        shell.indent do
          if gems.empty?
            say("Nothing to do.")
          else
            require_gem_file

            Executor.new(gems, number_of_workers: @number_of_workers).run_in_parallel do |gem_name|
              filename = expected_rbi(gem_name)

              if gem_rbi_exists?(gem_name)
                old_filename = existing_rbi(gem_name)
                move(old_filename, filename) unless old_filename == filename
              end

              gem = T.must(bundle.gem(gem_name))
              compile_gem_rbi(gem)
              puts
            end
          end

          anything_done = true
        end

        puts

        anything_done
      end

      sig { params(file: String, error: LoadError).void }
      def explain_failed_require(file, error)
        say_error("\n\nLoadError: #{error}", :bold, :red)
        say_error("\nTapioca could not load all the gems required by your application.", :yellow)
        say_error("If you populated ", :yellow)
        say_error("#{file} ", :bold, :blue)
        say_error("with ", :yellow)
        say_error("`#{default_command(:require)}`", :bold, :blue)
        say_error("you should probably review it and remove the faulty line.", :yellow)
      end

      sig { returns(T::Array[String]) }
      def removed_rbis
        (existing_rbis.keys - expected_rbis.keys).sort
      end

      sig { params(gem_name: String).returns(Pathname) }
      def existing_rbi(gem_name)
        gem_rbi_filename(gem_name, T.must(existing_rbis[gem_name]))
      end

      sig { returns(T::Array[String]) }
      def added_rbis
        expected_rbis.select do |name, value|
          existing_rbis[name] != value
        end.keys.sort
      end

      sig { params(gem_name: String).returns(Pathname) }
      def expected_rbi(gem_name)
        gem_rbi_filename(gem_name, T.must(expected_rbis[gem_name]))
      end

      sig { params(gem_name: String).returns(T::Boolean) }
      def gem_rbi_exists?(gem_name)
        existing_rbis.key?(gem_name)
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

      sig { params(old_filename: Pathname, new_filename: Pathname).void }
      def move(old_filename, new_filename)
        say("-> Moving: #{old_filename} to #{new_filename}")
        old_filename.rename(new_filename.to_s)
      end

      sig { returns(T::Hash[String, String]) }
      def existing_rbis
        @existing_rbis ||= Pathname.glob((@outpath / "*@*.rbi").to_s)
          .to_h { |f| T.cast(f.basename(".*").to_s.split("@", 2), [String, String]) }
      end

      sig { returns(T::Hash[String, String]) }
      def expected_rbis
        @expected_rbis ||= bundle.dependencies
          .reject { |gem| @exclude.include?(gem.name) }
          .to_h { |gem| [gem.name, gem.version.to_s] }
      end

      sig { params(gem_name: String, version: String).returns(Pathname) }
      def gem_rbi_filename(gem_name, version)
        @outpath / "#{gem_name}@#{version}.rbi"
      end

      sig { params(cause: Symbol, files: T::Array[String]).returns(String) }
      def build_error_for_files(cause, files)
        "  File(s) #{cause}:\n  - #{files.join("\n  - ")}"
      end

      sig { params(gem: Gemfile::GemSpec, file: RBI::File).void }
      def merge_with_exported_rbi(gem, file)
        return file unless gem.export_rbi_files?
        tree = gem.exported_rbi_tree

        unless tree.conflicts.empty?
          say_error("\n\n  RBIs exported by `#{gem.name}` contain conflicts and can't be used:", :yellow)

          tree.conflicts.each do |conflict|
            say_error("\n    #{conflict}", :yellow)
            say_error("    Found at:", :yellow)
            say_error("      #{conflict.left.loc}", :yellow)
            say_error("      #{conflict.right.loc}", :yellow)
          end

          return file
        end

        file.root = RBI::Rewriters::Merge.merge_trees(file.root, tree, keep: RBI::Rewriters::Merge::Keep::LEFT)
      rescue RBI::ParseError => e
        say_error("\n\n  RBIs exported by `#{gem.name}` contain errors and can't be used:", :yellow)
        say_error("Cause: #{e.message} (#{e.location})")
      end

      sig { params(gem_names: T::Array[String], gem_dir: String, dsl_dir: String).void }
      def update_strictnesses(gem_names, gem_dir: DEFAULT_GEM_DIR, dsl_dir: DEFAULT_DSL_DIR)
        return unless File.directory?(dsl_dir)

        error_url_base = Spoom::Sorbet::Errors::DEFAULT_ERROR_URL_BASE

        say("Typechecking RBI files... ")
        res = sorbet(
          "--no-config",
          "--error-url-base=#{error_url_base}",
          "--isolate-error-code 4010",
          dsl_dir,
          gem_dir
        )
        say(" Done", :green)

        errors = Spoom::Sorbet::Errors::Parser.parse_string(res.err)

        if errors.empty?
          say("No error found", [:green, :bold])
          return
        end

        files = []

        errors.each do |error|
          # Collect the file with error
          files << error.file
          error.more.each do |line|
            # Also collect the conflicting definition file paths
            next unless line.include?("Previous definition")
            files << line.split(":").first&.strip
          end
        end

        files
          .uniq
          .sort
          .select do |file|
            name = gem_name_from_rbi_path(file)
            file.start_with?(gem_dir) && (gem_names.empty? || gem_names.include?(name))
          end.each do |file|
            Spoom::Sorbet::Sigils.change_sigil_in_file(file, "false")
            say("\n  Changed strictness of #{file} to `typed: false` (conflicting with DSL files)", [:yellow, :bold])
          end

        say("\n")
      end

      sig { params(path: String).returns(String) }
      def gem_name_from_rbi_path(path)
        T.must(File.basename(path, ".rbi").split("@").first)
      end
    end
  end
end
