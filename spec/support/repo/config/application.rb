# typed: true
# frozen_string_literal: true

require "sidekiq"
require "smart_properties"
require "active_support/all"
require "baz"

# Fake as much of Rails as we can
module Rails
  class Application
    attr_reader :config

    def load_tasks; end
  end

  def self.application
    Application.new
  end
end

Dir[File.expand_path("../../lib/**/*.rb", __FILE__)].sort.each do |file|
  require(file)
end
