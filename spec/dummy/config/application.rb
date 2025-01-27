# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../../Gemfile", __dir__)

require "bundler/setup" if File.exist?(ENV["BUNDLE_GEMFILE"])
$LOAD_PATH.unshift(File.expand_path("../../../lib", __dir__))

require "rails" # minimal, instead of "rails/all"
require "active_record/railtie" # need for testing fixtures
require "active_job/railtie"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
  end
end
