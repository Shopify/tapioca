# typed: false
# frozen_string_literal: true

require "tapioca/internal"

module RubyLsp
  module Tapioca
    class ServerAddon < ::RubyLsp::Rails::ServerAddon
      def initialize(...)
        super
        @loaded_dsl = false
      end

      def name
        "Tapioca"
      end

      def execute(request, params)
        case request
        when "dsl"
          # Run DSL generation in-process for the first time to load Tapioca and speed up execution in the subsequent
          # forks
          if @loaded_dsl
            fork { dsl(params) }
          else
            @loaded_dsl = true
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
