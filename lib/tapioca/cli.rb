# typed: true
# frozen_string_literal: true

module Tapioca
  class Cli < Thor
    include CliHelper
    include ConfigHelper

    class_option :config,
      aliases: ["-c"],
      banner: "<config file path>",
      type: :string,
      desc: "Path to the Tapioca configuration file",
      default: TAPIOCA_CONFIG
    class_option :verbose,
      aliases: ["-V"],
      type: :boolean,
      desc: "Verbose output for debugging purposes",
      default: false

    desc "init", "initializes folder structure"
    def init
      generator = Generators::Init.new(
        sorbet_config: SORBET_CONFIG,
        default_postrequire: DEFAULT_POSTREQUIRE,
        default_command: DEFAULT_COMMAND
      )
      generator.generate
    end

    desc "require", "generate the list of files to be required by tapioca"
    option :postrequire, type: :string, default: DEFAULT_POSTREQUIRE
    def require
      generator = Generators::Require.new(
        requires_path: options[:postrequire],
        sorbet_config_path: SORBET_CONFIG,
        default_command: DEFAULT_COMMAND
      )
      Tapioca.silence_warnings do
        generator.generate
      end
    end

    desc "todo", "generate the list of unresolved constants"
    option :todos_path,
      type: :string,
      default: DEFAULT_TODOSPATH
    option :file_header,
      type: :boolean,
      desc: "Add a \"This file is generated\" header on top of each generated RBI file",
      default: true
    def todo
      generator = Generators::Todo.new(
        todos_path: options[:todos_path],
        file_header: options[:file_header],
        default_command: DEFAULT_COMMAND
      )
      Tapioca.silence_warnings do
        generator.generate
      end
    end

    desc "dsl [constant...]", "generate RBIs for dynamic methods"
    option :outdir,
      aliases: ["--out", "-o"],
      banner: "directory",
      desc: "The output directory for generated RBI files",
      default: DEFAULT_DSLDIR
    option :file_header,
      type: :boolean,
      desc: "Add a \"This file is generated\" header on top of each generated RBI file",
      default: true
    option :generators,
      type: :array,
      aliases: ["--gen", "-g"],
      banner: "generator [generator ...]",
      desc: "Only run supplied DSL generators",
      default: []
    option :exclude_generators,
      type: :array,
      banner: "generator [generator ...]",
      desc: "Exclude supplied DSL generators",
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
        outpath: Pathname.new(options[:outdir]),
        generators: options[:generators],
        exclude_generators: options[:exclude_generators],
        file_header: options[:file_header],
        compiler_path: Tapioca::Compilers::Dsl::COMPILERS_PATH,
        tapioca_path: TAPIOCA_PATH,
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
    option :outdir,
      aliases: ["--out", "-o"],
      banner: "directory",
      desc: "The output directory for generated RBI files",
      default: DEFAULT_GEMDIR
    option :file_header,
      type: :boolean,
      desc: "Add a \"This file is generated\" header on top of each generated RBI file",
      default: true
    option :all,
      type: :boolean,
      desc: "Regenerate RBI files for all gems",
      default: false
    option :prerequire,
      aliases: ["--pre", "-b"],
      banner: "file",
      desc: "A file to be required before Bundler.require is called",
      default: nil
    option :postrequire,
      aliases: ["--post", "-a"],
      banner: "file",
      desc: "A file to be required after Bundler.require is called",
      default: DEFAULT_POSTREQUIRE
    option :exclude,
      aliases: ["-x"],
      type: :array,
      banner: "gem [gem ...]",
      desc: "Excludes the given gem(s) from RBI generation",
      default: []
    option :typed_overrides,
      aliases: ["--typed", "-t"],
      type: :hash,
      banner: "gem:level [gem:level ...]",
      desc: "Overrides for typed sigils for generated gem RBIs",
      default: DEFAULT_OVERRIDES
    option :verify,
      type: :boolean,
      desc: "Verifies RBIs are up-to-date",
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
          gem_excludes: options[:exclude],
          prerequire: options[:prerequire],
          postrequire: options[:postrequire],
          typed_overrides: options[:typed_overrides],
          default_command: DEFAULT_COMMAND,
          outpath: Pathname.new(options[:outdir]),
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

    desc "clean-shims", "clean duplicated definitions in shim RBIs"
    option :gem_rbis_path, type: :string, desc: "Path to gem RBIs", default: DEFAULT_GEMDIR
    option :dsl_rbis_path, type: :string, desc: "Path to DSL RBIs", default: DEFAULT_DSLDIR
    option :shim_rbis_path, type: :string, desc: "Path to shim RBIs", default: DEFAULT_SHIMDIR
    def clean_shims(*files_to_clean)
      index = RBI::Index.new

      # Index gem RBIs
      gem_rbis_path = options[:gem_rbis_path]
      say("Loading gem RBIs from #{gem_rbis_path}... ")
      gem_rbis_files = Dir.glob("#{gem_rbis_path}/**/*.rbi").sort
      gem_rbis_trees = RBI::Parser.parse_files(gem_rbis_files)
      index.visit_all(gem_rbis_trees)
      say(" Done", :green)

      # Index dsl RBIs
      dsl_rbis_path = options[:dsl_rbis_path]
      say("Loading dsl RBIs from #{dsl_rbis_path}... ")
      dsl_rbis_files = Dir.glob("#{dsl_rbis_path}/**/*.rbi").sort
      dsl_rbis_trees = RBI::Parser.parse_files(dsl_rbis_files)
      index.visit_all(dsl_rbis_trees)
      say(" Done", :green)

      # Clean shim RBIs
      if files_to_clean.empty?
        shim_rbis_path = options[:shim_rbis_path]
        print("Cleaning shim RBIs from #{shim_rbis_path}...")
        files_to_clean = Dir.glob("#{shim_rbis_path}/*.rbi")
      else
        print("Cleaning shim RBIs...")
      end

      done_something = T.let(false, T::Boolean)
      files_to_clean.sort.each do |path|
        original = RBI::Parser.parse_file(path)
        cleaned, operations = RBI::Rewriters::RemoveKnownDefinitions.remove(original, index)

        next if operations.empty?
        done_something = true

        operations.each do |operation|
          print("\n  #{operation}")
        end

        if cleaned.empty?
          print("\n  Deleted empty file #{path}")
          FileUtils.rm(path)
        else
          File.write(path, cleaned.string)
        end
      end

      if done_something
        say("\nDone", :green)
      else
        say(" Done ", :green)
        say("(nothing to do)", :yellow)
      end
    rescue Errno::ENOENT => e
      say_error("\nCan't read RBI: #{e}")
      exit(1)
    rescue RBI::ParseError => e
      say_error("\nCan't parse RBI: #{e} (#{e.location})")
      exit(1)
    end

    map T.unsafe(["--version", "-v"] => :__print_version)

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
