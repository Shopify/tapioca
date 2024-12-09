# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../../Gemfile", __dir__)

require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])
$LOAD_PATH.unshift(File.expand_path("../../../lib", __dir__))

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
  end
end
