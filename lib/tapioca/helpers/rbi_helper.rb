# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBIHelper
    extend T::Sig
    extend T::Helpers

    requires_ancestor { Thor::Shell }
    requires_ancestor { SorbetHelper }

    sig { params(gem_names: T::Array[String], gem_dir: String, dsl_dir: String).void }
    def update_gem_rbis_strictnesses(gem_names, gem_dir: DEFAULT_GEM_DIR, dsl_dir: DEFAULT_DSL_DIR)
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
