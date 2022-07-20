# typed: true
# frozen_string_literal: true

module Tapioca
  module Loaders
    class Loader
      extend T::Sig
      extend T::Helpers

      include Thor::Base
      include CliHelper

      abstract!

      sig { abstract.void }
      def load; end

      private

      sig { params(environment_load: T::Boolean, eager_load: T::Boolean).void }
      def load_rails_application(environment_load: false, eager_load: false)
        return unless File.exist?("config/application.rb")

        silence_deprecations

        if environment_load
          safe_require("./config/environment")
        else
          safe_require("./config/application")
        end

        eager_load_rails_app if eager_load
      end

      sig { params(path: String).void }
      def safe_require(path)
        require path
      rescue LoadError
        nil
      end

      sig { void }
      def silence_deprecations
        # Stop any ActiveSupport Deprecations from being reported
        Object.const_get("ActiveSupport::Deprecation").silenced = true
      rescue NameError
        nil
      end

      sig { void }
      def eager_load_rails_app
        rails = Object.const_get("Rails")
        application = rails.application

        if Object.const_defined?("ActiveSupport")
          Object.const_get("ActiveSupport").run_load_hooks(
            :before_eager_load,
            application
          )
        end

        if Object.const_defined?("Zeitwerk::Loader")
          zeitwerk_loader = Object.const_get("Zeitwerk::Loader")
          zeitwerk_loader.eager_load_all
        end

        if rails.respond_to?(:autoloaders) && rails.autoloaders.zeitwerk_enabled?
          rails.autoloaders.each(&:eager_load)
        end

        if application.config.respond_to?(:eager_load_namespaces)
          application.config.eager_load_namespaces.each(&:eager_load!)
        end
      end
    end
  end
end
