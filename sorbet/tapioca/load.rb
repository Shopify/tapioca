# typed: true
# frozen_string_literal: true

# loader = Tapioca::Runtime::Loader.new
# loader.load_autoloads

# # Insert your custom code here

# puts "LOADED"

Tapioca.load(:gem) do
  require "fffdf"

  load_bundle
  load_autoloads

  require "rails/all"
  require "rails/generators"
  require "rails/generators/app_base"
  require "ansi/code"
  require "google/protobuf"
  require "rake/testtask"
  require "rubocop/rake_task"
end

Tapioca.load(:dsl) do
  require "my_custom_dsl_extension"
end
