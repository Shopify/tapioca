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

        #: (Rubydex::Graph graph) -> Set[String]
        def symbols_from_graph(graph)
          graph.declarations.filter_map do |decl|
            next unless decl.is_a?(Rubydex::Namespace) ||
              decl.is_a?(Rubydex::Constant) ||
              decl.is_a?(Rubydex::ConstantAlias) ||
              decl.is_a?(Rubydex::Todo)

            # Declarations added by `graph.resolve` only have `rubydex:built-in` definitions.
            # We exclude those unless the namespace has method or constant members defined in
            # source files, which indicates a class reopening (e.g. `class Object; def Nokogiri(); end`).
            if decl.definitions.any? && decl.definitions.all? { |defn| defn.location.uri == "rubydex:built-in" }
              next unless decl.is_a?(Rubydex::Namespace) && decl.members.any? do |m|
                (m.is_a?(Rubydex::Method) || m.is_a?(Rubydex::Constant) || m.is_a?(Rubydex::ConstantAlias)) &&
                  m.definitions.any?
              end
            end

            decl.name
          end.to_set
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
          symbols_from_graph(engine_graph)
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
          supported_values = ["symbol-table-json", "symbol-table-full-json"]
          unless supported_values.include?(table_type)
            raise NotImplementedError, <<~MSG
              Got an unsupported value for `table_type` (#{table_type.inspect}).
              The only supported values are:
                #{supported_values.map { |v| "- #{v}" }.join("\n")}

              This is because we use `--stop-after=namer` as a performance optimization. Other print formats
              may require running later stages of Sorbet's pipeline. Please adjust the `stop-after` accordingly.
            MSG
          end

          sorbet(
            "--no-config",
            "--quiet",
            "--print=#{table_type}",
            "--stop-after=namer",
            input,
          ).out
        end
      end
    end
  end
end
