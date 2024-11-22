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
          dsl(params)
        end
      end

      private

      def dsl(params)
      end
    end
  end
end
