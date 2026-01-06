# typed: true
# frozen_string_literal: true

module Tapioca
  module RailsSpecHelper
    extend Tapioca::Helpers::Test::Content

    class << self
      #: (String path) -> void
      def define_fake_rails_app(path)
        base_folder = Pathname.new(path)
        config_class = Struct.new(:root)
        config = config_class.new(base_folder)
        app_class = Struct.new(:config)
        Rails.application = app_class.new(config)
      end

      def load_active_storage
        add_ruby_file("application.rb", <<~RUBY)
          ENV["DATABASE_URL"] = "sqlite3::memory:"

          require "active_storage/engine"

          class Dummy < Rails::Application
            config.eager_load = true
            config.active_storage.service = :local
            if ActiveRecord::Base.respond_to?(:legacy_connection_handling=)
              config.active_record.legacy_connection_handling = false
            end
            config.active_storage.service_configurations = {
              local: {
                service: "Disk",
                root: Rails.root.join("storage")
              }
            }
            config.logger = Logger.new('/dev/null')
          end
          # The defaults are loaded with the first two version numbers (e.g. "7.1")
          defaults_version = Rails.gem_version.segments.take(2).join(".")
          Rails.configuration.load_defaults(defaults_version)
          Rails.application.initialize!
        RUBY
      end
    end
  end
end
