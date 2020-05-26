# frozen_string_literal: true

source("https://rubygems.org")

gemspec

gem 'rubocop-shopify', require: false

group(:deployment, :development) do
  gem("rake", "~> 12.3")
end

group(:development, :test) do
  gem("smart_properties", ">= 1.15.0")
end
