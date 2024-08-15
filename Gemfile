# frozen_string_literal: true

source "https://rubygems.org"

gemspec

CURRENT_RAILS_VERSION = "7.1"
rails_version = ENV.fetch("RAILS_VERSION", CURRENT_RAILS_VERSION)

gem "minitest", "< 5.25.0" # minitest 5.25.0+ is incompatible with minitest-hooks
gem "minitest-hooks"
gem "minitest-reporters"
gem "debug"
gem "irb"
gem "rubocop-shopify"
gem "rubocop-sorbet", ">= 0.4.1"
gem "rubocop-rspec"

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

  gem "mutex_m"
  gem "smart_properties"
  gem "json_api_client"
  gem "frozen_record"
  gem "sprockets"
  gem "state_machines"
  gem "activerecord-typedstore"
  gem "sqlite3", "~>1.4"
  gem "identity_cache"
  gem "cityhash",
    git: "https://github.com/csfrancis/cityhash.git",
    ref: "3cfc7d01f333c01811d5e834f1495eaa29f87c36",
    require: false
  gem "activeresource"
  gem "google-protobuf"
  gem "graphql"
  gem "shopify-money"
  gem "sidekiq"
  gem "nokogiri"
  gem "config"
  gem "aasm"
  gem "bcrypt"
  gem "xpath"
  gem "kredis"
end

group :test do
  gem "webmock"
end

gem "kramdown", "~> 2.4"
