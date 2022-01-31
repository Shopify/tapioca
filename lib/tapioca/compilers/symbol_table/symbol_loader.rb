# typed: strict
# frozen_string_literal: true

require "json"
require "tempfile"

module Tapioca
  module Compilers
    module SymbolTable
      module SymbolLoader
        class << self
          extend T::Sig
          include SorbetHelper

          sig { params(paths: T::Array[Pathname]).returns(T::Set[String]) }
          def list_from_paths(paths)
            output = T.cast(Tempfile.create("sorbet") do |file|
              file.write(Array(paths).join("\n"))
              file.flush

              symbol_table_json_from("@#{file.path.shellescape}")
            end, T.nilable(String))

            return Set.new if output.nil? || output.empty?

            SymbolTableParser.parse_json(output)
          end

          sig { returns(T::Set[String]) }
          def payload_symbols
            unless @payload_symbols
              output = symbol_table_json_from("-e ''", table_type: "symbol-table-full-json")
              @payload_symbols = T.let(SymbolTableParser.parse_json(output), T.nilable(T::Set[String]))
            end

            T.must(@payload_symbols)
          end

          private

          sig { params(input: String, table_type: String).returns(String) }
          def symbol_table_json_from(input, table_type: "symbol-table-json")
            sorbet("--no-config", "--print=#{table_type}", input)
          end
        end
      end
    end
  end
end
