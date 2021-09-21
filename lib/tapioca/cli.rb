# typed: true
# frozen_string_literal: true

require "thor"

module Tapioca
  class Cli < Thor
    include(Thor::Actions)

    class_option :outdir,
      aliases: ["--out", "-o"],
      banner: "directory",
      desc: "The output directory for generated RBI files"
    class_option :generate_command,
      aliases: ["--cmd", "-c"],
      banner: "command",
      desc: "The command to run to regenerate RBI files"
    class_option :file_header,
      type: :boolean,
      default: true,
      desc: "Add a \"This file is generated\" header on top of each generated RBI file"
    class_option :verbose,
      aliases: ["-V"],
      type: :boolean,
      default: false,
      desc: "Verbose output for debugging purposes"

    map T.unsafe(["--version", "-v"] => :__print_version)

    desc "init", "initializes folder structure"
    def init
      create_config
      create_post_require
      generate_binstub
    end

    desc "require", "generate the list of files to be required by tapioca"
    def require
      generator = Generators::Require.new(
        requires_path: ConfigBuilder.from_options(:require, options).postrequire,
        sorbet_config_path: Config::SORBET_CONFIG,
        default_command: Config::DEFAULT_COMMAND
      )
      Tapioca.silence_warnings do
        generator.generate
      end
    end

    desc "todo", "generate the list of unresolved constants"
    def todo
      current_command = T.must(current_command_chain.first)
      config = ConfigBuilder.from_options(current_command, options)
      generator = Generators::Todo.new(
        todos_path: config.todos_path,
        file_header: config.file_header,
        default_command: Config::DEFAULT_COMMAND
      )
      Tapioca.silence_warnings do
        generator.generate
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
        generator.build_dsl(
          constants,
          should_verify: options[:verify],
          quiet: options[:quiet],
          verbose: options[:verbose]
        )
      end
    end

    desc "gem [gem...]", "generate RBIs from gems"
    option :all,
      type: :boolean,
      default: false,
      desc: "Regenerate RBI files for all gems"
    option :prerequire,
      aliases: ["--pre", "-b"],
      banner: "file",
      desc: "A file to be required before Bundler.require is called"
    option :postrequire,
      aliases: ["--post", "-a"],
      banner: "file",
      desc: "A file to be required after Bundler.require is called"
    option :exclude,
      aliases: ["-x"],
      type: :array,
      banner: "gem [gem ...]",
      desc: "Excludes the given gem(s) from RBI generation"
    option :typed_overrides,
      aliases: ["--typed", "-t"],
      type: :hash,
      banner: "gem:level [gem:level ...]",
      desc: "Overrides for typed sigils for generated gem RBIs"
    option :verify,
      type: :boolean,
      default: false,
      desc: "Verifies RBIs are up-to-date"
    def gem(*gems)
      Tapioca.silence_warnings do
        all = options[:all]
        verify = options[:verify]

        raise MalformattedArgumentError, "Options '--all' and '--verify' are mutually exclusive" if all && verify

        unless gems.empty?
          raise MalformattedArgumentError, "Option '--all' must be provided without any other arguments" if all
          raise MalformattedArgumentError, "Option '--verify' must be provided without any other arguments" if verify
        end

        if gems.empty? && !all
          generator.sync_rbis_with_gemfile(should_verify: verify)
        else
          generator.build_gem_rbis(all ? [] : gems)
        end
      end
    end

    desc "generate [gem...]", "DEPRECATED: generate RBIs from gems"
    option :prerequire,
      aliases: ["--pre", "-b"],
      banner: "file",
      desc: "A file to be required before Bundler.require is called"
    option :postrequire,
      aliases: ["--post", "-a"],
      banner: "file",
      desc: "A file to be required after Bundler.require is called"
    option :exclude,
      aliases: ["-x"],
      type: :array,
      banner: "gem [gem ...]",
      desc: "Excludes the given gem(s) from RBI generation"
    option :typed_overrides,
      aliases: ["--typed", "-t"],
      type: :hash,
      banner: "gem:level [gem:level ...]",
      desc: "Overrides for typed sigils for generated gem RBIs"
    def generate(*gems)
      gem_names = if gems.empty?
        "--all"
      else
        gems.join(" ")
      end
      deprecation_message = <<~MSG
        DEPRECATION: The `generate` command will be removed in a future release.

        Start using `bin/tapioca gem #{gem_names}` instead.
      MSG

      say(deprecation_message, :red)
      say("")

      Tapioca.silence_warnings do
        generator.build_gem_rbis(gems)
      end

      say("")
      say(deprecation_message, :red)
    end

    desc "sync", "DEPRECATED: sync RBIs to Gemfile"
    option :prerequire,
      aliases: ["--pre", "-b"],
      banner: "file",
      desc: "A file to be required before Bundler.require is called"
    option :postrequire,
      aliases: ["--post", "-a"],
      banner: "file",
      desc: "A file to be required after Bundler.require is called"
    option :exclude,
      aliases: ["-x"],
      type: :array,
      banner: "gem [gem ...]",
      desc: "Excludes the given gem(s) from RBI generation"
    option :typed_overrides,
      aliases: ["--typed", "-t"],
      type: :hash,
      banner: "gem:level [gem:level ...]",
      desc: "Overrides for typed sigils for generated gem RBIs"
    option :verify,
      type: :boolean,
      default: false,
      desc: "Verifies RBIs are up-to-date"
    def sync
      deprecation_message = <<~MSG
        DEPRECATION: The `sync` command will be removed in a future release.

        Start using `bin/tapioca gem` instead.
      MSG

      say(deprecation_message, :red)
      say("")

      Tapioca.silence_warnings do
        generator.sync_rbis_with_gemfile(should_verify: options[:verify])
      end

      say("")
      say(deprecation_message, :red)
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
