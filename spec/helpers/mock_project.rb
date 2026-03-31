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

    # Directory for caching Gemfile.lock files and cross-process lock/marker files
    LOCKFILE_CACHE_DIR = "/tmp/tapioca/tests/lockfile_cache" #: String

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
    #
    # All gem installation is serialized across parallel test workers using a global
    # file lock to prevent ETXTBSY (concurrent binstub write + exec) and GemNotFound
    # (partially-installed gems visible to concurrent bundle exec) race conditions.
    # With lockfile caching, most `bundle install` calls are fast no-ops (~1-2s) so
    # serialization has minimal performance impact.
    #
    # @override(allow_incompatible: true)
    #: (?version: String?) -> Spoom::ExecResult
    def bundle_install!(version: nil)
      @bundler_version = version #: String?

      opts = {}
      opts[:chdir] = absolute_path
      Bundler.with_unbundled_env do
        # All gem operations (Gem.install + bundle install) are serialized under a single
        # global lock to prevent race conditions when multiple workers share GEM_HOME.
        global_lock = File.join(LOCKFILE_CACHE_DIR, ".bundle_install_global.lock")
        FileUtils.mkdir_p(LOCKFILE_CACHE_DIR)
        File.open(global_lock, File::RDWR | File::CREAT) do |lock_file|
          lock_file.flock(File::LOCK_EX)

          # Ensure the required bundler version is installed.
          # Use cross-process marker files instead of in-memory cache (which doesn't
          # survive across fork+exec in parallel workers).
          ensure_bundler_installed!

          # Try to reuse a cached Gemfile.lock if the Gemfile and referenced gemspecs haven't changed
          cached_lockfile = populate_lockfile_from_cache

          cmd = if ::Gem::Version.new(bundler_version).prerelease?
            "bundle install --jobs=4 --quiet --retry=0"
          else
            "bundle _#{bundler_version}_ install --jobs=4 --quiet --retry=0"
          end

          out, err, status = Open3.capture3(cmd, opts)

          # Cache the lockfile on success (atomic write to prevent partial reads)
          lockfile_path = File.join(absolute_path, "Gemfile.lock")
          if status.success? && cached_lockfile && File.exist?(lockfile_path)
            tmp = "#{cached_lockfile}.#{Process.pid}.tmp"
            FileUtils.cp(lockfile_path, tmp)
            File.rename(tmp, cached_lockfile)
          end

          Spoom::ExecResult.new(out: out, err: err, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
        end
      end
    end

    # Run a `command` with `bundle exec` in this project context (unbundled env)
    #
    # Takes a shared (read) lock on the global gem lock so that `bundle exec` calls
    # can run concurrently with each other, but never concurrently with `bundle install`
    # (which takes an exclusive lock). This prevents ETXTBSY errors where bundle install
    # writes binstubs while bundle exec tries to execute them.
    #
    # @override(allow_incompatible: true)
    #: (String command, ?Hash[String, String] env) -> Spoom::ExecResult
    def bundle_exec(command, env = {})
      opts = {}
      opts[:chdir] = absolute_path
      Bundler.with_unbundled_env do
        global_lock = File.join(LOCKFILE_CACHE_DIR, ".bundle_install_global.lock")
        FileUtils.mkdir_p(LOCKFILE_CACHE_DIR)
        File.open(global_lock, File::RDWR | File::CREAT) do |lock_file|
          lock_file.flock(File::LOCK_SH)
          out, err, status = Open3.capture3(env, ["bundle", "_#{bundler_version}_", "exec", command].join(" "), opts)
          Spoom::ExecResult.new(out: out, err: err, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
        end
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

    # Ensure the required bundler version is installed, using a cross-process marker
    # file to avoid redundant Gem.install calls across parallel workers.
    # MUST be called while holding the global bundle install lock.
    #: -> void
    def ensure_bundler_installed!
      marker_name = if ::Gem::Version.new(bundler_version).prerelease?
        ".bundler_installed_prerelease"
      else
        ".bundler_installed_#{bundler_version}"
      end
      marker_path = File.join(LOCKFILE_CACHE_DIR, marker_name)

      unless File.exist?(marker_path)
        begin
          if ::Gem::Version.new(bundler_version).prerelease?
            ::Gem::Specification.find_by_name("bundler")
          else
            ::Gem::Specification.find_by_name("bundler", bundler_version)
          end
        rescue ::Gem::MissingSpecError
          if ::Gem::Version.new(bundler_version).prerelease?
            ::Gem.install("bundler")
          else
            ::Gem.install("bundler", bundler_version)
          end
        end
        FileUtils.touch(marker_path)
      end
    end

    # Pre-populate the project's Gemfile.lock from cache if available.
    # Returns the cached lockfile path (for writing back on success), or nil.
    # MUST be called while holding the global bundle install lock.
    #: -> String?
    def populate_lockfile_from_cache
      gemfile_path = File.join(absolute_path, "Gemfile")
      lockfile_path = File.join(absolute_path, "Gemfile.lock")

      return unless File.exist?(gemfile_path)

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
      cached_lockfile = File.join(LOCKFILE_CACHE_DIR, "#{cache_key}.lock")

      if File.exist?(cached_lockfile)
        # Pre-populate lockfile so `bundle install` skips resolution (fast path).
        # We still run `bundle install` to ensure gems are actually installed.
        FileUtils.cp(cached_lockfile, lockfile_path)
      end

      cached_lockfile
    end

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
