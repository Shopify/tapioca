# frozen_string_literal: true

source("https://rubygems.org")

gemspec

gem "rubocop-shopify", require: false

group(:deployment, :development) do
  gem("rake")
end

gem("yard", "~> 0.9.25")
gem("pry-byebug")
gem("minitest")
gem("minitest-hooks")
gem("minitest-reporters")
gem("sorbet")

group(:development, :test) do
  gem("smart_properties", ">= 1.15.0", require: false)
  gem("frozen_record", ">= 0.17", require: false)
  gem("sprockets", require: false)
  gem("rails", require: false)
  gem("state_machines", require: false)
  gem("activerecord-typedstore", require: false)
  gem("sqlite3")
  gem("identity_cache", require: false)
  gem("cityhash", git: "https://github.com/csfrancis/cityhash.git",
                  ref: "3cfc7d01f333c01811d5e834f1495eaa29f87c36", require: false)
  gem("activemodel-serializers-xml", require: false)
  gem("activeresource", require: false)
  gem("google-protobuf", require: false)
  gem("sidekiq", require: false)
  gem("nokogiri", require: false)
  gem("shopify-money", require: false)
end

gem "rubocop-sorbet", ">= 0.4.1"
