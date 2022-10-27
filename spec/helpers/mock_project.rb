# typed: strict
# frozen_string_literal: true

require "open3"
require "helpers/mock_gem"

module Tapioca
  # A mock project used for testing purposes
  class MockProject < MockDir
    extend T::Sig

    # Path to Tapioca's source files
    TAPIOCA_PATH = T.let((Pathname.new(__FILE__) / ".." / ".." / "..").to_s, String)

    # Write `contents` to the gemfile in this project
    sig { params(contents: String, append: T::Boolean).void }
    def gemfile(contents, append: false)
      write("Gemfile", contents, append: append)
    end

    # Add a gem requirement to this project's gemfile from a `MockGem`
    sig { params(gem: MockGem, require: T.nilable(T.any(FalseClass, String))).void }
    def require_mock_gem(gem, require: nil)
      line = gem.gemfile_line.dup
      line << ", require: #{require.inspect}" unless require.nil?
      line << "\n"
      gemfile(line, append: true)
    end

    # Add a gem requirement to this project's gemfile from a real gem
    sig { params(name: String, version: T.nilable(String), require: T.nilable(T.any(FalseClass, String))).void }
    def require_real_gem(name, version = nil, require: nil)
      line = +"gem \"#{name}\""
      line << ", \"#{version}\"" if version
      line << ", require: #{require.inspect}" unless require.nil?
      line << "\n"
      gemfile(line, append: true)
    end

    # Default Gemfile contents requiring only Tapioca
    sig { returns(String) }
    def tapioca_gemfile
      <<~GEMFILE
        source("https://rubygems.org")

        gemspec name: "tapioca", path: "#{TAPIOCA_PATH}"
      GEMFILE
    end

    # Write `contents` to the `sorbet/config` file of this project
    sig { params(contents: String, append: T::Boolean).void }
    def sorbet_config(contents, append: false)
      write("sorbet/config", contents, append: append)
    end

    sig { returns(String) }
    def bundler_version
      @bundler_version || Bundler::VERSION
    end

    sig { void }
    def reset_bundler_version
      return unless @bundler_version

      bundle_install
    end

    class ExecResult < T::Struct
      extend T::Sig

      const :out, String
      const :err, String
      const :status, T::Boolean

      sig { returns(String) }
      def to_s
        <<~STR
          ########## STDOUT ##########
          #{out.empty? ? "<empty>" : out}
          ########## STDERR ##########
          #{err.empty? ? "<empty>" : err}
          ########## STATUS: #{status} ##########
        STR
      end
    end

    # Run `bundle install` in this project context (unbundled env)
    sig { params(version: T.nilable(String)).returns(ExecResult) }
    def bundle_install(version: nil)
      @bundler_version = T.let(version, T.nilable(String))

      opts = {}
      opts[:chdir] = path
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
        ExecResult.new(out: out, err: err, status: T.must(status.success?))
      end
    end

    # Run a `command` with `bundle exec` in this project context (unbundled env)
    sig { params(command: String).returns(ExecResult) }
    def bundle_exec(command)
      opts = {}
      opts[:chdir] = path
      Bundler.with_unbundled_env do
        out, err, status = Open3.capture3(["bundle", "_#{bundler_version}_", "exec", command].join(" "), opts)
        ExecResult.new(out: out, err: err, status: T.must(status.success?))
      end
    end

    # Run a Tapioca `command` with `bundle exec` in this project context (unbundled env)
    sig { params(command: String).returns(ExecResult) }
    def tapioca(command)
      exec_command = ["tapioca", command]
      if command.start_with?(/gem/)
        exec_command << "--workers=1" unless command.match?("--workers")
        exec_command << "--no-doc" unless command.match?("--doc")
        exec_command << "--no-loc" unless command.match?("--loc")
      elsif command.start_with?(/dsl/)
        exec_command << "--workers=1" unless command.match?("--workers")
      end
      bundle_exec(exec_command.join(" "))
    end
  end
end
