# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "foo"
  spec.version       = "0.0.1"
  spec.authors       = ["Test User"]
  spec.email         = ["test@example.com"]

  spec.summary       = "Foo - Test Gem"
  spec.homepage      = "https://example.com/foo"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "no"

  spec.require_paths = ["lib"]

  spec.files         = Dir.glob("lib/**/*.rb")
end
