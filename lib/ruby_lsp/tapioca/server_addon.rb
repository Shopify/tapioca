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
