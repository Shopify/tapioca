# frozen_string_literal: true

if RUBY_VERSION >= '3.0'
  module BundlerHack
    def __materialize__
      if name == 'google-protobuf'
        Bundler.settings.temporary(force_ruby_platform: true) do
          super
        end
      else
        super
      end
    end
  end
  Bundler::LazySpecification.prepend(BundlerHack)
end

source("https://rubygems.org")

gemspec

gem 'rubocop-shopify', require: false

group(:deployment, :development) do
  gem("rake")
end

gem("bundler")
gem("yard", "~> 0.9.25")
gem("pry-byebug")
gem("minitest")
gem("minitest-hooks")
gem("minitest-reporters")
gem("sorbet")

group(:development, :test) do
  gem("smart_properties", ">= 1.15.0", require: false)
  gem("frozen_record", ">= 0.17", require: false)
  gem("sprockets", "~> 3.7", require: false)
  gem("rails", "~> 6.1", require: false)
  gem("state_machines", "~> 0.5.0", require: false)
  gem("activerecord-typedstore", "~> 1.3", require: false)
  gem("sqlite3")
  gem("identity_cache", "~> 1.0", require: false)
  gem('cityhash', git: 'https://github.com/csfrancis/cityhash.git',
                  ref: '3cfc7d01f333c01811d5e834f1495eaa29f87c36', require: false)
  gem("activemodel-serializers-xml", "~> 1.0", require: false)
  gem("activeresource", "~> 5.1", require: false)
  gem("google-protobuf", "~>3.12.0", require: false)
  # Fix version to 0.14.1 since it is the last version to support Ruby 2.4
  gem("shopify-money", "= 0.14.1", require: false)
  gem("sidekiq", "~>5.0", require: false) # Version 6 dropped support for Ruby 2.4
end

gem "rubocop-sorbet", ">= 0.4.1"
