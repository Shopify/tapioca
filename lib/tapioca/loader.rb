# typed: strict
# frozen_string_literal: true

module Tapioca
  class Loader
    extend(T::Sig)

    sig { params(gemfile: Tapioca::Gemfile).void }
    def initialize(gemfile)
      @gemfile = T.let(gemfile, Tapioca::Gemfile)
    end

    sig { params(initialize_file: T.nilable(String), require_file: T.nilable(String)).void }
    def load_bundle(initialize_file, require_file)
      require_helper(initialize_file)

      load_rails
      load_rake

      require_bundle

      require_helper(require_file)

      load_rails_engines
    end

    sig { params(environment_load: T::Boolean, eager_load: T::Boolean).void }
    def load_rails(environment_load: false, eager_load: false)
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

    sig { returns(Tapioca::Gemfile) }
    attr_reader :gemfile

    sig { params(file: T.nilable(String)).void }
    def require_helper(file)
      return unless file
      file = File.absolute_path(file)
      return unless File.exist?(file)

      require(file)
    end

    sig { void }
    def require_bundle
      gemfile.require
    end

    sig { returns(T::Array[T.untyped]) }
    def rails_engines
      engines = []

      return engines unless Object.const_defined?("Rails::Engine")

      base = Object.const_get("Rails::Engine")
      ObjectSpace.each_object(base.singleton_class) do |k|
        k = T.cast(k, Class)
        next if k.singleton_class?
        engines.unshift(k) unless k == base
      end

      engines.reject(&:abstract_railtie?)
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
      if Object.const_defined?("ActiveSupport")
        Object.const_get("ActiveSupport").run_load_hooks(
          :before_eager_load,
          Object.const_get("Rails").application
        )
      end
      if Object.const_defined?("Zeitwerk::Loader")
        zeitwerk_loader = Object.const_get("Zeitwerk::Loader")
        zeitwerk_loader.eager_load_all
      end
      Object.const_get("Rails").autoloaders.each(&:eager_load)
    end

    sig { void }
    def load_rails_engines
      rails_engines.each do |engine|
        errored_files = []

        engine.config.eager_load_paths.each do |load_path|
          Dir.glob("#{load_path}/**/*.rb").sort.each do |file|
            begin
              require(file)
            rescue LoadError, StandardError
              errored_files << file
            end
          end
        end

        # Try files that have errored one more time
        # It might have been a load order problem
        errored_files.each do |file|
          begin
            require(file)
          rescue LoadError, StandardError
            nil
          end
        end
      end
    end
  end
end
