# typed: strict
# frozen_string_literal: true

require "open3"
require "digest"
require "helpers/mock_gem"

module Tapioca
  # A mock project used for testing purposes
  class MockProject < Spoom::Context
    # Path to Tapioca's source files
    TAPIOCA_PATH = (Pathname.new(__FILE__) / ".." / ".." / "..").to_s #: String

    # Cache which bundler versions have already been installed to avoid redundant Gem.install calls
    @installed_bundler_versions = {} #: Hash[String, bool]

    # Directory for caching Gemfile.lock files keyed by Gemfile content hash
    LOCKFILE_CACHE_DIR = "/tmp/tapioca/tests/lockfile_cache" #: String

    class << self
      #: Hash[String, bool]
      attr_reader :installed_bundler_versions
    end

    # Add a gem requirement to this project's gemfile from a `MockGem`
    #: (MockGem gem, ?require: (FalseClass | String)?) -> void
    def require_mock_gem(gem, require: nil)
      line = gem.gemfile_line.dup
      line << ", require: #{require.inspect}" unless require.nil?
      line << "\n"
      write_gemfile!(line, append: true)
    end

    # Add a gem requirement to this project's gemfile from a real gem
    #: (String name, ?String? version, ?require: (FalseClass | String)?) -> void
    def require_real_gem(name, version = nil, require: nil)
      line = +"gem \"#{name}\""
      line << ", \"#{version}\"" if version
      line << ", require: #{require.inspect}" unless require.nil?
      line << "\n"
      write_gemfile!(line, append: true)
    end

    #: -> void
    def require_default_gems
      require_real_gem("ostruct")
      require_real_gem("logger")
      # Rails 8.1.1 doesn't support minitest 6.0 which causes errors
      require_real_gem("minitest", "< 6.0")
    end

    # Default Gemfile contents requiring only Tapioca
    #: -> String
    def tapioca_gemfile
      <<~GEMFILE
        source("https://rubygems.org")

        gemspec name: "tapioca", path: "#{TAPIOCA_PATH}"
      GEMFILE
    end

    #: -> String
    def bundler_version
      @bundler_version || Bundler::VERSION
    end

    #: -> void
    def reset_bundler_version
      return unless @bundler_version

      bundle_install!
    end

    # Run `bundle install` in this project context (unbundled env)
    # @override(allow_incompatible: true)
    #: (?version: String?) -> Spoom::ExecResult
    def bundle_install!(version: nil)
      @bundler_version = version #: String?

      opts = {}
      opts[:chdir] = absolute_path
      Bundler.with_unbundled_env do
        # Ensure the required bundler version is installed.
        # Use a file lock to prevent concurrent Gem.install calls from corrupting
        # the gem directory when running tests in parallel.
        if ::Gem::Version.new(bundler_version).prerelease?
          unless MockProject.installed_bundler_versions["prerelease"]
            lockfile = File.join(LOCKFILE_CACHE_DIR, ".bundler_install.lock")
            FileUtils.mkdir_p(LOCKFILE_CACHE_DIR)
            File.open(lockfile, File::RDWR | File::CREAT) do |f|
              f.flock(File::LOCK_EX)
              begin
                ::Gem::Specification.find_by_name("bundler")
              rescue ::Gem::MissingSpecError
                ::Gem.install("bundler")
              end
            end
            MockProject.installed_bundler_versions["prerelease"] = true
          end
        else
          unless MockProject.installed_bundler_versions[bundler_version]
            lockfile = File.join(LOCKFILE_CACHE_DIR, ".bundler_install.lock")
            FileUtils.mkdir_p(LOCKFILE_CACHE_DIR)
            File.open(lockfile, File::RDWR | File::CREAT) do |f|
              f.flock(File::LOCK_EX)
              begin
                ::Gem::Specification.find_by_name("bundler", bundler_version)
              rescue ::Gem::MissingSpecError
                ::Gem.install("bundler", bundler_version)
              end
            end
            MockProject.installed_bundler_versions[bundler_version] = true
          end
        end

        # Try to reuse a cached Gemfile.lock if the Gemfile and referenced gemspecs haven't changed
        gemfile_path = File.join(absolute_path, "Gemfile")
        lockfile_path = File.join(absolute_path, "Gemfile.lock")

        if File.exist?(gemfile_path)
          gemfile_content = File.read(gemfile_path)
          # Include the content of any locally-referenced gemspec files in the cache key,
          # since a gem's version can change without the Gemfile changing
          local_gemspec_content = gemfile_content.scan(/path:\s*["']([^"']+)["']/).flatten.sort.map do |path|
            Dir.glob(File.join(path, "*.gemspec")).sort.map do |f|
              File.read(f)
            rescue
              ""
            end.join
          end.join
          cache_key = Digest::SHA256.hexdigest("#{bundler_version}:#{gemfile_content}:#{local_gemspec_content}")
          FileUtils.mkdir_p(LOCKFILE_CACHE_DIR)
          cached_lockfile = File.join(LOCKFILE_CACHE_DIR, "#{cache_key}.lock")

          if File.exist?(cached_lockfile)
            # Pre-populate lockfile so `bundle install` skips resolution (fast path).
            # We still run `bundle install` to ensure gems are actually installed.
            FileUtils.cp(cached_lockfile, lockfile_path)
          end
        end

        cmd = if ::Gem::Version.new(bundler_version).prerelease?
          "bundle install --jobs=4 --quiet --retry=0"
        else
          "bundle _#{bundler_version}_ install --jobs=4 --quiet --retry=0"
        end

        out, err, status = Open3.capture3(cmd, opts)

        # Cache the lockfile on success
        if status.success? && cached_lockfile && File.exist?(lockfile_path)
          FileUtils.cp(lockfile_path, cached_lockfile)
        end

        Spoom::ExecResult.new(out: out, err: err, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
      end
    end

    # Run a `command` with `bundle exec` in this project context (unbundled env)
    # @override(allow_incompatible: true)
    #: (String command, ?Hash[String, String] env) -> Spoom::ExecResult
    def bundle_exec(command, env = {})
      opts = {}
      opts[:chdir] = absolute_path
      Bundler.with_unbundled_env do
        out, err, status = Open3.capture3(env, ["bundle", "_#{bundler_version}_", "exec", command].join(" "), opts)
        Spoom::ExecResult.new(out: out, err: err, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
      end
    end

    # Run a Tapioca `command` with `bundle exec` in this project context (unbundled env)
    #: (String command, ?enforce_typechecking: bool, ?skip_validation: bool, ?exclude: Array[String]) -> Spoom::ExecResult
    def tapioca(command, enforce_typechecking: false, skip_validation: true, exclude: tapioca_dependencies)
      args = command.split
      if args.first == "gem" || command.start_with?("gem")
        args << "--workers=1" unless command.match?("--workers")
        args << "--no-doc" unless command.match?("--doc")
        args << "--no-loc" unless command.match?("--loc")
        args << "--exclude" << exclude.join(" ") unless command.match?("--exclude") || exclude.empty?
      elsif args.first == "dsl" || command.start_with?("dsl")
        args << "--workers=1" unless command.match?("--workers")
      end

      env = {
        "ENFORCE_TYPECHECKING" => enforce_typechecking ? "1" : "0",
      }
      env["TAPIOCA_SKIP_VALIDATION"] = "1" if skip_validation

      bundle_exec("tapioca #{args.join(" ")}", env)
    end

    # Fast in-process alternative to `tapioca("configure")` that creates
    # the required configuration files without spawning a subprocess (~0.8s savings)
    #: -> void
    def configure!
      write!("sorbet/config", <<~CONTENT)
        --dir
        .
        --ignore=tmp/
        --ignore=vendor/
      CONTENT

      write!("sorbet/tapioca/config.yml", <<~YAML)
        gem:
          # Add your `gem` command parameters here:
          #
          # exclude:
          # - gem_name
          # doc: true
          # workers: 5
        dsl:
          # Add your `dsl` command parameters here:
          #
          # exclude:
          # - SomeGeneratorName
          # workers: 5
      YAML

      write!("sorbet/tapioca/require.rb", <<~CONTENT)
        # typed: true
        # frozen_string_literal: true

        # Add your extra requires here (`bin/tapioca require` can be used to bootstrap this list)
      CONTENT
    end

    private

    #: (::Gem::Specification spec) -> Array[::Gem::Specification]
    def transitive_runtime_deps(spec)
      spec.runtime_dependencies.concat(
        spec.runtime_dependencies.flat_map do |dep|
          transitive_runtime_deps(dep.to_spec)
        end,
      )
    end

    #: -> Array[String]
    def tapioca_dependencies
      @tapioca_dependencies ||=
        transitive_runtime_deps(::Gem.loaded_specs["tapioca"]).map(&:name).uniq #: Array[String]?
    end
  end
end
