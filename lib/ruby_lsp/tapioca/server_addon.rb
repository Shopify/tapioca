# typed: false
# frozen_string_literal: true

require "tapioca/internal"

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
          fork do
            dsl(params)
          end
        end
      end

      private

      def dsl(params)
        load("tapioca/cli.rb") # Reload the CLI to reset thor defaults between requests
        ::Tapioca::Cli.start(["dsl", "--lsp_addon", "--workers=1"] + params[:constants])
      end
    end
  end
end
