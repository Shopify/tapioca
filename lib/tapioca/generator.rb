# frozen_string_literal: true
# typed: strict

require 'pathname'
require 'thor'

module Tapioca
  class Generator < ::Thor::Shell::Color
    extend(T::Sig)

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
            compile_rbi(gem)
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
      content << rbi_header(config.generate_command, "false")
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
      content << rbi_header(config.generate_command, "false")
      content << rbi_string
      content << "\n"

      outdir = File.dirname(todos_path)
      FileUtils.mkdir_p(outdir)
      File.write(todos_path, content)

      say("Done", :green)

      say("All unresolved constants have been written to #{name}.", [:green, :bold])
      say("Please review changes and commit them.", [:green, :bold])
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
      loader.load_bundle(config.prerequire, config.postrequire)
      say(" Done", :green)
      puts
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

    sig { params(gem_name: String, version: String).returns(Pathname) }
    def rbi_filename(gem_name, version)
      config.outpath / "#{gem_name}@#{version}.rbi"
    end

    sig { params(gem_name: String).returns(Pathname) }
    def existing_rbi(gem_name)
      rbi_filename(gem_name, T.must(existing_rbis[gem_name]))
    end

    sig { params(gem_name: String).returns(Pathname) }
    def expected_rbi(gem_name)
      rbi_filename(gem_name, T.must(expected_rbis[gem_name]))
    end

    sig { params(gem_name: String).returns(T::Boolean) }
    def rbi_exists?(gem_name)
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

            if rbi_exists?(gem_name)
              old_filename = existing_rbi(gem_name)
              move(old_filename, filename) unless old_filename == filename
            end

            gem = T.must(bundle.gem(gem_name))
            compile_rbi(gem)
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

    sig { params(command: String, typed_sigil: String).returns(String) }
    def rbi_header(command, typed_sigil)
      <<~HEAD
        # This file is autogenerated. Do not edit it by hand. Regenerate it with:
        #   #{command}

        # typed: #{typed_sigil}

      HEAD
    end

    sig { params(gem: Gemfile::Gem).void }
    def compile_rbi(gem)
      compiler = Compilers::SymbolTableCompiler.new
      gem_name = set_color(gem.name, :yellow, :bold)
      say("Compiling #{gem_name}, this may take a few seconds... ")

      typed_sigil = config.typed_overrides[gem.name] || "true"

      content = compiler.compile(gem)
      content.prepend(rbi_header(config.generate_command, typed_sigil))

      FileUtils.mkdir_p(config.outdir)
      filename = config.outpath / gem.rbi_file_name
      File.write(filename.to_s, content)

      say("Done", :green)

      Pathname.glob((config.outpath / "#{gem.name}@*.rbi").to_s) do |file|
        remove(file) unless file.basename.to_s == gem.rbi_file_name
      end
    end
  end
end
