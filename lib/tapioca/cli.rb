# typed: true
# frozen_string_literal: true

module Tapioca
  class Cli < Thor
    include CliHelper
    include ConfigHelper
    include ShimsHelper

    FILE_HEADER_OPTION_DESC = "Add a \"This file is generated\" header on top of each generated RBI file"

    class_option :config,
      aliases: ["-c"],
      banner: "<config file path>",
      type: :string,
      desc: "Path to the Tapioca configuration file",
      default: TAPIOCA_CONFIG_FILE
    class_option :verbose,
      aliases: ["-V"],
      type: :boolean,
      desc: "Verbose output for debugging purposes",
      default: false

    class_option :gem_rbi_dir,
      type: :string,
      banner: "directory",
      desc: "The output directory for generated gem RBI files",
      default: DEFAULT_GEM_DIR

    class_option :dsl_rbi_dir,
      type: :string,
      banner: "directory",
      desc: "The output directory for generated DSL RBI files",
      default: DEFAULT_DSL_DIR

    class_option :shim_rbi_dir,
      type: :string,
      banner: "directory",
      desc: "The directory containing shim RBI files",
      default: DEFAULT_SHIM_DIR

    class_option :todo_rbi_file,
      type: :string,
      banner: "file",
      desc: "The output path for generated todo RBI",
      default: DEFAULT_TODO_FILE

    class_option :prerequire_file,
      type: :string,
      aliases: ["--pre", "-b"],
      banner: "file",
      desc: "A file to be required before Bundler.require is called",
      default: nil

    class_option :postrequire_file,
      type: :string,
      aliases: ["--post", "-a"],
      banner: "file",
      desc: "A file to be required after Bundler.require is called",
      default: DEFAULT_POSTREQUIRE_FILE

    desc "init", "initializes folder structure"
    def init
      generator = Generators::Init.new(
        sorbet_config: SORBET_CONFIG_FILE,
        tapioca_config: TAPIOCA_CONFIG_FILE,
        default_postrequire: options[:postrequire_file],
        default_command: DEFAULT_COMMAND
      )
      generator.generate
    end

    desc "require", "generate the list of files to be required by tapioca"
    def require
      generator = Generators::Require.new(
        requires_path: options[:postrequire_file],
        sorbet_config_path: SORBET_CONFIG_FILE,
        default_command: DEFAULT_COMMAND
      )
      Tapioca.silence_warnings do
        generator.generate
      end
    end

    desc "todo", "generate the list of unresolved constants"
    option :file_header,
      type: :boolean,
      desc: FILE_HEADER_OPTION_DESC,
      default: true
    def todo
      generator = Generators::Todo.new(
        todo_file: options[:todo_rbi_file],
        file_header: options[:file_header],
        default_command: DEFAULT_COMMAND
      )
      Tapioca.silence_warnings do
        generator.generate
      end
    end

    desc "dsl [constant...]", "generate RBIs for dynamic methods"
    option :file_header,
      type: :boolean,
      desc: FILE_HEADER_OPTION_DESC,
      default: true
    option :only,
      type: :array,
      banner: "compiler [compiler ...]",
      desc: "Only run supplied DSL compiler(s)",
      default: []
    option :exclude,
      type: :array,
      banner: "compiler [compiler ...]",
      desc: "Exclude supplied DSL compiler(s)",
      default: []
    option :verify,
      type: :boolean,
      default: false,
      desc: "Verifies RBIs are up-to-date"
    option :quiet,
      aliases: ["-q"],
      type: :boolean,
      desc: "Supresses file creation output",
      default: false
    option :workers,
      aliases: ["-w"],
      type: :numeric,
      desc: "EXPERIMENTAL: Number of parallel workers to use when generating RBIs",
      default: 1
    def dsl(*constants)
      generator = Generators::Dsl.new(
        requested_constants: constants,
        outpath: Pathname.new(options[:dsl_rbi_dir]),
        only: options[:only],
        exclude: options[:exclude],
        file_header: options[:file_header],
        compiler_path: Tapioca::Dsl::DSL_COMPILERS_DIR,
        tapioca_path: TAPIOCA_DIR,
        default_command: DEFAULT_COMMAND,
        should_verify: options[:verify],
        quiet: options[:quiet],
        verbose: options[:verbose],
        number_of_workers: options[:workers]
      )

      if options[:workers] != 1
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
    option :file_header,
      type: :boolean,
      desc: FILE_HEADER_OPTION_DESC,
      default: true
    option :all,
      type: :boolean,
      desc: "Regenerate RBI files for all gems",
      default: false
    option :exclude,
      aliases: ["-x"],
      type: :array,
      banner: "gem [gem ...]",
      desc: "Exclude the given gem(s) from RBI generation",
      default: []
    option :typed_overrides,
      aliases: ["--typed", "-t"],
      type: :hash,
      banner: "gem:level [gem:level ...]",
      desc: "Override for typed sigils for generated gem RBIs",
      default: DEFAULT_OVERRIDES
    option :verify,
      type: :boolean,
      desc: "Verify RBIs are up-to-date",
      default: false
    option :doc,
      type: :boolean,
      desc: "Include YARD documentation from sources when generating RBIs. Warning: this might be slow",
      default: false
    option :exported_gem_rbis,
      type: :boolean,
      desc: "Include RBIs found in the `rbi/` directory of the gem",
      default: true
    option :workers,
      aliases: ["-w"],
      type: :numeric,
      desc: "EXPERIMENTAL: Number of parallel workers to use when generating RBIs",
      default: 1
    def gem(*gems)
      Tapioca.silence_warnings do
        all = options[:all]
        verify = options[:verify]

        generator = Generators::Gem.new(
          gem_names: all ? [] : gems,
          exclude: options[:exclude],
          prerequire: options[:prerequire_file],
          postrequire: options[:postrequire_file],
          typed_overrides: options[:typed_overrides],
          default_command: DEFAULT_COMMAND,
          outpath: Pathname.new(options[:gem_rbi_dir]),
          file_header: options[:file_header],
          doc: options[:doc],
          include_exported_rbis: options[:exported_gem_rbis],
          number_of_workers: options[:workers]
        )

        raise MalformattedArgumentError, "Options '--all' and '--verify' are mutually exclusive" if all && verify

        unless gems.empty?
          raise MalformattedArgumentError, "Option '--all' must be provided without any other arguments" if all
          raise MalformattedArgumentError, "Option '--verify' must be provided without any other arguments" if verify
        end

        if options[:workers] != 1
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
    map "gems" => :gem

    desc "check-shims", "check duplicated definitions in shim RBIs"
    def check_shims
      index = RBI::Index.new

      shim_rbi_dir = options[:shim_rbi_dir]
      if !Dir.exist?(shim_rbi_dir) || Dir.empty?(shim_rbi_dir)
        say("No shim RBIs to check", :green)
        exit(0)
      end

      index_rbis(index, "shim", shim_rbi_dir)
      index_rbis(index, "gem", options[:gem_rbi_dir])
      index_rbis(index, "dsl", options[:dsl_rbi_dir])

      duplicates = duplicated_nodes_from_index(index, shim_rbi_dir)
      unless duplicates.empty?
        duplicates.each do |key, nodes|
          say_error("\nDuplicated RBI for #{key}:", :red)
          nodes.each do |node|
            say_error(" * #{node.loc}", :red)
          end
        end
        say_error("\nPlease remove the duplicated definitions from the #{shim_rbi_dir} directory.", :red)
        exit(1)
      end

      say("\nNo duplicates found in shim RBIs", :green)
      exit(0)
    end

    map ["--version", "-v"] => :__print_version

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
