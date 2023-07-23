# typed: strict
# frozen_string_literal: true

module Tapioca
  module Loaders
    class Dsl < Loader
      extend T::Sig

      class << self
        extend T::Sig

        sig do
          params(tapioca_path: String, eager_load: T::Boolean, app_root: String, halt_upon_load_error: T::Boolean).void
        end
        def load_application(tapioca_path:, eager_load: true, app_root: ".", halt_upon_load_error: true)
          loader = new(
            tapioca_path: tapioca_path,
            eager_load: eager_load,
            app_root: app_root,
            halt_upon_load_error: halt_upon_load_error,
          )
          loader.load
        end
      end

      sig { override.void }
      def load
        load_dsl_extensions
        load_application
        load_dsl_compilers
      end

      protected

      sig do
        params(tapioca_path: String, eager_load: T::Boolean, app_root: String, halt_upon_load_error: T::Boolean).void
      end
      def initialize(tapioca_path:, eager_load: true, app_root: ".", halt_upon_load_error: true)
        super()

        @tapioca_path = tapioca_path
        @eager_load = eager_load
        @app_root = app_root
        @halt_upon_load_error = halt_upon_load_error
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
          halt_upon_load_error: @halt_upon_load_error,
        )

        say("Done", :green)
      end
    end
  end
end
