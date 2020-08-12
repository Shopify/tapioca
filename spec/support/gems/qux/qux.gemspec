# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "qux"
  spec.version       = "0.5.0"
  spec.authors       = ["Test User"]
  spec.email         = ["test@example.com"]

  spec.summary       = "Qux - Test Gem"
  spec.homepage      = "https://example.com/qux"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "no"

  spec.require_paths = ["lib"]

  spec.files         = Dir.glob("lib/**/*.rb")
end
