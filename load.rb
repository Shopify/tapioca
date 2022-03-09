# typed: true
# frozen_string_literal: true

# loader = Tapioca::Runtime::Loader.new
# loader.load_autoloads

# # Insert your custom code here

# puts "LOADED"

Tapioca.load do
  load_bundle
  load_autoloads
end

loader = Tapioca::Runtime::Loader.new
gemfile = Tapioca::Gemfile.new([])
loader.load_bundle(gemfile, nil, nil)
