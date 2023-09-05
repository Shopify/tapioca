# typed: strict
# frozen_string_literal: true

require "open3"
require "helpers/mock_gem"

module Tapioca
  # A mock project used for testing purposes
  class MockProject < Spoom::Context
    extend T::Sig

    # Path to Tapioca's source files
    TAPIOCA_PATH = T.let((Pathname.new(__FILE__) / ".." / ".." / "..").to_s, String)

    # Add a gem requirement to this project's gemfile from a `MockGem`
    sig { params(gem: MockGem, require: T.nilable(T.any(FalseClass, String))).void }
    def require_mock_gem(gem, require: nil)
      line = gem.gemfile_line.dup
      line << ", require: #{require.inspect}" unless require.nil?
      line << "\n"
      write_gemfile!(line, append: true)
    end

    # Add a gem requirement to this project's gemfile from a real gem
    sig { params(name: String, version: T.nilable(String), require: T.nilable(T.any(FalseClass, String))).void }
    def require_real_gem(name, version = nil, require: nil)
      line = +"gem \"#{name}\""
      line << ", \"#{version}\"" if version
      line << ", require: #{require.inspect}" unless require.nil?
      line << "\n"
      write_gemfile!(line, append: true)
    end

    # Default Gemfile contents requiring only Tapioca
    sig { returns(String) }
    def tapioca_gemfile
      <<~GEMFILE
        source("https://rubygems.org")

        gemspec name: "tapioca", path: "#{TAPIOCA_PATH}"
      GEMFILE
    end

    sig { returns(String) }
    def bundler_version
      @bundler_version || Bundler::VERSION
    end

    sig { void }
    def reset_bundler_version
      return unless @bundler_version

      bundle_install!
    end

    # Run `bundle install` in this project context (unbundled env)
    sig do
      override(allow_incompatible: true) # rubocop:disable Sorbet/AllowIncompatibleOverride
        .params(version: T.nilable(String))
        .returns(Spoom::ExecResult)
    end
    def bundle_install!(version: nil)
      @bundler_version = T.let(version, T.nilable(String))

      opts = {}
      opts[:chdir] = absolute_path
      Bundler.with_unbundled_env do
        cmd =
          # prerelease versions are not always available on rubygems.org
          # so in this case, we install whichever is the latest
          if ::Gem::Version.new(bundler_version).prerelease?
            ::Gem.install("bundler")
            "bundle install"
          else
            ::Gem.install("bundler", bundler_version)
            "bundle _#{bundler_version}_ install"
          end

        out, err, status = Open3.capture3(cmd, opts)
        Spoom::ExecResult.new(out: out, err: err, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
      end
    end

    # Run a `command` with `bundle exec` in this project context (unbundled env)
    sig do
      override(allow_incompatible: true) # rubocop:disable Sorbet/AllowIncompatibleOverride
        .params(command: String, env: T::Hash[String, String])
        .returns(Spoom::ExecResult)
    end
    def bundle_exec(command, env = {})
      opts = {}
      opts[:chdir] = absolute_path
      Bundler.with_unbundled_env do
        out, err, status = Open3.capture3(env, ["bundle", "_#{bundler_version}_", "exec", command].join(" "), opts)
        Spoom::ExecResult.new(out: out, err: err, status: T.must(status.success?), exit_code: T.must(status.exitstatus))
      end
    end

    # Run a Tapioca `command` with `bundle exec` in this project context (unbundled env)
    sig do
      params(
        command: String,
        enforce_typechecking: T::Boolean,
        exclude: T::Array[String],
      ).returns(Spoom::ExecResult)
    end
    def tapioca(command, enforce_typechecking: true, exclude: tapioca_dependencies)
      exec_command = ["tapioca", command]
      if command.start_with?(/gem/)
        exec_command << "--workers=1" unless command.match?("--workers")
        exec_command << "--no-doc" unless command.match?("--doc")
        exec_command << "--no-loc" unless command.match?("--loc")
        exec_command << "--exclude #{exclude.join(" ")}" unless command.match?("--exclude") || exclude.empty?
      elsif command.start_with?(/dsl/)
        exec_command << "--workers=1" unless command.match?("--workers")
      end

      env = {}
      env["ENFORCE_TYPECHECKING"] = if enforce_typechecking
        "1"
      else
        warn("Ignoring typechecking errors in CLI test")
        "0"
      end

      bundle_exec(exec_command.join(" "), env)
    end

    private

    sig { params(spec: ::Gem::Specification).returns(T::Array[::Gem::Specification]) }
    def transitive_runtime_deps(spec)
      spec.runtime_dependencies.concat(
        spec.runtime_dependencies.flat_map do |dep|
          transitive_runtime_deps(dep.to_spec)
        end,
      )
    end

    sig { returns(T::Array[String]) }
    def tapioca_dependencies
      @tapioca_dependencies ||= T.let(
        transitive_runtime_deps(::Gem.loaded_specs["tapioca"]).map(&:name).uniq,
        T.nilable(T::Array[String]),
      )
    end
  end
end
