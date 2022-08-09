# typed: strict
# frozen_string_literal: true

module Tapioca
  module Loaders
    class Dsl < Loader
      extend T::Sig

      sig { params(tapioca_path: String, eager_load: T::Boolean).void }
      def self.load_application(tapioca_path:, eager_load: true)
        loader = new(tapioca_path: tapioca_path)
        loader.load
      end

      sig { override.void }
      def load
        load_dsl_extensions
        load_application
        abort_if_pending_migrations!
        load_dsl_compilers
      end

      protected

      sig { params(tapioca_path: String, eager_load: T::Boolean).void }
      def initialize(tapioca_path:, eager_load: true)
        super()

        @tapioca_path = tapioca_path
        @eager_load = eager_load
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
          eager_load: @eager_load
        )

        say("Done", :green)
      end

      sig { void }
      def abort_if_pending_migrations!
        return unless File.exist?("config/application.rb")
        return unless defined?(::Rake)

        Rails.application.load_tasks
        if Rake::Task.task_defined?("db:abort_if_pending_migrations")
          Rake::Task["db:abort_if_pending_migrations"].invoke
        end
      end
    end
  end
end
