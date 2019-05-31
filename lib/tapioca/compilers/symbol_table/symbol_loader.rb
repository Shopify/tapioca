# frozen_string_literal: true
# typed: true

require 'json'
require 'pathname'
require 'tempfile'
require 'shellwords'

module Tapioca
  module Compilers
    module SymbolTable
      module SymbolLoader
        extend(T::Sig)
        T::Hooks.install(self)

        SORBET = T.let(Gem.bin_path("sorbet", "srb"), String)

        class << self
          extend(T::Sig)

          sig { params(paths: T::Array[Pathname]).returns(T::Set[String]) }
          def list_from_paths(paths)
            load_symbols(paths.map(&:to_s))
          end

          def ignore_symbol?(symbol)
            ignored_symbols.include?(symbol)
          end

          private

          sig { params(paths: T.any(String, T::Array[String])).returns(T::Set[String]) }
          def load_symbols(paths)
            output = T.cast(Tempfile.create('sorbet') do |file|
              file.write(Array(paths).join("\n"))
              file.flush

              symbol_table_from("@#{file.path}")
            end, T.nilable(String))

            return Set.new if output.nil? || output.empty?

            parser = SymbolTableParser.new(output)
            parser.symbols
          end

          def ignored_symbols
            unless @ignored_symbols
              output = symbol_table_from("''", table_type: "symbol-table-full")
              parser = SymbolTableParser.new(output)
              @ignored_symbols = parser.symbols
            end

            @ignored_symbols
          end

          def symbol_table_from(input, table_type: "symbol-table")
            IO.popen(
              [
                SORBET,
                "tc",
                "--print=#{table_type}",
                "--quiet",
                input,
              ].shelljoin,
              err: "/dev/null"
            ).read
          end
        end

        class SymbolTableParser
          attr_accessor :symbols

          def initialize(symbol_table)
            @symbols = Set.new
            parse_symbol_table(symbol_table)
          end

          def parse_symbol_table(symbol_table_str)
            symbol_table_str.each_line do |line|
              next if line.strip!.empty?

              kind, name = line.split(" ")

              next if kind.nil? || name.nil?
              name = name.sub(/^::/, "").sub(/\[.*$/, "")

              next unless %w[class static-field].include?(kind)
              next if name =~ /[<>()$]/
              next if name =~ /^[0-9]+$/
              next if name == "T::Helpers"

              symbols.add(name)
            end
          end
        end
      end
    end
  end
end
