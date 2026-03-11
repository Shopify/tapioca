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
        # prerelease versions are not always available on rubygems.org
        # so in this case, we install whichever is the latest
        if ::Gem::Version.new(bundler_version).prerelease?
          unless MockProject.installed_bundler_versions["prerelease"]
            ::Gem.install("bundler")
            MockProject.installed_bundler_versions["prerelease"] = true
          end
        else
          unless MockProject.installed_bundler_versions[bundler_version]
            ::Gem.install("bundler", bundler_version)
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
            Dir.glob(File.join(path, "*.gemspec")).sort.map { |f| File.read(f) rescue "" }.join
          end.join
          cache_key = Digest::SHA256.hexdigest("#{bundler_version}:#{gemfile_content}:#{local_gemspec_content}")
          FileUtils.mkdir_p(LOCKFILE_CACHE_DIR)
          cached_lockfile = File.join(LOCKFILE_CACHE_DIR, "#{cache_key}.lock")

          if File.exist?(cached_lockfile)
            FileUtils.cp(cached_lockfile, lockfile_path)
            return Spoom::ExecResult.new(out: "", err: "", status: true, exit_code: 0)
          end
        end

        cmd = if ::Gem::Version.new(bundler_version).prerelease?
          "bundle install --jobs=4 --prefer-local --quiet --retry=0"
        else
          "bundle _#{bundler_version}_ install --jobs=4 --prefer-local --quiet --retry=0"
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

    # Run a Tapioca `command` in this project context using ruby -rbundler/setup
    # for faster startup than `bundle exec`
    #: (String command, ?enforce_typechecking: bool, ?exclude: Array[String]) -> Spoom::ExecResult
    def tapioca(command, enforce_typechecking: false, exclude: tapioca_dependencies)
      args = command.split
      if args.first == "gem" || command.start_with?("gem")
        args << "--workers=1" unless command.match?("--workers")
        args << "--no-doc" unless command.match?("--doc")
        args << "--no-loc" unless command.match?("--loc")
        args << "--exclude" << exclude.join(" ") unless command.match?("--exclude") || exclude.empty?
      elsif args.first == "dsl" || command.start_with?("dsl")
        args << "--workers=1" unless command.match?("--workers")
      end

      # Detect the correct gemfile (Gemfile or gems.rb)
      gemfile_path = if File.exist?(File.join(absolute_path, "Gemfile"))
        File.join(absolute_path, "Gemfile")
      elsif File.exist?(File.join(absolute_path, "gems.rb"))
        File.join(absolute_path, "gems.rb")
      else
        File.join(absolute_path, "Gemfile")
      end

      env = {
        "ENFORCE_TYPECHECKING" => enforce_typechecking ? "1" : "0",
        "BUNDLE_GEMFILE" => gemfile_path,
      }

      opts = { chdir: absolute_path }
      Bundler.with_unbundled_env do
        cmd = "ruby -rbundler/setup #{File.join(TAPIOCA_PATH, "exe", "tapioca")} #{args.join(" ")}"
        out, err, status = Open3.capture3(env, cmd, opts)
        Spoom::ExecResult.new(out: out, err: err, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
      end
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
