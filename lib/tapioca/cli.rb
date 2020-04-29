# frozen_string_literal: true
# typed: false

require 'thor'

module Tapioca
  class Cli < Thor
    include(Thor::Actions)

    class_option :prerequire,
                  aliases: ["--pre", "-b"],
                  banner: "file",
                  desc: "A file to be required before Bundler.require is called"
    class_option :postrequire,
                  aliases: ["--post", "-a"],
                  banner: "file",
                  desc: "A file to be required after Bundler.require is called"
    class_option :outdir,
                  aliases: ["--out", "-o"],
                  banner: "directory",
                  desc: "The output directory for generated RBI files"
    class_option :generate_command,
                  aliases: ["--cmd", "-c"],
                  banner: "command",
                  desc: "The command to run to regenerate RBI files"
    class_option :exclude,
                  aliases: ["-x"],
                  type: :array,
                  banner: "gem [gem ...]",
                  desc: "Excludes the given gem(s) from RBI generation"
    class_option :typed_overrides,
                  aliases: ["--typed", "-t"],
                  type: :hash,
                  banner: "gem:level [gem:level ...]",
                  desc: "Overrides for typed sigils for generated gem RBIs"

    desc "init", "initializes folder structure"
    def init
      create_file(Config::SORBET_CONFIG, skip: true) do
        <<~CONTENT
          --dir
          .
        CONTENT
      end
      create_file(Config::DEFAULT_POSTREQUIRE, skip: true) do
        <<~CONTENT
          # frozen_string_literal: true
          # typed: false

          # Add your extra requires here
        CONTENT
      end
    end

    desc "todo", "generate the list of unresolved constants"
    def todo
      Tapioca.silence_warnings do
        generator.build_todos
      end
    end

    desc "generate [gem...]", "generate RBIs from gems"
    def generate(*gems)
      Tapioca.silence_warnings do
        generator.build_gem_rbis(gems)
      end
    end

    desc "sync", "sync RBIs to Gemfile"
    def sync
      Tapioca.silence_warnings do
        generator.sync_rbis_with_gemfile
      end
    end

    no_commands do
      def self.exit_on_failure?
        true
      end

      def generator
        @generator ||= Generator.new(ConfigBuilder.from_options(options))
      end
    end
  end
end
