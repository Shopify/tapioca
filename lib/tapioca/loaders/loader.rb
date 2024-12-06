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
        params(
          gemfile: Tapioca::Gemfile,
          initialize_file: T.nilable(String),
          require_file: T.nilable(String),
          halt_upon_load_error: T::Boolean,
        ).void
      end
      def load_bundle(gemfile, initialize_file, require_file, halt_upon_load_error)
        require_helper(initialize_file)

        gemfile.require_bundle

        load_rails_application(environment_load: true, halt_upon_load_error: halt_upon_load_error)

        require_helper(require_file)
      end

      sig do
        params(
          environment_load: T::Boolean,
          eager_load: T::Boolean,
          app_root: String,
          halt_upon_load_error: T::Boolean,
        ).void
      end
      def load_rails_application(environment_load: false, eager_load: false, app_root: ".", halt_upon_load_error: true)
        return unless File.exist?(File.expand_path("config/application.rb", app_root))

        load_path = if environment_load
          "config/environment"
        else
          "config/application"
        end

        require File.expand_path(load_path, app_root)

        unless defined?(Rails)
          say(
            "\nTried to load the app from `#{load_path}` as a Rails application " \
              "but the `Rails` constant wasn't defined after loading the file.",
            :yellow,
          )
          return
        end

        eager_load_rails_app if eager_load
      rescue LoadError, StandardError => e
        say(
          "\nTapioca attempted to load the Rails application after encountering a `config/application.rb` file, " \
            "but it failed. If your application uses Rails please ensure it can be loaded correctly before " \
            "generating RBIs. If your application does not use Rails and you wish to continue RBI generation " \
            "please pass `--no-halt-upon-load-error` to the tapioca command in sorbet/tapioca/config.yml or in CLI." \
            "\n#{e}",
          :yellow,
        )
        raise e if halt_upon_load_error

        if e.backtrace
          backtrace = T.must(e.backtrace).join("\n")
          say(backtrace, :cyan) # TODO: Check verbose flag to print backtrace.
        end
        say("Continuing RBI generation without loading the Rails application.")
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

      # Rails 7.2 renamed `eager_load_paths` to `all_eager_load_paths`, which maintains the same original functionality.
      # The `eager_load_paths` method still exists, but doesn't return all paths anymore and causes Tapioca to miss some
      # engine paths. The following commit is the change:
      # https://github.com/rails/rails/commit/ebfca905db14020589c22e6937382e6f8f687664
      T::Sig::WithoutRuntime.sig { params(engine: T.class_of(Rails::Engine)).returns(T::Array[String]) }
      def eager_load_paths(engine)
        config = engine.config

        (config.respond_to?(:all_eager_load_paths) && config.all_eager_load_paths) || config.eager_load_paths
      end
    end
  end
end
