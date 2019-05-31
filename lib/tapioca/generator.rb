# frozen_string_literals: true
# typed: true

require 'pathname'

module Tapioca
  class Generator
    extend(T::Sig)

    class GemNameError < RuntimeError
      attr_reader :gem_name

      def initialize(message, gem_name)
        super(message)
        @gem_name = gem_name
      end
    end

    sig { returns(Pathname) }
    attr_reader :outdir

    sig { returns(T.nilable(String)) }
    attr_reader :prerequire

    sig { returns(T.nilable(String)) }
    attr_reader :postrequire

    sig { params(outdir: String, prerequire: T.nilable(String), postrequire: T.nilable(String)).void }
    def initialize(outdir:, prerequire:, postrequire:)
      @outdir = T.let(Pathname.new(outdir), Pathname)
      @prerequire = T.let(prerequire, T.nilable(String))
      @postrequire = T.let(postrequire, T.nilable(String))
    end

    sig { params(gem_names: T::Array[String]).void }
    def build_gem_rbis(gem_names)
      Tapioca.silence_warnings do
        require_gem_file

        gems_to_generate(gem_names).map do |gem|
          compile_rbi(gem)
          puts
        end

        puts("All operations performed in working directory.")
        puts("Please review changes and commit them.")
      end
    end

    sig { void }
    def sync_rbis_with_gemfile
      Tapioca.silence_warnings do
        anything_done = [
          perform_removals,
          perform_additions
        ].any?

        if anything_done
          puts("All operations performed in working directory.")
          puts("Please review changes and commit them.")
        else
          puts("No operations performed, all RBIs are up-to-date.")
        end

        puts
      end
    end

    private

    sig { returns(Gemfile) }
    def gemfile
      @gemfile ||= Gemfile.new
    end

    sig { returns(Compilers::SymbolTableCompiler) }
    def compiler
      @compiler ||= Compilers::SymbolTableCompiler.new
    end

    sig { void }
    def require_gem_file
      gemfile.require_bundle(prerequire, postrequire)
    end

    sig { returns(T::Hash[String, String]) }
    def existing_rbis
      @existing_rbis ||= Dir.glob("*@*.rbi", T.unsafe(base: outdir.to_s))
        .map do |f|
          File.basename(f, ".*").split('@')
        end.to_h
    end

    sig { returns(T::Hash[String, String]) }
    def expected_rbis
      @expected_rbis ||= gemfile.dependencies
        .reject do |gem|
          # We don't want to generate RBIs for gems
          # that might happen to be in the current
          # directory (loaded via `path`)
          gem.full_gem_path.start_with?(Dir.pwd)
        end
        .map do |gem|
          [gem.name, gem.version.to_s]
        end.to_h
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
      puts("  ++ Adding: #{filename}")
      # status = execute("git add '#{filename}'")

      # unless status.success?
      #   $stderr.puts("    Failed to add RBI: #{filename}")
      #   exit(3)
      # end
    end

    sig { params(filename: Pathname).void }
    def remove(filename)
      puts("  -- Removing: #{filename}")
      filename.unlink
      # status = execute("git rm '#{filename}'")

      # unless status.success?
      #   $stderr.puts("    Failed to remove RBI: #{filename}")
      #   exit(3)
      # end
    end

    sig { params(old_filename: Pathname, new_filename: Pathname).void }
    def move(old_filename, new_filename)
      puts("  -> Moving: #{old_filename} to #{new_filename}")
      old_filename.rename(new_filename.to_s)
      # status = execute("git mv '#{old_filename}' '#{new_filename}'")

      # unless status.success?
      #   $stderr.puts("    Failed to move RBI: #{old_filename}")
      #   exit(3)
      # end
    end

    sig { void }
    def perform_removals
      puts("# Removing RBI files of gems that have been removed:")
      puts

      anything_done = false

      gems = removed_rbis

      if gems.empty?
        puts("  Nothing to do.")
      else
        gems.each do |removed|
          filename = existing_rbi(removed)
          remove(filename)
        end

        anything_done = true
      end

      puts

      anything_done
    end

    sig { void }
    def perform_additions
      puts("# Generating RBI files of gems that are added or updated:")
      puts

      anything_done = false

      gems = added_rbis

      if gems.empty?
        puts("  Nothing to do.")
      else
        require_gem_file

        gems.each do |gem_name|
          filename = expected_rbi(gem_name)

          if rbi_exists?(gem_name)
            old_filename = existing_rbi(gem_name)
            move(old_filename, filename) unless old_filename == filename
          end

          gem = T.must(gemfile.gem(gem_name))
          compile_rbi(gem)
          add(filename)

          puts
        end

        anything_done = true
      end

      puts

      anything_done
    end

    sig {
      params(gem_names: T::Array[String])
        .returns(T::Array[Gemfile::Gem])
    }
    def gems_to_generate(gem_names)
      return gemfile.dependencies if gem_names.empty?

      gem_names.map do |gem_name|
        gem = gemfile.gem(gem_name)
        raise GemNameError.new("cannot find gem", gem_name) if gem.nil?
        gem
      end
    end

    sig { params(gem: Gemfile::Gem).void }
    def compile_rbi(gem)
      compiler = Compilers::SymbolTableCompiler.new
      puts "  Compiling #{gem.name}, this may take a few seconds..."

      content = compiler.compile(gem)

      FileUtils.mkdir_p(outdir)
      filename = outdir / gem.rbi_file_name
      File.write(filename.to_s, content)

      puts "  Compiled #{filename}"
    end
  end
end
