# typed: true
# frozen_string_literal: true

module Tapioca
  class Cli < Thor
    include CliHelper

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
      generator = Generators::Init.new(
        sorbet_config: Config::SORBET_CONFIG,
        default_postrequire: Config::DEFAULT_POSTREQUIRE,
        default_command: Config::DEFAULT_COMMAND
      )
      generator.generate
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
    option :workers,
      aliases: ["-w"],
      type: :numeric,
      desc: "EXPERIMENTAL: Number of parallel workers to use when generating RBIs"
    def dsl(*constants)
      current_command = T.must(current_command_chain.first)
      config = ConfigBuilder.from_options(current_command, options)
      generator = Generators::Dsl.new(
        requested_constants: constants,
        outpath: config.outpath,
        generators: config.generators,
        exclude_generators: config.exclude_generators,
        file_header: config.file_header,
        compiler_path: Tapioca::Compilers::Dsl::COMPILERS_PATH,
        tapioca_path: Config::TAPIOCA_PATH,
        default_command: Config::DEFAULT_COMMAND,
        should_verify: options[:verify],
        quiet: options[:quiet],
        verbose: options[:verbose],
        number_of_workers: config.workers
      )

      if config.workers != 1
        say(
          "Using more than one worker is experimental and might produce results that are not deterministic",
          :red
        )
      end

      Tapioca.silence_warnings do
        generator.generate
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
    option :doc,
      type: :boolean,
      desc: "Include YARD documentation from sources when generating RBIs. Warning: this might be slow"
    option :workers,
      aliases: ["-w"],
      type: :numeric,
      desc: "EXPERIMENTAL: Number of parallel workers to use when generating RBIs"
    def gem(*gems)
      Tapioca.silence_warnings do
        all = options[:all]
        verify = options[:verify]
        current_command = T.must(current_command_chain.first)
        config = ConfigBuilder.from_options(current_command, options)
        generator = Generators::Gem.new(
          gem_names: all ? [] : gems,
          gem_excludes: config.exclude,
          prerequire: config.prerequire,
          postrequire: config.postrequire,
          typed_overrides: config.typed_overrides,
          default_command: Config::DEFAULT_COMMAND,
          outpath: config.outpath,
          file_header: config.file_header,
          doc: config.doc,
          number_of_workers: config.workers
        )

        raise MalformattedArgumentError, "Options '--all' and '--verify' are mutually exclusive" if all && verify

        unless gems.empty?
          raise MalformattedArgumentError, "Option '--all' must be provided without any other arguments" if all
          raise MalformattedArgumentError, "Option '--verify' must be provided without any other arguments" if verify
        end

        if config.workers != 1
          say(
            "Using more than one worker is experimental and might produce results that are not deterministic",
            :red
          )
        end

        if gems.empty? && !all
          generator.sync(should_verify: verify)
        else
          generator.generate
        end
      end
    end

    desc "--version, -v", "show version"
    def __print_version
      puts "Tapioca v#{Tapioca::VERSION}"
    end

    no_commands do
      def self.exit_on_failure?
        true
      end
    end
  end
end
