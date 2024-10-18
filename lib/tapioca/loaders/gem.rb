# typed: strict
# frozen_string_literal: true

module Tapioca
  module Loaders
    class Gem < Loader
      extend T::Sig

      class << self
        extend T::Sig

        sig do
          params(
            bundle: Gemfile,
            prerequire: T.nilable(String),
            postrequire: String,
            default_command: String,
            halt_upon_load_error: T::Boolean,
          ).void
        end
        def load_application(bundle:, prerequire:, postrequire:, default_command:, halt_upon_load_error:)
          loader = new(
            bundle: bundle,
            prerequire: prerequire,
            postrequire: postrequire,
            default_command: default_command,
            halt_upon_load_error: halt_upon_load_error,
          )
          loader.load
        end
      end

      sig { override.void }
      def load
        require_gem_file
      end

      protected

      sig do
        params(
          bundle: Gemfile,
          prerequire: T.nilable(String),
          postrequire: String,
          default_command: String,
          halt_upon_load_error: T::Boolean,
        ).void
      end
      def initialize(bundle:, prerequire:, postrequire:, default_command:, halt_upon_load_error:)
        super()

        @bundle = bundle
        @prerequire = prerequire
        @postrequire = postrequire
        @default_command = default_command
        @halt_upon_load_error = halt_upon_load_error
      end

      sig { void }
      def require_gem_file
        logger.info("Requiring all gems to prepare for compiling... ")
        begin
          load_bundle(@bundle, @prerequire, @postrequire, @halt_upon_load_error)
        rescue LoadError => e
          explain_failed_require(@postrequire, e)
          exit(1)
        end

        Runtime::Trackers::Autoload.eager_load_all!

        logger.info(" Done", :green)
        unless @bundle.missing_specs.empty?
          logger.info("  completed with missing specs: ")
          logger.info(@bundle.missing_specs.join(", "), :yellow)
        end
        puts
      end

      sig { params(file: String, error: LoadError).void }
      def explain_failed_require(file, error)
        logger.error("\n\nLoadError: #{error}", :bold, :red)
        logger.error(
          "\nTapioca could not load all the gems required by your application.",
          :yellow,
        )
        logger.error("If you populated ", :yellow)
        logger.error("#{file} ", :bold, :blue)
        logger.error("with ", :yellow)
        logger.error("`#{@default_command}`", :bold, :blue)
        logger.error("you should probably review it and remove the faulty line.", :yellow)
      end
    end
  end
end
