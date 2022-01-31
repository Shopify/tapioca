# typed: true
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
            load_symbols(paths.map(&:to_s))
          end

          def ignore_symbol?(symbol)
            symbol = symbol[2..-1] if symbol.start_with?("::")
            ignored_symbols.include?(symbol)
          end

          private

          sig { params(paths: T::Array[String]).returns(T::Set[String]) }
          def load_symbols(paths)
            output = T.cast(Tempfile.create("sorbet") do |file|
              file.write(Array(paths).join("\n"))
              file.flush

              symbol_table_json_from("@#{file.path.shellescape}")
            end, T.nilable(String))

            return Set.new if output.nil? || output.empty?

            SymbolTableParser.parse_json(output)
          end

          def ignored_symbols
            unless @ignored_symbols
              output = symbol_table_json_from("-e ''", table_type: "symbol-table-full-json")
              @ignored_symbols = SymbolTableParser.parse_json(output)
            end

            @ignored_symbols
          end

          def symbol_table_json_from(input, table_type: "symbol-table-json")
            sorbet("--no-config", "--print=#{table_type}", input)
          end
        end
      end
    end
  end
end
