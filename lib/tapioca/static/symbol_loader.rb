# typed: strict
# frozen_string_literal: true

module Tapioca
  module Static
    module SymbolLoader
      class << self
        extend T::Sig
        include SorbetHelper
        include Runtime::Reflection

        #: -> Set[String]
        def payload_symbols
          unless @payload_symbols
            output = symbol_table_json_from("-e ''", table_type: "symbol-table-full-json")
            @payload_symbols = SymbolTableParser.parse_json(output) #: Set[String]?
          end

          T.must(@payload_symbols)
        end

        # @without_runtime
        #: -> Array[singleton(Rails::Engine)]
        def engines
          @engines ||= if Object.const_defined?("Rails::Engine")
            descendants_of(Object.const_get("Rails::Engine"))
              .reject(&:abstract_railtie?)
          else
            []
          end #: Array[singleton(Rails::Engine)]?
        end

        private

        #: (String input, ?table_type: String) -> String
        def symbol_table_json_from(input, table_type: "symbol-table-json")
          sorbet("--no-config", "--quiet", "--print=#{table_type}", input).out
        end
      end
    end
  end
end
