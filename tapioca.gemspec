# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "tapioca/version"

Gem::Specification.new do |spec|
  spec.name          = "tapioca"
  spec.version       = Tapioca::VERSION
  spec.authors       = ["Ufuk Kayserilioglu", "Alan Wu", "Alexandre Terrasa", "Peter Zhu"]
  spec.email         = ["ruby@shopify.com"]

  spec.summary       = "A Ruby Interface file generator for gems, core types and the Ruby standard library"
  spec.homepage      = "https://github.com/Shopify/tapioca"
  spec.license       = "MIT"

  spec.bindir        = "exe"
  spec.executables   = ["tapioca"]
  spec.require_paths = ["lib"]

  spec.files         = Dir.glob("lib/**/*.rb") + ["README.md", "LICENSE.txt"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.add_dependency("bundler", ">= 1.17.3")
  spec.add_dependency("netrc", ">= 0.11.0")
  spec.add_dependency("parallel", ">= 1.21.0")
  spec.add_dependency("pry", ">= 0.12.2")
  spec.add_dependency("rbi", "~> 0.0.0", ">= 0.0.14")
  spec.add_dependency("sorbet-static-and-runtime", ">= 0.5.9204")
  spec.add_dependency("spoom", "~> 1.1.0", ">= 1.1.11")
  spec.add_dependency("thor", ">= 1.2.0")
  spec.add_dependency("yard-sorbet")

  spec.required_ruby_version = ">= 2.7"
end
