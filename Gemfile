# frozen_string_literal: true

source "https://rubygems.org"

gemspec

CURRENT_RAILS_VERSION = "7.1"
rails_version = ENV.fetch("RAILS_VERSION", CURRENT_RAILS_VERSION)

gem "minitest"
gem "minitest-hooks"
gem "minitest-reporters"
gem "debug", require: false
gem "pry"
gem "pry-byebug"
gem "rubocop-shopify", require: false
gem "rubocop-sorbet", ">= 0.4.1"
gem "rubocop-rspec", require: false

group :deployment, :development do
  gem "rake"
end

group :development, :test do
  if rails_version == "main"
    gem "rails", github: "rails/rails", branch: "main"
  else
    rails_version = CURRENT_RAILS_VERSION if rails_version == "current"
    gem "rails", "~> #{rails_version}.0"
  end

  gem "mutex_m", require: false
  gem "smart_properties", require: false
  gem "json_api_client", require: false
  gem "frozen_record", require: false
  gem "sprockets", require: false
  gem "state_machines", require: false
  gem "activerecord-typedstore", require: false
  gem "sqlite3"
  gem "identity_cache", require: false
  gem "cityhash",
    git: "https://github.com/csfrancis/cityhash.git",
    ref: "3cfc7d01f333c01811d5e834f1495eaa29f87c36",
    require: false
  gem "activeresource", require: false
  gem "google-protobuf", require: false
  gem "graphql", require: false
  gem "shopify-money", require: false
  gem "sidekiq", require: false
  gem "nokogiri", require: false
  gem "config", require: false
  gem "aasm", require: false
  gem "bcrypt", require: false
  gem "xpath", require: false
  gem "kredis", require: false
end

group :test do
  gem "webmock"
end

gem "kramdown", "~> 2.4"
