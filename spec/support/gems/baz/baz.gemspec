# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "baz"
  spec.version       = "0.0.2"
  spec.authors       = ["Test User"]
  spec.email         = ["test@example.com"]

  spec.summary       = "Baz - Test Gem"
  spec.homepage      = "https://example.com/baz"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "no"

  spec.require_paths = ["lib"]

  spec.files         = Dir.glob("lib/**/*.rb")
end
