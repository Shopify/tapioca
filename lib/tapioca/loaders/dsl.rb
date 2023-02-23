# typed: strict
# frozen_string_literal: true

module Tapioca
  module Loaders
    class Dsl < Loader
      extend T::Sig

      class << self
        extend T::Sig

        sig { params(tapioca_path: String, eager_load: T::Boolean, app_root: String).void }
        def load_application(tapioca_path:, eager_load: true, app_root: ".")
          loader = new(tapioca_path: tapioca_path, eager_load: eager_load, app_root: app_root)
          loader.load
        end
      end

      sig { override.void }
      def load
        load_dsl_extensions
        load_application
        abort_if_pending_migrations!
        load_dsl_compilers
      end

      protected

      sig { params(tapioca_path: String, eager_load: T::Boolean, app_root: String).void }
      def initialize(tapioca_path:, eager_load: true, app_root: ".")
        super()

        @tapioca_path = tapioca_path
        @eager_load = eager_load
        @app_root = app_root
      end

      sig { void }
      def load_dsl_extensions
        Dir["#{__dir__}/../dsl/extensions/*.rb"].sort.each { |f| require(f) }
      end

      sig { void }
      def load_dsl_compilers
        say("Loading DSL compiler classes... ")

        Dir.glob([
          "#{@tapioca_path}/generators/**/*.rb", # TODO: Here for backcompat, remove later
          "#{@tapioca_path}/compilers/**/*.rb",
        ]).each do |compiler|
          require File.expand_path(compiler)
        end

        ::Gem.find_files("tapioca/dsl/compilers/*.rb").each do |compiler|
          require File.expand_path(compiler)
        end

        say("Done", :green)
      end

      sig { void }
      def load_application
        say("Loading Rails application... ")

        load_rails_application(
          environment_load: true,
          eager_load: @eager_load,
          app_root: @app_root,
        )

        say("Done", :green)
      end

      sig { void }
      def abort_if_pending_migrations!
        return unless File.exist?("#{@app_root}/config/application.rb")
        return unless defined?(::Rake)

        Rails.application.load_tasks
        if Rake::Task.task_defined?("db:abort_if_pending_migrations")
          Rake::Task["db:abort_if_pending_migrations"].invoke
        end
      end
    end
  end
end
