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

        # Builds a Rubydex graph from `paths` (regular Ruby/RBS source files)
        # and optional `rbi_files` (Sorbet RBI stubs shipped alongside the
        # gem in `rbi/`). Rubydex's `index_all` ignores `.rbi` extensions,
        # so we feed those files through `index_source` after retitling
        # their URIs to a `.rb` extension — RBI is plain Ruby, so the
        # indexer is happy with the content once it can see it.
        #
        # The graph also indexes the latest installed `rbs` gem's core
        # and stdlib RBS definitions so that bare references like
        # `Integer` or `String` resolve.
        #: (Array[Pathname] paths, ?rbi_files: Array[Pathname]) -> Rubydex::Graph
        def graph_from_paths(paths, rbi_files: [])
          graph = Rubydex::Graph.new
          paths_to_index = paths.map(&:to_s)
          # Include core/stdlib RBS so that references like `Integer`, `String`,
          # etc. resolve when we fully-qualify types extracted from inline RBS
          # signatures.
          paths_to_index.concat(core_rbs_definition_paths)
          graph.index_all(paths_to_index)

          rbi_files.each do |rbi_path|
            content = begin
              rbi_path.read(encoding: "UTF-8")
            rescue Errno::ENOENT, Errno::EACCES
              next
            end
            # Pretend the file has a `.rb` extension so Rubydex's source
            # registration doesn't reject it; the underlying syntax is plain
            # Ruby.
            uri = "file://#{rbi_path}.rb"
            graph.index_source(uri, content, "ruby")
          end

          graph.resolve
          graph
        end

        # Returns the filesystem paths to the latest installation of the
        # `rbs` gem's `core` and `stdlib` RBS definition directories, or an
        # empty list if no such installation exists. Used to seed the Rubydex
        # graph so it can resolve references to builtin constants such as
        # `Integer`, `String`, etc.
        #: -> Array[String]
        def core_rbs_definition_paths
          rbs_gem_path = ::Gem.path
            .flat_map { |path| Dir.glob(File.join(path, "gems", "rbs-[0-9]*/")) }
            .max_by { |path| ::Gem::Version.new(File.basename(path).delete_prefix("rbs-")) }

          return [] unless rbs_gem_path

          [
            File.join(rbs_gem_path, "core"),
            File.join(rbs_gem_path, "stdlib"),
          ]
        end

        #: (Gemfile::GemSpec gem) -> Set[String]
        def gem_symbols(gem)
          symbols_from_paths(gem.files)
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

          symbols_from_paths(paths)
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
