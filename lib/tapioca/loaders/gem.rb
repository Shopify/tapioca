# typed: strict
# frozen_string_literal: true

module Tapioca
  module Loaders
    class Gem < Loader
      extend T::Sig

      class << self
        extend T::Sig

        #: (bundle: Gemfile, prerequire: String?, postrequire: String, default_command: String, halt_upon_load_error: bool) -> void
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

      # @override
      #: -> void
      def load
        require_gem_file
      end

      protected

      #: (bundle: Gemfile, prerequire: String?, postrequire: String, default_command: String, halt_upon_load_error: bool) -> void
      def initialize(bundle:, prerequire:, postrequire:, default_command:, halt_upon_load_error:)
        super()

        @bundle = bundle
        @prerequire = prerequire
        @postrequire = postrequire
        @default_command = default_command
        @halt_upon_load_error = halt_upon_load_error
      end

      #: -> void
      def require_gem_file
        say("Requiring all gems to prepare for compiling... ")
        begin
          load_bundle(@bundle, @prerequire, @postrequire, @halt_upon_load_error)
        rescue LoadError => e
          explain_failed_require(@postrequire, e)
          exit(1)
        end

        Runtime::Trackers::Autoload.eager_load_all!

        say(" Done", :green)
        unless @bundle.missing_specs.empty?
          say("  completed with missing specs: ")
          say(@bundle.missing_specs.join(", "), :yellow)
        end
        puts
      end

      #: (String file, LoadError error) -> void
      def explain_failed_require(file, error)
        say_error("\n\nLoadError: #{error}", :bold, :red)
        say_error("\nTapioca could not load all the gems required by your application.", :yellow)
        say_error("If you populated ", :yellow)
        say_error("#{file} ", :bold, :blue)
        say_error("with ", :yellow)
        say_error("`#{@default_command}`", :bold, :blue)
        say_error("you should probably review it and remove the faulty line.", :yellow)
      end
    end
  end
end
