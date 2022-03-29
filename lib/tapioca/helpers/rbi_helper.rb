# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBIHelper
    extend T::Sig
    extend T::Helpers

    requires_ancestor { Thor::Shell }
    requires_ancestor { SorbetHelper }

    sig do
      params(
        command: String,
        gem_dir: String,
        dsl_dir: String,
        auto_strictness: T::Boolean,
        gems: T::Array[Gemfile::GemSpec],
        compilers: T::Enumerable[Class]
      ).void
    end
    def validate_rbi_files(command:, gem_dir:, dsl_dir:, auto_strictness:, gems: [], compilers: [])
      error_url_base = Spoom::Sorbet::Errors::DEFAULT_ERROR_URL_BASE

      say("Checking generated RBI files... ")
      res = sorbet(
        "--no-config",
        "--error-url-base=#{error_url_base}",
        "--stop-after namer",
        dsl_dir,
        gem_dir
      )
      say(" Done", :green)

      errors = Spoom::Sorbet::Errors::Parser.parse_string(res.err)

      if errors.empty?
        say("  No errors found\n\n", [:green, :bold])
        return
      end

      parse_errors = errors.select { |error| error.code < 4000 }

      if parse_errors.any?
        say_error(<<~ERR, :red)

          ##### INTERNAL ERROR #####

          There are parse errors in the generated RBI files.

          This seems related to a bug in Tapioca.
          Please open an issue at https://github.com/Shopify/tapioca/issues/new with the following information:

          Tapioca v#{Tapioca::VERSION}

          Command:
            #{command}

        ERR

        say_error(<<~ERR, :red) if gems.any?
          Gems:
          #{gems.map { |gem| "  #{gem.name} (#{gem.version})" }.join("\n")}

        ERR

        say_error(<<~ERR, :red) if compilers.any?
          Compilers:
          #{compilers.map { |compiler| "  #{compiler.name}" }.join("\n")}

        ERR

        say_error(<<~ERR, :red)
          Errors:
          #{parse_errors.map { |error| "  #{error}" }.join("\n")}

          ##########################

        ERR
      end

      if auto_strictness
        redef_errors = errors.select { |error| error.code == 4010 }
        update_gem_rbis_strictnesses(redef_errors, gem_dir)
      end

      Kernel.exit(1) if parse_errors.any?
    end

    private

    sig { params(errors: T::Array[Spoom::Sorbet::Errors::Error], gem_dir: String).void }
    def update_gem_rbis_strictnesses(errors, gem_dir)
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
        .select { |file| file.start_with?(gem_dir) }
        .each do |file|
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
