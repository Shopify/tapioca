# frozen_string_literal: true

source("https://rubygems.org")

gemspec

gem 'rubocop-shopify', require: false

group(:deployment, :development) do
  gem("rake")
end

gem("bundler", "~> 1.17")
gem("pry-byebug")
gem("minitest")
gem("minitest-hooks")
gem("minitest-fork_executor")
gem("minitest-reporters")
gem("sorbet")

group(:development, :test) do
  gem("smart_properties", ">= 1.15.0", require: false)
  gem("frozen_record", ">= 0.17", require: false)
  gem("sprockets", "~> 3.7", require: false)
  gem("rails", "~> 5.2", require: false)
  gem("state_machines", "~> 0.5.0", require: false)
  gem("activerecord-typedstore", "~> 1.3", require: false)
  gem("sqlite3")
  gem("identity_cache", "~> 1.0", require: false)
  gem('cityhash', require: false)
end
