# typed: true
# frozen_string_literal: true

module Tapioca
  module Loaders
    class Loader
      extend T::Sig
      extend T::Helpers

      include Thor::Base
      include CliHelper
      include Tapioca::GemHelper

      abstract!

      sig { abstract.void }
      def load; end

      private

      sig do
        params(gemfile: Tapioca::Gemfile, initialize_file: T.nilable(String), require_file: T.nilable(String)).void
      end
      def load_bundle(gemfile, initialize_file, require_file)
        require_helper(initialize_file)

        load_rails_application

        gemfile.require_bundle

        require_helper(require_file)

        load_rails_engines
      end

      sig { params(environment_load: T::Boolean, eager_load: T::Boolean, app_root: String).void }
      def load_rails_application(environment_load: false, eager_load: false, app_root: ".")
        return unless File.exist?("#{app_root}/config/application.rb")

        silence_deprecations

        if environment_load
          require "./#{app_root}/config/environment"
        else
          require "./#{app_root}/config/application"
        end

        eager_load_rails_app if eager_load
      rescue LoadError, StandardError => e
        say(
          "Tapioca attempted to load the Rails application after encountering a `config/application.rb` file, " \
            "but it failed. If your application uses Rails please ensure it can be loaded correctly before " \
            "generating RBIs.\n#{e}",
          :yellow,
        )
        say("Continuing RBI generation without loading the Rails application.")
      end

      sig { void }
      def load_rails_engines
        return if rails_engines.empty?

        with_rails_application do
          rails_engines.each do |engine|
            eager_load_engine(engine)
          end
        end

        rails_autoloader&.setup
      end

      sig { params(engine: T.class_of(Rails::Engine)).void }
      def eager_load_engine(engine)
        if rails_autoloader
          engine.config.eager_load_paths.each do |path|
            # Zeitwerk only accepts existing directories in `push_dir`.
            next unless File.directory?(path)

            rails_autoloader.push_dir(path)
          end
        else
          errored_files = []

          engine.config.eager_load_paths.each do |load_path|
            Dir.glob("#{load_path}/**/*.rb").sort.each do |file|
              require(file)
            rescue LoadError, StandardError
              errored_files << file
            end
          end

          errored_files.each do |file|
            require(file)
          rescue LoadError, StandardError
            nil
          end
        end
      end

      sig { returns(T.untyped) }
      def rails_autoloader
        return @rails_autoloader if defined?(@rails_autoloader)

        @rails_autoloader = T.let(Rails.autoloaders.once, T.untyped) if Rails.respond_to?(:autoloaders)
      end

      sig { params(blk: T.proc.void).void }
      def with_rails_application(&blk)
        # Store the current Rails.application object so that we can restore it
        rails_application = Rails.application

        # Create a new Rails::Application object, so that we can load the engines.
        # Some engines and the `Rails.autoloaders` call might expect `Rails.application`
        # to be set, so we need to create one here.
        unless rails_application
          Rails.application = Class.new(Rails::Application)
        end

        blk.call
      ensure
        Rails.app_class = Rails.application = rails_application
      end

      T::Sig::WithoutRuntime.sig { returns(T::Array[T.class_of(Rails::Engine)]) }
      def rails_engines
        return [] unless defined?(Rails::Engine)

        safe_require("active_support/core_ext/class/subclasses")

        project_path = Bundler.default_gemfile.parent.expand_path
        # We can use `Class#descendants` here, since we know Rails is loaded
        Rails::Engine
          .descendants
          .reject(&:abstract_railtie?)
          .reject { |engine| gem_in_app_dir?(project_path, engine.config.root.to_path) }
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
        if defined?(ActiveSupport::Deprecation)
          ActiveSupport::Deprecation.silenced = true
        end
      end

      sig { void }
      def eager_load_rails_app
        application = Rails.application

        if defined?(ActiveSupport)
          ActiveSupport.run_load_hooks(:before_eager_load, application)
        end

        if defined?(Zeitwerk::Loader)
          Zeitwerk::Loader.eager_load_all
        end

        if Rails.respond_to?(:autoloaders)
          Rails.autoloaders.each(&:eager_load)
        end

        if application.config.respond_to?(:eager_load_namespaces)
          application.config.eager_load_namespaces.each(&:eager_load!)
        end
      end

      sig { params(file: T.nilable(String)).void }
      def require_helper(file)
        return unless file

        file = File.absolute_path(file)
        return unless File.exist?(file)

        require(file)
      end
    end
  end
end
