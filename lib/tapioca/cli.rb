# typed: true
# frozen_string_literal: true

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
                  desc: "[DEPRECATED] The command to run to regenerate RBI files"
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

    map T.unsafe(%w[--version -v] => :__print_version)

    desc "init", "initializes folder structure"
    def init
      create_config
      create_post_require
      generate_binstub
    end

    desc "require", "generate the list of files to be required by tapioca"
    def require
      Tapioca.silence_warnings do
        generator.build_requires
      end
    end

    desc "todo", "generate the list of unresolved constants"
    def todo
      Tapioca.silence_warnings do
        generator.build_todos
      end
    end

    desc "dsl [constant...]", "generate RBIs for dynamic methods"
    option :generators,
      type: :array,
      aliases: ["--gen", "-g"],
      banner: "generator [generator ...]",
      desc: "Only run supplied DSL generators"
    option :verify,
      type: :boolean,
      default: false,
      desc: "Verifies RBIs are up-to-date"
    def dsl(*constants)
      Tapioca.silence_warnings do
        generator.build_dsl(constants, should_verify: options[:verify])
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

    desc "--version, -v", "show version"
    def __print_version
      puts "Tapioca v#{Tapioca::VERSION}"
    end

    private

    def create_config
      create_file(Config::SORBET_CONFIG, skip: true) do
        <<~CONTENT
          --dir
          .
        CONTENT
      end
    end

    def create_post_require
      create_file(Config::DEFAULT_POSTREQUIRE, skip: true) do
        <<~CONTENT
          # typed: false
          # frozen_string_literal: true

          # Add your extra requires here
        CONTENT
      end
    end

    def generate_binstub
      installer = Bundler::Installer.new(Bundler.root, Bundler.definition)
      spec = Bundler.definition.specs.find { |s| s.name == "tapioca" }
      installer.generate_bundler_executable_stubs(spec, { force: true })
    end

    no_commands do
      def self.exit_on_failure?
        true
      end

      def generator
        current_command = T.must(current_command_chain.first)
        @generator ||= Generator.new(
          ConfigBuilder.from_options(current_command, options)
        )
      end
    end
  end
end
