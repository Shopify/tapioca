# typed: strict
# frozen_string_literal: true

require 'pathname'
require 'thor'

module Tapioca
  class Generator < ::Thor::Shell::Color
    extend(T::Sig)

    class OutOfSyncError < StandardError; end

    sig { returns(Config) }
    attr_reader :config

    sig do
      params(
        config: Config
      ).void
    end
    def initialize(config)
      @config = config
      @bundle = T.let(nil, T.nilable(Gemfile))
      @loader = T.let(nil, T.nilable(Loader))
      @compiler = T.let(nil, T.nilable(Compilers::SymbolTableCompiler))
      @existing_rbis = T.let(nil, T.nilable(T::Hash[String, String]))
      @expected_rbis = T.let(nil, T.nilable(T::Hash[String, String]))
      super()
    end

    sig { params(gem_names: T::Array[String]).void }
    def build_gem_rbis(gem_names)
      require_gem_file

      gems_to_generate(gem_names)
        .reject { |gem| config.exclude.include?(gem.name) }
        .each do |gem|
          say("Processing '#{gem.name}' gem:", :green)
          indent do
            compile_gem_rbi(gem)
            puts
          end
        end

      say("All operations performed in working directory.", [:green, :bold])
      say("Please review changes and commit them.", [:green, :bold])
    end

    sig { void }
    def build_requires
      requires_path = Config::DEFAULT_POSTREQUIRE
      compiler = Compilers::RequiresCompiler.new(Config::SORBET_CONFIG)
      name = set_color(requires_path, :yellow, :bold)
      say("Compiling #{name}, this may take a few seconds... ")

      rb_string = compiler.compile
      if rb_string.empty?
        say("Nothing to do", :green)
        return
      end

      # Clean all existing requires before regenerating the list so we update
      # it with the new one found in the client code and remove the old ones.
      File.delete(requires_path) if File.exist?(requires_path)

      content = String.new
      content << rbi_header(
        config.generate_command,
        reason: "explicit gem requires",
        strictness: "false"
      )
      content << rb_string

      outdir = File.dirname(requires_path)
      FileUtils.mkdir_p(outdir)
      File.write(requires_path, content)

      say("Done", :green)

      say("All requires from this application have been written to #{name}.", [:green, :bold])
      cmd = set_color("tapioca sync", :yellow, :bold)
      say("Please review changes and commit them, then run #{cmd}.", [:green, :bold])
    end

    sig { void }
    def build_todos
      todos_path = config.todos_path
      compiler = Compilers::TodosCompiler.new
      name = set_color(todos_path, :yellow, :bold)
      say("Compiling #{name}, this may take a few seconds... ")

      # Clean all existing unresolved constants before regenerating the list
      # so Sorbet won't grab them as already resolved.
      File.delete(todos_path) if File.exist?(todos_path)

      rbi_string = compiler.compile
      if rbi_string.empty?
        say("Nothing to do", :green)
        return
      end

      content = String.new
      content << rbi_header(
        config.generate_command,
        reason: "unresolved constants",
        strictness: "false"
      )
      content << rbi_string
      content << "\n"

      outdir = File.dirname(todos_path)
      FileUtils.mkdir_p(outdir)
      File.write(todos_path, content)

      say("Done", :green)

      say("All unresolved constants have been written to #{name}.", [:green, :bold])
      say("Please review changes and commit them.", [:green, :bold])
    end

    sig do
      params(
        requested_constants: T::Array[String],
        should_verify: T::Boolean,
      ).void
    end
    def build_dsl(requested_constants, should_verify: false)
      load_application(eager_load: requested_constants.empty?)
      load_dsl_generators

      if should_verify
        say("Checking for out-of-date RBIs...")
      else
        say("Compiling DSL RBI files...")
      end
      say("")

      outpath = should_verify ? Dir.mktmpdir : config.outpath
      rbi_files_to_purge = existing_rbi_filenames(requested_constants)

      compiler = Compilers::DslCompiler.new(
        requested_constants: constantize(requested_constants),
        requested_generators: config.generators,
        error_handler: ->(error) {
          say_error(error, :bold, :red)
        }
      )

      compiler.run do |constant, contents|
        filename = compile_dsl_rbi(constant, contents, outpath: Pathname.new(outpath))
        rbi_files_to_purge.delete(filename) if filename
      end

      if !rbi_files_to_purge.empty? && !should_verify
        say("")
        say("Removing stale RBI files...")

        rbi_files_to_purge.sort.each do |filename|
          remove(filename)
        end
      end

      say("")
      if should_verify
        begin
          verify_dsl_rbi(tmp_dir: Pathname.new(outpath))
        rescue OutOfSyncError => e
          say("RBI files are out-of-date, please run `bundle exec tapioca dsl` to update.")
          say("Reason: ", [:red])
          say(e.message.to_s)
          exit(1)
        else
          say("Nothing to do, all RBIs are up-to-date.")
        end
      else
        say("Done", :green)

        say("All operations performed in working directory.", [:green, :bold])
        say("Please review changes and commit them.", [:green, :bold])
      end
    end

    sig { void }
    def sync_rbis_with_gemfile
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

    EMPTY_RBI_COMMENT = <<~CONTENT
      # THIS IS AN EMPTY RBI FILE.
      # see https://github.com/Shopify/tapioca/blob/master/README.md#manual-gem-requires
    CONTENT

    sig { returns(Gemfile) }
    def bundle
      @bundle ||= Gemfile.new
    end

    sig { returns(Loader) }
    def loader
      @loader ||= Loader.new(bundle)
    end

    sig { returns(Compilers::SymbolTableCompiler) }
    def compiler
      @compiler ||= Compilers::SymbolTableCompiler.new
    end

    sig { void }
    def require_gem_file
      say("Requiring all gems to prepare for compiling... ")
      begin
        loader.load_bundle(config.prerequire, config.postrequire)
      rescue LoadError => e
        explain_failed_require(config.postrequire, e)
        exit(1)
      end
      say(" Done", :green)
      unless bundle.missing_specs.empty?
        say("  completed with missing specs: ")
        say(bundle.missing_specs.join(', '), :yellow)
      end
      puts
    end

    sig { params(file: String, error: LoadError).void }
    def explain_failed_require(file, error)
      say_error("\n\nLoadError: #{error}", :bold, :red)
      say_error("\nTapioca could not load all the gems required by your application.", :yellow)
      say_error("If you populated ", :yellow)
      say_error("#{file} ", :bold, :blue)
      say_error("with ", :yellow)
      say_error("tapioca require", :bold, :blue)
      say_error("you should probably review it and remove the faulty line.", :yellow)
    end

    sig do
      params(
        message: String,
        color: T.any(Symbol, T::Array[Symbol]),
      ).void
    end
    def say_error(message = "", *color)
      force_new_line = (message.to_s !~ /( |\t)\Z/)
      buffer = prepare_message(*T.unsafe([message, *T.unsafe(color)]))
      buffer << "\n" if force_new_line && !message.to_s.end_with?("\n")

      stderr.print(buffer)
      stderr.flush
    end

    sig { params(eager_load: T::Boolean).void }
    def load_application(eager_load:)
      say("Loading Rails application... ")

      loader.load_rails(
        environment_load: true,
        eager_load: eager_load
      )

      say("Done", :green)
    end

    sig { void }
    def load_dsl_generators
      say("Loading DSL generator classes... ")

      Dir.glob([
        "#{__dir__}/compilers/dsl/*.rb",
        "#{Config::TAPIOCA_PATH}/generators/**/*.rb",
      ]).each do |generator|
        require File.expand_path(generator)
      end

      say("Done", :green)
    end

    sig { params(constant_names: T::Array[String]).returns(T::Array[Module]) }
    def constantize(constant_names)
      constant_map = constant_names.map do |name|
        begin
          [name, name.constantize]
        rescue NameError
          [name, nil]
        end
      end.to_h

      unprocessable_constants = constant_map.select { |_, v| v.nil? }
      unless unprocessable_constants.empty?
        unprocessable_constants.each do |name, _|
          say("Error: Cannot find constant '#{name}'", :red)
          remove(dsl_rbi_filename(name))
        end

        exit(1)
      end

      constant_map.values
    end

    sig { params(requested_constants: T::Array[String]).returns(T::Set[Pathname]) }
    def existing_rbi_filenames(requested_constants)
      filenames = if requested_constants.empty?
        Pathname.glob(config.outpath / "**/*.rbi")
      else
        requested_constants.map do |constant_name|
          dsl_rbi_filename(constant_name)
        end
      end

      filenames.to_set
    end

    sig { returns(T::Hash[String, String]) }
    def existing_rbis
      @existing_rbis ||= Pathname.glob((config.outpath / "*@*.rbi").to_s)
        .map { |f| T.cast(f.basename(".*").to_s.split('@', 2), [String, String]) }
        .to_h
    end

    sig { returns(T::Hash[String, String]) }
    def expected_rbis
      @expected_rbis ||= bundle.dependencies
        .reject { |gem| config.exclude.include?(gem.name) }
        .map { |gem| [gem.name, gem.version.to_s] }
        .to_h
    end

    sig { params(constant_name: String).returns(Pathname) }
    def dsl_rbi_filename(constant_name)
      config.outpath / "#{constant_name.underscore}.rbi"
    end

    sig { params(gem_name: String, version: String).returns(Pathname) }
    def gem_rbi_filename(gem_name, version)
      config.outpath / "#{gem_name}@#{version}.rbi"
    end

    sig { params(gem_name: String).returns(Pathname) }
    def existing_rbi(gem_name)
      gem_rbi_filename(gem_name, T.must(existing_rbis[gem_name]))
    end

    sig { params(gem_name: String).returns(Pathname) }
    def expected_rbi(gem_name)
      gem_rbi_filename(gem_name, T.must(expected_rbis[gem_name]))
    end

    sig { params(gem_name: String).returns(T::Boolean) }
    def gem_rbi_exists?(gem_name)
      existing_rbis.key?(gem_name)
    end

    sig { returns(T::Array[String]) }
    def removed_rbis
      (existing_rbis.keys - expected_rbis.keys).sort
    end

    sig { returns(T::Array[String]) }
    def added_rbis
      expected_rbis.select do |name, value|
        existing_rbis[name] != value
      end.keys.sort
    end

    sig { params(filename: Pathname).void }
    def add(filename)
      say("++ Adding: #{filename}")
    end

    sig { params(filename: Pathname).void }
    def remove(filename)
      return unless filename.exist?
      say("-- Removing: #{filename}")
      filename.unlink
    end

    sig { params(old_filename: Pathname, new_filename: Pathname).void }
    def move(old_filename, new_filename)
      say("-> Moving: #{old_filename} to #{new_filename}")
      old_filename.rename(new_filename.to_s)
    end

    sig { void }
    def perform_removals
      say("Removing RBI files of gems that have been removed:", [:blue, :bold])
      puts

      anything_done = T.let(false, T::Boolean)

      gems = removed_rbis

      indent do
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

      indent do
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

    sig do
      params(gem_names: T::Array[String])
        .returns(T::Array[Gemfile::Gem])
    end
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

      [statement, sigil].compact.join("\n").strip.concat("\n\n")
    end

    sig { params(gem: Gemfile::Gem).void }
    def compile_gem_rbi(gem)
      compiler = Compilers::SymbolTableCompiler.new
      gem_name = set_color(gem.name, :yellow, :bold)
      say("Compiling #{gem_name}, this may take a few seconds... ")

      strictness = config.typed_overrides[gem.name] || "true"
      rbi_body_content = compiler.compile(gem)
      content = String.new
      content << rbi_header(
        config.generate_command,
        reason: "types exported from the `#{gem.name}` gem",
        strictness: strictness
      )

      FileUtils.mkdir_p(config.outdir)
      filename = config.outpath / gem.rbi_file_name

      if rbi_body_content.strip.empty?
        content << EMPTY_RBI_COMMENT
        say("Done (empty output)", :yellow)
      else
        content << rbi_body_content
        say("Done", :green)
      end
      File.write(filename.to_s, content)

      Pathname.glob((config.outpath / "#{gem.name}@*.rbi").to_s) do |file|
        remove(file) unless file.basename.to_s == gem.rbi_file_name
      end
    end

    sig { params(constant: Module, contents: String, outpath: Pathname).returns(T.nilable(Pathname)) }
    def compile_dsl_rbi(constant, contents, outpath: config.outpath)
      return if contents.nil?

      command = format(config.generate_command, constant.name)
      constant_name = Module.instance_method(:name).bind(constant).call
      rbi_name = constant_name.underscore + ".rbi"
      filename = outpath / rbi_name

      out = String.new
      out << rbi_header(
        command,
        reason: "dynamic methods in `#{constant.name}`"
      )
      out << contents

      FileUtils.mkdir_p(File.dirname(filename))
      File.write(filename, out)
      say("Wrote: ", [:green])
      say(filename)

      filename
    end

    sig { params(tmp_dir: Pathname).void }
    def verify_dsl_rbi(tmp_dir:)
      existing_rbis = get_file_list(dir: config.outpath).sort
      test_rbis = get_file_list(dir: tmp_dir).sort

      current_count = existing_rbis.count
      new_count = test_rbis.count

      raise(OutOfSyncError.new, "New file(s) introduced.") if current_count != new_count

      desynced_files = []

      (0..current_count - 1).each do |i|
        desynced_files << test_rbis[i] unless FileUtils.identical?(existing_rbis[i], test_rbis[i])
      end

      if desynced_files.count > 0
        filenames = desynced_files.map(&:to_s).each do |file|
          file.sub!(tmp_dir.to_s, "sorbet/rbi/dsl")
        end.join("\n  - ")

        raise(OutOfSyncError.new, "File(s) updated:\n  - #{filenames}")
      end
    end

    sig { params(dir: Pathname).returns(T::Array[Pathname]) }
    def get_file_list(dir:)
      Dir.glob("#{dir}/**/*.rbi").reject { |e| e =~ /gems/ }.map { |f| Pathname.new(f) }
    end
  end
end
