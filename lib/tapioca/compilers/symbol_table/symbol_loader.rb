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
        SORBET = Pathname.new(Gem::Specification.find_by_name("sorbet-static").full_gem_path) / "libexec" / "sorbet"

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

          sig { params(paths: T::Array[String]).returns(T::Set[String]) }
          def load_symbols(paths)
            output = T.cast(Tempfile.create('sorbet') do |file|
              file.write(Array(paths).join("\n"))
              file.flush

              symbol_table_json_from("@#{file.path}")
            end, T.nilable(String))

            return Set.new if output.nil? || output.empty?

            json = JSON.parse(output)
            SymbolTableParser.parse(json)
          end

          def ignored_symbols
            unless @ignored_symbols
              output = symbol_table_json_from("''", table_type: "symbol-table-full-json")
              json = JSON.parse(output)
              @ignored_symbols = SymbolTableParser.parse(json)
            end

            @ignored_symbols
          end

          def symbol_table_json_from(input, table_type: "symbol-table-json")
            IO.popen(
              [
                SORBET,
                # We don't want to pick up any sorbet/config files in cwd
                "--no-config",
                "--print=#{table_type}",
                "--quiet",
                input,
              ].shelljoin,
              err: "/dev/null"
            ).read
          end
        end

        class SymbolTableParser
          def self.parse(object, parents = [])
            symbols = Set.new

            children = object.fetch("children", [])

            children.each do |child|
              kind = child.fetch("kind")
              name = child.fetch("name")
              name = name.fetch("name") if name.is_a?(Hash)

              next if kind.nil? || name.nil?

              next unless %w[CLASS STATIC_FIELD].include?(kind)
              next if name =~ /[<>()$]/
              next if name =~ /^[0-9]+$/
              next if name == "T::Helpers"

              parents << name

              symbols.add(parents.join("::"))
              symbols.merge(parse(child, parents))

              parents.pop
            end
            symbols
          end
        end
      end
    end
  end
end
