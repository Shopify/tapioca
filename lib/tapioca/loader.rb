# typed: strict
# frozen_string_literal: true

require "tapioca/core_ext/class"

module Tapioca
  class Loader
    extend(T::Sig)

    sig { params(gemfile: Tapioca::Gemfile, initialize_file: T.nilable(String), require_file: T.nilable(String)).void }
    def load_bundle(gemfile, initialize_file, require_file)
      require_helper(initialize_file)

      load_rails_application
      load_rake

      gemfile.require

      require_helper(require_file)

      load_rails_engines
    end

    sig { params(environment_load: T::Boolean, eager_load: T::Boolean).void }
    def load_rails_application(environment_load: false, eager_load: false)
      return unless File.exist?("config/application.rb")

      safe_require("rails")

      silence_deprecations

      safe_require("rails/generators/test_case")
      if environment_load
        safe_require("./config/environment")
      else
        safe_require("./config/application")
      end

      eager_load_rails_app if eager_load
    end

    private

    sig { params(file: T.nilable(String)).void }
    def require_helper(file)
      return unless file
      file = File.absolute_path(file)
      return unless File.exist?(file)

      require(file)
    end

    sig { returns(T::Array[T.untyped]) }
    def rails_engines
      return [] unless Object.const_defined?("Rails::Engine")

      Object.const_get("Rails::Engine").descendants.reject(&:abstract_railtie?)
    end

    sig { params(path: String).void }
    def safe_require(path)
      require path
    rescue LoadError
      nil
    end

    sig { void }
    def load_rake
      safe_require("rake")
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

    sig { void }
    def load_rails_engines
      rails_engines.each do |engine|
        errored_files = []

        engine.config.eager_load_paths.each do |load_path|
          Dir.glob("#{load_path}/**/*.rb").sort.each do |file|
            require(file)
          rescue LoadError, StandardError
            errored_files << file
          end
        end

        # Try files that have errored one more time
        # It might have been a load order problem
        errored_files.each do |file|
          require(file)
        rescue LoadError, StandardError
          nil
        end
      end
    end
  end
end
