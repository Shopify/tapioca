# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "fizz"
  spec.version       = "0.4.0"
  spec.authors       = ["Test User"]
  spec.email         = ["test@example.com"]

  spec.summary       = "Fizz - Test Gem"
  spec.homepage      = "https://example.com/fizz"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "no"

  spec.require_paths = ["lib"]

  spec.files         = Dir.glob("lib/**/*.rb")
end
