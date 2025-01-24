# typed: false
# frozen_string_literal: true

require "tapioca/internal"
require "tapioca/dsl/compilers/url_helpers"

module RubyLsp
  module Tapioca
    class ServerAddon < ::RubyLsp::Rails::ServerAddon
      def name
        "Tapioca"
      end

      def execute(request, params)
        case request
        when "load_compilers_and_extensions"
          # Load DSL extensions and compilers ahead of time, so that we don't have to pay the price of invoking
          # `Gem.find_files` on every execution, which is quite expensive
          ::Tapioca::Loaders::Dsl.new(
            tapioca_path: ::Tapioca::TAPIOCA_DIR,
            eager_load: false,
            app_root: params[:workspace_path],
            halt_upon_load_error: false,
          ).load_dsl_extensions_and_compilers
        when "dsl"
          fork { dsl(params[:constants]) }
        when "route_dsl"
          fork do
            constants = ::Tapioca::Dsl::Compilers::UrlHelpers.gather_constants
            dsl(constants.map(&:name), "--only=Tapioca::Dsl::Compilers::UrlHelpers", "ActiveSupportConcern")
          end
        end
      end

      private

      def dsl(constants, *args)
        load("tapioca/cli.rb") # Reload the CLI to reset thor defaults between requests

        # Order here is important to avoid having Thor confuse arguments. Do not put an array argument at the end before
        # the list of constants
        arguments = ["dsl"]
        arguments.concat(args)
        arguments.push("--lsp_addon", "--workers=1")
        arguments.concat(constants)

        ::Tapioca::Cli.start(arguments)
      end
    end
  end
end
