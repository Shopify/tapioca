# frozen_string_literal: true

source "https://rubygems.org"

gemspec

CURRENT_RAILS_VERSION = "8.1"
rails_version = ENV.fetch("RAILS_VERSION", CURRENT_RAILS_VERSION)

gem "minitest-hooks"
gem "minitest-reporters"
gem "debug"
gem "irb"
gem "rubocop-shopify"
gem "rubocop-sorbet", ">= 0.4.1"
gem "rubocop-rspec" # useful even though we use minitest/spec
gem "ruby-lsp", ">= 0.23.1"
gem "ruby-lsp-rails", ">= 0.4"

group :deployment, :development do
  gem "rake"
end

group :development, :test do
  if rails_version == "main"
    gem "rails", github: "rails/rails", branch: "main"
    gem "minitest", "< 7.0" 
  else
    rails_version = CURRENT_RAILS_VERSION if rails_version == "current"

    if rails_version == "8.1"
      rails_version = "8.1.2"
      gem "rails", "~> 8.1.2" # Fixes support for Minitest 6.0
    else
      gem "rails", "~> #{rails_version}.0"
    end

    if Gem::Version.new(rails_version) < Gem::Version.new("8.1.2")
      gem "minitest", "< 6.0" # Don't use Minitest 6 for Rails versions older than 8.1.2
    else
      gem "minitest", "< 7.0" # Rails 8.1.1 doesn't support minitest 6.0 which causes errors
    end
  end

  gem "sqlite3"
  gem "mutex_m"
  gem "smart_properties"
  # Needed for Ruby 4.0 compatibility
  # Can be removed once https://github.com/JsonApiClient/json_api_client/pull/416 is merged
  gem "json_api_client", github: "paracycle/json_api_client", branch: "uk-bump-versions"
  gem "frozen_record"
  gem "sprockets"
  gem "state_machines"
  gem "activerecord-typedstore"
  gem "identity_cache"
  gem "cityhash" # identity_cache emits a warning if this is not present
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

gem "kramdown", "~> 2.5"
