# frozen_string_literal: true

source "https://rubygems.org"

gemspec

CURRENT_RAILS_VERSION = "8.1"
rails_version = ENV.fetch("RAILS_VERSION", CURRENT_RAILS_VERSION)

# Rails main and 8.1.2 onward support Minitest 6.
# Rails 8.0.x lacks support for Minitest 6 in released versions.
# TODO: Remove conditional once a Rails 8.0.x release with Minitest 6 support is cut.
# See: https://github.com/rails/rails/commit/ec62932ee7d31e0ef870e61c2d7de2c3efe3faa6
if rails_version == "8.0"
  gem "minitest", "< 6"
else
  gem "minitest"
end
gem "minitest-hooks"
gem "minitest-reporters"
gem "minitest-mock"
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
  else
    rails_version = CURRENT_RAILS_VERSION if rails_version == "current"
    gem "rails", "~> #{rails_version}.0"
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
  # TODO: Unlock when segfault in sorbet-static is fixed
  gem "sorbet-static", "< 0.6.12889"
end

group :test do
  gem "webmock"
end

gem "kramdown", "~> 2.5"
