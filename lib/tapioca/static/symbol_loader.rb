# typed: strict
# frozen_string_literal: true

module Tapioca
  module Static
    module SymbolLoader
      class << self
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

        #: (Array[Pathname] paths) -> Rubydex::Graph
        def graph_from_paths(paths)
          graph = Rubydex::Graph.new
          graph.index_all(paths.map(&:to_s))
          graph.resolve
          graph
        end

        #: (Gemfile::GemSpec gem) -> Set[String]
        def engine_symbols(gem)
          gem_engine = engines.find do |engine|
            gem.full_gem_path == engine.config.root.to_s
          end

          return Set.new unless gem_engine

          # https://github.com/rails/rails/commit/ebfca905db14020589c22e6937382e6f8f687664
          config = gem_engine.config
          eager_load_paths = if config.respond_to?(:all_eager_load_paths)
            config.all_eager_load_paths
          else
            config.eager_load_paths
          end

          paths = eager_load_paths.flat_map do |load_path|
            Pathname.glob("#{load_path}/**/*.rb")
          end

          engine_graph = graph_from_paths(paths)
          engine_graph.declarations.map(&:name).to_set
        rescue
          Set.new
        end

        #: (Array[Pathname] paths) -> Set[String]
        def symbols_from_paths(paths)
          return Set.new if paths.empty?

          output = Tempfile.create("sorbet") do |file|
            file.write(Array(paths).join("\n"))
            file.flush

            symbol_table_json_from("@#{file.path.shellescape}")
          end

          return Set.new if output.empty?

          SymbolTableParser.parse_json(output)
        end

        private

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

        #: (String input, ?table_type: String) -> String
        def symbol_table_json_from(input, table_type: "symbol-table-json")
          sorbet("--no-config", "--quiet", "--print=#{table_type}", input).out
        end
      end
    end
  end
end
