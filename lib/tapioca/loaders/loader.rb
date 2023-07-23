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

        load_rails_application(halt_upon_load_error: halt_upon_load_error)

        gemfile.require_bundle

        require_helper(require_file)

        load_rails_engines
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
      def load_rails_engines
        return if engines.empty?

        with_rails_application do
          run_initializers

          if zeitwerk_mode?
            load_engines_in_zeitwerk_mode
          else
            load_engines_in_classic_mode
          end
        end
      end

      def run_initializers
        engines.each do |engine|
          engine.instance.initializers.tsort_each do |initializer|
            initializer.run(Rails.application)
          rescue ScriptError, StandardError
            nil
          end
        end
      end

      sig { void }
      def load_engines_in_zeitwerk_mode
        # Collect all the directories that are already managed by all existing Zeitwerk loaders.
        managed_dirs = Zeitwerk::Registry.loaders.flat_map(&:dirs).to_set
        # We use a fresh loader to load the engine directories, so that we don't interfere with
        # any of the existing loaders.
        autoloader = Zeitwerk::Loader.new

        engines.each do |engine|
          engine.config.eager_load_paths.each do |path|
            # Zeitwerk only accepts existing directories in `push_dir`.
            next unless File.directory?(path)
            # We should not add directories that are already managed by a Zeitwerk loader.
            next if managed_dirs.member?(path)

            autoloader.push_dir(path)
          end
        end

        autoloader.setup
      end

      sig { void }
      def load_engines_in_classic_mode
        # This is code adapted from `Rails::Engine#eager_load!` in
        # https://github.com/rails/rails/blob/d9e188dbab81b412f73dfb7763318d52f360af49/railties/lib/rails/engine.rb#L489-L495
        #
        # We can't use `Rails::Engine#eager_load!` directly because it will raise as soon as it encounters
        # an error, which is not what we want. We want to try to load as much as we can.
        engines.each do |engine|
          engine.config.eager_load_paths.each do |load_path|
            Dir.glob("#{load_path}/**/*.rb").sort.each do |file|
              require_dependency file
            end
          rescue ScriptError, StandardError
            nil
          end
        end
      end

      sig { returns(T::Boolean) }
      def zeitwerk_mode?
        Rails.respond_to?(:autoloaders) &&
          Rails.autoloaders.respond_to?(:zeitwerk_enabled?) &&
          Rails.autoloaders.zeitwerk_enabled?
      end

      sig { params(blk: T.proc.void).void }
      def with_rails_application(&blk)
        # Store the current Rails.application object so that we can restore it
        rails_application = T.unsafe(Rails.application)

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
      def engines
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
