# typed: strict
# frozen_string_literal: true

module Tapioca
  module Generators
    class Gem < Base
      # NOTE: This was previously _private_ which it actually wasn't, but should be extracted
      # to a module
      EMPTY_RBI_COMMENT = <<~CONTENT
        # THIS IS AN EMPTY RBI FILE.
        # see https://github.com/Shopify/tapioca/wiki/Manual-Gem-Requires
      CONTENT

      sig do
        params(
          gem_names: T::Array[String],
          gem_excludes: T::Array[String],
          prerequire: T.nilable(String),
          postrequire: String,
          typed_overrides: T::Hash[String, String],
          default_command: String,
          outpath: Pathname,
          file_header: T::Boolean,
          doc: T::Boolean,
        ).void
      end
      def initialize(
        gem_names:,
        gem_excludes:,
        prerequire:,
        postrequire:,
        typed_overrides:,
        default_command:,
        outpath:,
        file_header:,
        doc:
      )
        @gem_names = gem_names
        @gem_excludes = gem_excludes
        @prerequire = prerequire
        @postrequire = postrequire
        @typed_overrides = typed_overrides
        @outpath = outpath
        @file_header = file_header

        super(default_command: default_command)

        @loader = T.let(nil, T.nilable(Loader))
        @bundle = T.let(nil, T.nilable(Gemfile))
        @existing_rbis = T.let(nil, T.nilable(T::Hash[String, String]))
        @expected_rbis = T.let(nil, T.nilable(T::Hash[String, String]))
        @doc = T.let(doc, T::Boolean)
      end

      sig { override.void }
      def generate
        require_gem_file

        gems_to_generate(@gem_names)
          .reject { |gem| @gem_excludes.include?(gem.name) }
          .each do |gem|
            say("Processing '#{gem.name}' gem:", :green)
            shell.indent do
              compile_gem_rbi(gem)
              puts
            end
          end

        say("All operations performed in working directory.", [:green, :bold])
        say("Please review changes and commit them.", [:green, :bold])
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
        compiler = Compilers::SymbolTableCompiler.new
        gem_name = set_color(gem.name, :yellow, :bold)
        say("Compiling #{gem_name}, this may take a few seconds... ")

        strictness = @typed_overrides[gem.name] || "true"
        rbi_body_content = compiler.compile(gem, 0, @doc)
        content = String.new
        content << rbi_header(
          "#{@default_command} gem #{gem.name}",
          reason: "types exported from the `#{gem.name}` gem",
          strictness: strictness
        )

        FileUtils.mkdir_p(@outpath)
        filename = @outpath / gem.rbi_file_name

        if rbi_body_content.strip.empty?
          content << EMPTY_RBI_COMMENT
          say("Done (empty output)", :yellow)
        else
          content << rbi_body_content
          say("Done", :green)
        end
        File.write(filename.to_s, content)

        T.unsafe(Pathname).glob((@outpath / "#{gem.name}@*.rbi").to_s) do |file|
          remove(file) unless file.basename.to_s == gem.rbi_file_name
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

        report_diff_and_exit_if_out_of_date(diff, "gem")
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
              remove(filename)
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

            gems.each do |gem_name|
              filename = expected_rbi(gem_name)

              if gem_rbi_exists?(gem_name)
                old_filename = existing_rbi(gem_name)
                move(old_filename, filename) unless old_filename == filename
              end

              gem = T.must(bundle.gem(gem_name))
              compile_gem_rbi(gem)
              add(filename)

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
        say_error("`#{@default_command} require`", :bold, :blue)
        say_error("you should probably review it and remove the faulty line.", :yellow)
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

        if @file_header
          [statement, sigil].compact.join("\n").strip.concat("\n\n")
        elsif sigil
          sigil.strip.concat("\n\n")
        else
          ""
        end
      end

      sig { params(filename: Pathname).void }
      def remove(filename)
        return unless filename.exist?
        say("-- Removing: #{filename}")
        filename.unlink
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

      sig { params(diff: T::Hash[String, Symbol], command: String).void }
      def report_diff_and_exit_if_out_of_date(diff, command)
        if diff.empty?
          say("Nothing to do, all RBIs are up-to-date.")
        else
          say("RBI files are out-of-date. In your development environment, please run:", :green)
          say("  `#{Config::DEFAULT_COMMAND} #{command}`", [:green, :bold])
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

      sig { params(filename: Pathname).void }
      def add(filename)
        say("++ Adding: #{filename}")
      end

      sig { returns(T::Hash[String, String]) }
      def existing_rbis
        @existing_rbis ||= Pathname.glob((@outpath / "*@*.rbi").to_s)
          .map { |f| T.cast(f.basename(".*").to_s.split("@", 2), [String, String]) }
          .to_h
      end

      sig { returns(T::Hash[String, String]) }
      def expected_rbis
        @expected_rbis ||= bundle.dependencies
          .reject { |gem| @gem_excludes.include?(gem.name) }
          .map { |gem| [gem.name, gem.version.to_s] }
          .to_h
      end

      sig { params(gem_name: String, version: String).returns(Pathname) }
      def gem_rbi_filename(gem_name, version)
        @outpath / "#{gem_name}@#{version}.rbi"
      end

      sig { params(cause: Symbol, files: T::Array[String]).returns(String) }
      def build_error_for_files(cause, files)
        filenames = files.map do |file|
          @outpath / file
        end.join("\n  - ")

        "  File(s) #{cause}:\n  - #{filenames}"
      end
    end
  end
end
