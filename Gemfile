# frozen_string_literal: true

source("https://rubygems.org")

gemspec

gem 'rubocop-shopify', require: false

group(:deployment, :development) do
  gem("rake", "~> 12.3")
end

group(:development, :test) do
  gem("smart_properties", ">= 1.15.0", require: false)
  gem("frozen_record", ">= 0.17", require: false)
  gem("sprockets", "~> 3.7", require: false)
  gem("rails", "~> 5.2", require: false)
  gem("state_machines", "~> 0.5.0", require: false)
end
