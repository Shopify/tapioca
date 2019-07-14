# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "tapioca/version"

Gem::Specification.new do |spec|
  spec.name          = "tapioca"
  spec.version       = Tapioca::VERSION
  spec.authors       = ["Ufuk Kayserilioglu", "Alan Wu", "Alexandre Terrasa", "Peter Zhu"]
  spec.email         = ["rails@shopify.com"]

  spec.summary       = "A Ruby Interface file generator for gems, core types and the Ruby standard library"
  spec.homepage      = "https://github.com/Shopify/tapioca"
  spec.license       = "MIT"

  spec.bindir        = "exe"
  spec.executables   = %w(tapioca)
  spec.require_paths = ["lib"]

  spec.files         = Dir.glob("lib/**/*.rb") + %w(
    README.md
    Gemfile
    Rakefile
  )

  spec.add_dependency("pry", ">= 0.12.2")
  spec.add_dependency("sorbet-static", "~> 0.4.4371")
  spec.add_dependency("thor", "~> 0.20.3")
  spec.add_dependency("zeitwerk", "~> 2.1")
  spec.add_dependency("activesupport")

  spec.add_development_dependency("bundler", "~> 1.17")
  spec.add_development_dependency("pry-byebug")
  spec.add_development_dependency("rspec", "~> 3.7")
  spec.add_development_dependency("rubocop", "~> 0.70.0")
  spec.add_development_dependency("sorbet")
  spec.add_development_dependency("zeitwerk", "~> 2.1")
end
