# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "bar"
  spec.version       = "0.3.0"
  spec.authors       = ["Test User"]
  spec.email         = ["test@example.com"]

  spec.summary       = "Bar - Test Gem"
  spec.homepage      = "https://example.com/bar"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "no"

  spec.require_paths = ["lib"]

  spec.files         = Dir.glob("lib/**/*.rb")
end
