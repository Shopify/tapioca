# typed: strict
# frozen_string_literal: true

module Tapioca
  # A mock gem used for testing purposes
  class MockGem < Spoom::Context
    extend T::Sig

    # The gem's name
    #: String
    attr_reader :name

    # The gem's version string such as "1.0.0" or ">= 2.0.5"
    #: String
    attr_reader :version

    # The dependencies to be added to the gem's gemspec
    #: Array[String]
    attr_reader :dependencies

    # Create a new mock gem at `path`
    #: (String path, String name, String version, ?Array[String] dependencies) -> void
    def initialize(path, name, version, dependencies = [])
      super(path)
      @name = name
      @version = version
      @dependencies = dependencies
    end

    # Write `contents` to the gem's gemspec
    #: (String contents) -> void
    def gemspec(contents)
      write!("#{name}.gemspec", contents)
    end

    # The line to add to a project gemfile to require this gem
    #: -> String
    def gemfile_line
      "gem '#{name}', path: '#{absolute_path}'"
    end

    # The default gemspec contents string
    #: -> String
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

    #: (String version) -> void
    def update(version)
      @version = version
      gemspec(default_gemspec_contents)
    end
  end
end
