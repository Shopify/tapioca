# typed: strict
# frozen_string_literal: true

require "helpers/mock_dir"

module Tapioca
  # A mock gem used for testing purposes
  class MockGem < Spoom::Context
    extend T::Sig

    # The gem's name
    sig { returns(String) }
    attr_reader :name

    # The gem's version string such as "1.0.0" or ">= 2.0.5"
    sig { returns(String) }
    attr_reader :version

    # The dependencies to be added to the gem's gemspec
    sig { returns(T::Array[String]) }
    attr_reader :dependencies

    # Create a new mock gem at `path`
    sig { params(path: String, name: String, version: String, dependencies: T::Array[String]).void }
    def initialize(path, name, version, dependencies = [])
      super(path)
      @name = name
      @version = version
      @dependencies = dependencies
    end

    # Write `contents` to the gem's gemspec
    sig { params(contents: String).void }
    def gemspec(contents)
      write!("#{name}.gemspec", contents)
    end

    # The line to add to a project gemfile to require this gem
    sig { returns(String) }
    def gemfile_line
      "gem '#{name}', path: '#{absolute_path}'"
    end

    # The default gemspec contents string
    sig { returns(String) }
    def default_gemspec_contents
      dependencies = self.dependencies.map do |gem|
        "spec.add_dependency(\"#{gem}\")"
      end
      <<~GEMSPEC
        Gem::Specification.new do |spec|
          spec.name          = "#{name}"
          spec.version       = "#{version}"
          spec.authors       = ["Test User"]
          spec.email         = ["test@example.com"]

          spec.summary       = "Test Gem"
          spec.homepage      = "https://example.com/"
          spec.license       = "MIT"

          spec.metadata["allowed_push_host"] = "no"

          spec.require_paths = ["lib"]

          spec.files         = Dir.glob("lib/**/*.rb")

          #{dependencies.join("\n")}
        end
      GEMSPEC
    end
  end
end
