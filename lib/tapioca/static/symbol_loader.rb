# typed: strict
# frozen_string_literal: true

module Tapioca
  module Static
    module SymbolLoader
      class << self
        extend T::Sig
        include SorbetHelper
        include Runtime::Reflection

        sig { returns(T::Set[String]) }
        def payload_symbols
          unless @payload_symbols
            output = symbol_table_json_from("-e ''", table_type: "symbol-table-full-json")
            @payload_symbols = T.let(SymbolTableParser.parse_json(output), T.nilable(T::Set[String]))
          end

          T.must(@payload_symbols)
        end

        sig { params(gem: Gemfile::GemSpec).returns(T::Set[String]) }
        def engine_symbols(gem)
          gem_engine = engines.find do |engine|
            gem.contains_path?(engine.config.root.to_s)
          end

          return Set.new unless gem_engine

          paths = gem_engine.config.eager_load_paths.flat_map do |load_path|
            Pathname.glob("#{load_path}/**/*.rb")
          end

          symbols_from_paths(paths)
        rescue
          Set.new
        end

        sig { params(gem: Gemfile::GemSpec).returns(T::Set[String]) }
        def gem_symbols(gem)
          symbols_from_paths(gem.files)
        end

        sig { params(paths: T::Array[Pathname]).returns(T::Set[String]) }
        def symbols_from_paths(paths)
          output = Tempfile.create("sorbet") do |file|
            file.write(Array(paths).join("\n"))
            file.flush

            symbol_table_json_from("@#{file.path.shellescape}")
          end

          return Set.new if output.empty?

          SymbolTableParser.parse_json(output)
        end

        private

        sig { returns(T::Array[T.class_of(Rails::Engine)]) }
        def engines
          @engines ||= T.let(
            if Object.const_defined?("Rails::Engine")
              descendants_of(Object.const_get("Rails::Engine"))
                .reject(&:abstract_railtie?)
            else
              []
            end,
            T.nilable(T::Array[T.class_of(Rails::Engine)]),
          )
        end

        sig { params(input: String, table_type: String).returns(String) }
        def symbol_table_json_from(input, table_type: "symbol-table-json")
          sorbet("--no-config", "--quiet", "--print=#{table_type}", input).out
        end
      end
    end
  end
end
