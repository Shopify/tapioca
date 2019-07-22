# frozen_string_literal: true
# typed: strict

require 'pathname'
require 'thor'

module Tapioca
  class Generator < ::Thor::Shell::Color
    extend(T::Sig)

    DEFAULT_OUTDIR = "sorbet/rbi/gems"
    DEFAULT_OVERRIDES = T.let({
      # ActiveSupport overrides some core methods with different signatures
      # so we generate a typed: false RBI for it to suppress errors
      "activesupport" => "false",
    }, T::Hash[String, String])

    sig { returns(Pathname) }
    attr_reader :outdir
    sig { returns(T.nilable(String)) }
    attr_reader :prerequire
    sig { returns(T.nilable(String)) }
    attr_reader :postrequire
    sig { returns(String) }
    attr_reader :command
    sig { returns(T::Hash[String, String]) }
    attr_reader :typed_overrides

    sig do
      params(
        outdir: T.nilable(String),
        prerequire: T.nilable(String),
        postrequire: T.nilable(String),
        command: T.nilable(String),
        typed_overrides: T.nilable(T::Hash[String, String])
      ).void
    end
    def initialize(outdir: nil, prerequire: nil, postrequire: nil, command: nil, typed_overrides: nil)
      @outdir = T.let(Pathname.new(outdir || DEFAULT_OUTDIR), Pathname)
      @prerequire = T.let(prerequire, T.nilable(String))
      @postrequire = T.let(postrequire, T.nilable(String))
      @command = T.let(command || default_command, String)
      @typed_overrides = T.let(typed_overrides || {}, T::Hash[String, String])
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

      gems_to_generate(gem_names).map do |gem|
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

    sig { returns(String) }
    def default_command
      command = File.basename($PROGRAM_NAME)
      args = ARGV.join(" ")

      "#{command} #{args}"
    end

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
      loader.load_bundle(prerequire, postrequire)
      say(" Done", :green)
      puts
    end

    sig { returns(T::Hash[String, String]) }
    def existing_rbis
      @existing_rbis ||= Dir.glob("*@*.rbi", T.unsafe(base: outdir))
        .map { |f| File.basename(f, ".*").split('@') }
        .to_h
    end

    sig { returns(T::Hash[String, String]) }
    def expected_rbis
      @expected_rbis ||= bundle.dependencies
        .map { |gem| [gem.name, gem.version.to_s] }
        .to_h
    end

    sig { params(gem_name: String, version: String).returns(Pathname) }
    def rbi_filename(gem_name, version)
      outdir / "#{gem_name}@#{version}.rbi"
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

      typed_sigil = typed_overrides[gem.name] || DEFAULT_OVERRIDES[gem.name] || "true"

      content = compiler.compile(gem)
      content.prepend(rbi_header(command, typed_sigil))

      FileUtils.mkdir_p(outdir)
      filename = outdir / gem.rbi_file_name
      File.write(filename.to_s, content)

      say("Done", :green)

      outdir.glob("#{gem.name}@*.rbi") do |file|
        remove(file) unless file.basename.to_s == gem.rbi_file_name
      end
    end
  end
end
