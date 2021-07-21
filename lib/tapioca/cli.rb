# typed: true
# frozen_string_literal: true

require "thor"

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
    class_option :file_header,
      type: :boolean,
      default: true,
      desc: "Add a \"This file is generated\" header on top of each generated RBI file"

    map T.unsafe(["--version", "-v"] => :__print_version)

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
    option :exclude_generators,
      type: :array,
      banner: "generator [generator ...]",
      desc: "Exclude supplied DSL generators"
    option :verify,
      type: :boolean,
      default: false,
      desc: "Verifies RBIs are up-to-date"
    option :quiet,
      aliases: ["-q"],
      type: :boolean,
      desc: "Supresses file creation output"
    def dsl(*constants)
      Tapioca.silence_warnings do
        generator.build_dsl(constants, should_verify: options[:verify], quiet: options[:quiet])
      end
    end

    desc "generate [gem...]", "generate RBIs from gems"
    def generate(*gems)
      Tapioca.silence_warnings do
        generator.build_gem_rbis(gems)
      end
    end

    desc "sync", "sync RBIs to Gemfile"
    option :verify,
      type: :boolean,
      default: false,
      desc: "Verifies RBIs are up-to-date"
    def sync
      Tapioca.silence_warnings do
        generator.sync_rbis_with_gemfile(should_verify: options[:verify])
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
          --ignore=vendor
        CONTENT
      end
    end

    def create_post_require
      create_file(Config::DEFAULT_POSTREQUIRE, skip: true) do
        <<~CONTENT
          # typed: true
          # frozen_string_literal: true

          # Add your extra requires here (`tapioca require` can be used to boostrap this list)
        CONTENT
      end
    end

    def generate_binstub
      bin_stub_exists = File.exist?("bin/tapioca")
      installer = Bundler::Installer.new(Bundler.root, Bundler.definition)
      spec = Bundler.definition.specs.find { |s| s.name == "tapioca" }
      installer.generate_bundler_executable_stubs(spec, { force: true })
      if bin_stub_exists
        shell.say_status(:force, "bin/tapioca", :yellow)
      else
        shell.say_status(:create, "bin/tapioca", :green)
      end
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
