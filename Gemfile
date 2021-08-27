# frozen_string_literal: true

source("https://rubygems.org")

gemspec

gem("minitest")
gem("minitest-hooks")
gem("minitest-reporters")
gem("pry-byebug")
gem("rubocop-shopify", require: false)
gem("rubocop-sorbet", ">= 0.4.1")
gem("sorbet")
gem("yard", "~> 0.9.25")

group(:deployment, :development) do
  gem("rake")
end

group(:development, :test) do
  gem("smart_properties", require: false)
  gem("frozen_record", require: false)
  gem("sprockets", require: false)
  gem("rails", require: false)
  gem("state_machines", require: false)
  gem("activerecord-typedstore", require: false)
  gem("sqlite3")
  gem("identity_cache", require: false)
  gem("cityhash", git: "https://github.com/csfrancis/cityhash.git",
                  ref: "3cfc7d01f333c01811d5e834f1495eaa29f87c36", require: false)
  gem("activeresource", require: false)
  gem("google-protobuf", require: false)
  gem("shopify-money", require: false)
  gem("sidekiq", require: false)
  gem("nokogiri", require: false)
  gem("config", require: false)
  gem("aasm", require: false)
end
