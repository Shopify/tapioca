# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBS
    # Resolves inline RBS signatures for runtime methods encountered during a
    # `tapioca dsl` run.
    #
    # The DSL command doesn't compile a specific gem — it inspects whichever
    # constants the user's app exposes — so we build a Rubydex graph of the
    # entire host workspace (plus core/stdlib RBS) and consult it whenever a
    # DSL compiler asks for the signature of a method that has no Sorbet
    # runtime sig. This mirrors what the `gem` pipeline does on a per-gem
    # graph and lets DSL compilers see RBS-only sigs without relying on the
    # require-hook rewriter.
    module DslSignatures
      class << self
        # Returns the {RBI::Sig} extracted from inline RBS comments next to
        # `method_def`'s source declaration, fully qualified through the
        # host-app graph. Returns nil when no RBS info is available or the
        # signature can't be parsed.
        #: ((Method | UnboundMethod) method_def) -> RBI::Sig?
        def build(method_def)
          location = method_def.source_location
          return unless location

          file, line = location
          declaration, kind = find_declaration(method_def, file, line)
          return unless declaration

          definition = pick_definition(declaration, file, line)
          return unless definition

          parsed = parse_rbs_comments(definition)
          return if parsed.signatures.empty?

          # When the source carries multiple `#: ... -> ...` overload lines,
          # Sorbet's runtime can only attach one signature to a given method
          # anyway, so we pick the last overload — same convention the
          # spoom-based rewriter used.
          signature_string = parsed.signatures.last&.string #: as !nil

          rbi_method = build_rbi_method(method_def)
          sig = case kind
          when :attr_reader, :attr_accessor
            build_attr_sig(signature_string, attr_name_from(method_def), writer: false)
          when :attr_writer
            build_attr_sig(signature_string, attr_name_from(method_def), writer: true)
          else
            build_method_sig(signature_string, rbi_method)
          end
          return unless sig

          qualifier = TypeQualifier.new(graph, nesting_for(method_def))
          qualify_sig!(sig, qualifier)
          sig
        rescue ::RBS::ParsingError, ::RBI::Error
          nil
        end

        # The Rubydex graph used to look up declarations and resolve
        # constants. Built lazily on first access and shared per process.
        # Parallel DSL workers (forked by `Parallel.map`) get their own copy
        # the first time a compiler asks for a sig — the graph is not
        # Marshal-friendly (Rust-backed) so we can't share across the fork
        # boundary cleanly.
        # Returns the per-process Rubydex graph used to look up declarations
        # and resolve constants. Built lazily on first access. On every call
        # we also incrementally index any new `$LOADED_FEATURES` entries we
        # haven't seen yet — this matters for test suites that `require`
        # fresh fixture files between tests, where the cached graph would
        # otherwise miss the new source.
        #
        # Parallel DSL workers (forked by `Parallel.map`) get their own copy
        # the first time a compiler asks for a sig — the graph is not
        # Marshal-friendly (Rust-backed) so we can't share across the fork
        # boundary cleanly.
        #: -> Rubydex::Graph
        def graph
          if @graph
            refresh_graph(@graph)
            @graph
          else
            @graph = build_graph #: Rubydex::Graph?
          end
        end

        # Drops the cached graph. Test-only escape hatch.
        #: -> void
        def reset!
          @graph = nil
          @indexed_paths = nil
        end

        private

        #: -> Rubydex::Graph
        def build_graph
          paths = workspace_source_paths
          graph = Rubydex::Graph.new
          graph.index_all(paths)
          graph.resolve
          @indexed_paths = Set.new(paths) #: Set[String]?
          graph
        end

        # Indexes any new `$LOADED_FEATURES` files that have appeared since
        # the graph was last built/refreshed. No-ops when there's nothing
        # new.
        #: (Rubydex::Graph graph) -> void
        def refresh_graph(graph)
          indexed = (@indexed_paths ||= Set.new) #: Set[String]
          new_paths = extra_loaded_features.reject { |p| indexed.include?(p) }
          return if new_paths.empty?

          graph.index_all(new_paths)
          graph.resolve
          indexed.merge(new_paths)
        end

        # Source paths to index for the host app: the user's own code under
        # `Dir.pwd` (excluding common artifact directories like `.git`,
        # `tmp`, `node_modules`, `vendor`, etc.), every `.rb` file already
        # loaded into the process via `$LOADED_FEATURES` (so we cover code
        # loaded from temp dirs, scripts outside `Dir.pwd`, etc.), and the
        # latest installed core/stdlib RBS so basic constant resolution
        # still works.
        #
        # We deliberately skip Bundler-managed dependencies that live under
        # `Gem.path`, because indexing every gem has been seen to make
        # Rubydex's resolver panic on Rails apps and there's nothing we'd
        # do with the resolved declarations anyway — we only need to
        # resolve constants the user references from their own inline RBS
        # sigs.
        #: -> Array[String]
        def workspace_source_paths
          paths = workspace_top_level_paths
          paths.concat(extra_loaded_features)
          paths.concat(Static::SymbolLoader.core_rbs_definition_paths)
          paths.uniq!
          paths
        rescue StandardError
          # Last-ditch fallback if anything blows up while probing — at
          # least we still get core RBS resolution.
          Static::SymbolLoader.core_rbs_definition_paths.dup
        end

        # Walk `Dir.pwd`'s top level, returning the subdirectories and
        # top-level `.rb` files that should feed the graph.
        #: -> Array[String]
        def workspace_top_level_paths
          workspace = begin
            Dir.pwd
          rescue StandardError
            "."
          end

          paths = []
          Dir.each_child(workspace) do |entry|
            next if IGNORED_WORKSPACE_DIRS.include?(entry)

            full_path = File.join(workspace, entry)
            if File.directory?(full_path)
              paths << full_path
            elsif File.extname(entry) == ".rb"
              paths << full_path
            end
          end
          paths
        end

        # Returns the absolute paths of every Ruby source file already
        # loaded into the process that lives *outside* the workspace,
        # gem path, and any Ruby runtime/standard library directory we can
        # detect. This captures host-app code that lives in unusual places
        # (most notably the `tmp_path` directories used by the spec suite)
        # without dragging every gem into the graph.
        #: -> Array[String]
        def extra_loaded_features
          workspace_prefix = begin
            "#{Dir.pwd}/"
          rescue StandardError
            nil
          end
          gem_prefixes = ::Gem.path.map { |p| "#{p}/" }
          ruby_lib_prefix = "#{RbConfig::CONFIG["rubylibdir"]}/"
          site_dir_prefix = "#{RbConfig::CONFIG["sitelibdir"]}/" if RbConfig::CONFIG["sitelibdir"]

          $LOADED_FEATURES.select do |feature|
            next false unless feature.end_with?(".rb")
            next false unless File.absolute_path?(feature)
            next false if workspace_prefix && feature.start_with?(workspace_prefix)
            next false if gem_prefixes.any? { |gp| feature.start_with?(gp) }
            next false if feature.start_with?(ruby_lib_prefix)
            next false if site_dir_prefix && feature.start_with?(site_dir_prefix)

            true
          end
        end

        IGNORED_WORKSPACE_DIRS = [
          ".bundle",
          ".git",
          ".github",
          ".ruby-lsp",
          ".vscode",
          "log",
          "node_modules",
          "sorbet",
          "tmp",
          "vendor",
        ].freeze #: Array[String]
        private_constant :IGNORED_WORKSPACE_DIRS

        # Finds the Rubydex declaration that owns `method_def`. Tries
        # several lookup shapes in order, falling back to a file/line scan
        # when the owner has no name (anonymous classes built with
        # `Class.new`).
        #
        # The `line` argument is the 1-indexed runtime
        # `method.source_location` line, used to disambiguate between
        # multiple declarations with the same name (e.g. when a spec file
        # creates anonymous classes in each test block).
        #: ((Method | UnboundMethod) method_def, String file, Integer line) -> [Rubydex::Declaration, Symbol]?
        def find_declaration(method_def, file, line)
          owner = method_def.owner
          owner_name = Runtime::Reflection.name_of(owner)
          method_name = method_def.name.to_s

          if owner_name
            # Singleton methods live on the singleton class; we surface them
            # under their attached class with the `<Foo>` marker Rubydex uses.
            result = lookup_singleton_declaration(owner, method_name) if owner.singleton_class?
            return result if result

            lookup_name = method_name.delete_suffix("=")
            qualified = "#{owner_name}##{lookup_name}()"
            result = lookup_with_kind(qualified)
            return result if result
          end

          # Owner has no name (anonymous class) or qualified lookup failed.
          # Fall back to scanning the file for a method declaration with the
          # right name and a definition closest to `line`.
          find_declaration_by_location(method_def, file, line)
        end

        # Scans the graph for a method declaration whose name matches,
        # which has a definition in `file`, and whose definition line is
        # the closest match to `line` (1-indexed runtime source location).
        # Used when the owner is anonymous and can't be looked up by
        # qualified name.
        #: ((Method | UnboundMethod) method_def, String file, Integer line) -> [Rubydex::Declaration, Symbol]?
        def find_declaration_by_location(method_def, file, line)
          method_name = method_def.name.to_s
          lookup_name = method_name.delete_suffix("=")
          target_line = line - 1 # Rubydex is 0-indexed
          realpath = begin
            Pathname.new(file).realpath.to_s
          rescue Errno::ENOENT
            file
          end

          best_declaration = nil #: Rubydex::Declaration?
          best_distance = nil #: Integer?

          graph.declarations.each do |declaration|
            next unless declaration.is_a?(Rubydex::Method)
            next unless declaration.unqualified_name == "#{lookup_name}()"

            declaration.definitions.each do |defn|
              path = begin
                defn.location.to_file_path
              rescue Rubydex::Location::NotFileUriError
                next
              end
              next unless path == file || path == realpath

              distance = (defn.location.start_line - target_line).abs
              if best_distance.nil? || distance < best_distance
                best_distance = distance
                best_declaration = declaration
              end
            end
          end

          return unless best_declaration

          kind = case best_declaration.definitions.first
          when Rubydex::AttrReaderDefinition then :attr_reader
          when Rubydex::AttrWriterDefinition then :attr_writer
          when Rubydex::AttrAccessorDefinition then :attr_accessor
          else :method
          end
          [best_declaration, kind]
        end

        # Looks up a singleton method declaration on `owner` (which is
        # expected to be a singleton class) by walking up to the attached
        # class and using Rubydex's `Foo::<Foo>#method()` form.
        #: (Module[top] owner, String method_name) -> [Rubydex::Declaration, Symbol]?
        def lookup_singleton_declaration(owner, method_name)
          attached = Runtime::Reflection.attached_class_of(owner)
          return unless attached

          attached_name = Runtime::Reflection.name_of(attached)
          return unless attached_name

          last_part = attached_name.split("::").last
          qualified = "#{attached_name}::<#{last_part}>##{method_name.delete_suffix("=")}()"
          lookup_with_kind(qualified)
        end

        #: (String qualified) -> [Rubydex::Declaration, Symbol]?
        def lookup_with_kind(qualified)
          declaration = graph[qualified]
          return unless declaration

          kind = declaration.definitions.first&.then do |d|
            case d
            when Rubydex::AttrReaderDefinition then :attr_reader
            when Rubydex::AttrWriterDefinition then :attr_writer
            when Rubydex::AttrAccessorDefinition then :attr_accessor
            else :method
            end
          end || :method

          [declaration, kind]
        end

        # Selects the definition matching `file` and `line` (1-indexed,
        # i.e. `method.source_location` form). Rubydex itself uses
        # 0-indexed lines, so we offset by one.
        #: (Rubydex::Declaration declaration, String file, Integer line) -> Rubydex::Definition?
        def pick_definition(declaration, file, line)
          target_line = line - 1
          realpath = begin
            Pathname.new(file).realpath.to_s
          rescue Errno::ENOENT
            file
          end

          matching = declaration.definitions.select do |d|
            path = d.location.to_file_path
            path == file || path == realpath
          rescue Rubydex::Location::NotFileUriError
            false
          end

          return matching.min_by { |d| (d.location.start_line - target_line).abs } if matching.any?

          declaration.definitions.first
        end

        #: (Rubydex::Definition definition) -> Tapioca::RBS::Comments::Parsed
        def parse_rbs_comments(definition)
          tuples = definition.comments.map do |comment|
            # Rubydex uses 0-indexed lines; we present 1-indexed lines to
            # match `Method#source_location` and downstream callers.
            [comment.string, comment.location.start_line + 1]
          end
          Tapioca::RBS::Comments.parse(tuples)
        end

        # Lexical nesting (e.g. `["Foo", "Bar"]`) of the method's owning
        # constant, used so {TypeQualifier} can resolve relative references
        # like `Bar` from inside `Foo::Bar`. Falls back to a source-based
        # scan of the file when the owner is anonymous (e.g. created with
        # `Class.new`).
        #: ((Method | UnboundMethod) method_def) -> Array[String]
        def nesting_for(method_def)
          owner = method_def.owner
          name = if owner.singleton_class?
            attached = Runtime::Reflection.attached_class_of(owner)
            attached && Runtime::Reflection.name_of(attached)
          else
            Runtime::Reflection.name_of(owner)
          end

          return name.split("::").reject(&:empty?) if name

          location = method_def.source_location
          return [] unless location

          source_nesting_for(location[0], location[1])
        end

        # Returns the lexical class/module nesting at `line` in `file`, by
        # parsing the file with Prism and recording the path of `class`
        # and `module` nodes whose source range contains `line`.
        #: (String file, Integer line) -> Array[String]
        def source_nesting_for(file, line)
          source = File.read(file, encoding: "UTF-8")
          result = Prism.parse(source)
          return [] unless result.success?

          visitor = NestingVisitor.new(line)
          visitor.visit(result.value)
          visitor.nesting
        rescue Errno::ENOENT, Errno::EACCES
          []
        end

        # Walks a Prism AST and records the chain of `class`/`module`
        # `constant_path` slices that lexically enclose `line`. Visiting is
        # short-circuited once we descend into a scope that does not
        # contain `line`.
        class NestingVisitor < Prism::Visitor
          #: Array[String]
          attr_reader :nesting

          #: (Integer line) -> void
          def initialize(line)
            super()
            @target_line = line
            @nesting = [] #: Array[String]
          end

          # @override
          #: (Prism::ClassNode node) -> void
          def visit_class_node(node)
            return unless contains_target?(node)

            @nesting.push(node.constant_path.slice)
            super
          end

          # @override
          #: (Prism::ModuleNode node) -> void
          def visit_module_node(node)
            return unless contains_target?(node)

            @nesting.push(node.constant_path.slice)
            super
          end

          private

          #: (Prism::Node node) -> bool
          def contains_target?(node)
            node.location.start_line <= @target_line &&
              @target_line <= node.location.end_line
          end
        end

        #: ((Method | UnboundMethod) method_def) -> RBI::Method
        def build_rbi_method(method_def)
          rbi = RBI::Method.new(method_def.name.to_s)
          method_def.parameters.each_with_index do |(type, name), index|
            rbi_name = name ? name.to_s : "_arg#{index}"
            case type
            when :req
              rbi << RBI::ReqParam.new(rbi_name)
            when :opt
              rbi << RBI::OptParam.new(rbi_name, "T.unsafe(nil)")
            when :rest
              rbi << RBI::RestParam.new(rbi_name)
            when :keyreq
              rbi << RBI::KwParam.new(rbi_name)
            when :key
              rbi << RBI::KwOptParam.new(rbi_name, "T.unsafe(nil)")
            when :keyrest
              rbi << RBI::KwRestParam.new(rbi_name)
            when :block
              rbi << RBI::BlockParam.new(rbi_name)
            end
          end
          rbi
        end

        #: ((Method | UnboundMethod) method_def) -> String
        def attr_name_from(method_def)
          method_def.name.to_s.delete_suffix("=")
        end

        #: (String signature_string, RBI::Method rbi_method) -> RBI::Sig?
        def build_method_sig(signature_string, rbi_method)
          method_type = ::RBS::Parser.parse_method_type(signature_string)
          ::RBI::RBS::MethodTypeTranslator.translate(rbi_method, method_type)
        end

        #: (String signature_string, String attr_name, writer: bool) -> RBI::Sig
        def build_attr_sig(signature_string, attr_name, writer:)
          attr_type = ::RBS::Parser.parse_type(signature_string)
          translated = ::RBI::RBS::TypeTranslator.translate(attr_type)

          sig = ::RBI::Sig.new
          sig.params << ::RBI::SigParam.new(attr_name, translated) if writer
          sig.return_type = translated
          sig
        end

        #: (RBI::Sig sig, TypeQualifier qualifier) -> void
        def qualify_sig!(sig, qualifier)
          new_params = sig.params.map do |param|
            type = param.type
            new_type = type.is_a?(::RBI::Type) ? qualifier.visit(type) : type.to_s
            ::RBI::SigParam.new(param.name, new_type)
          end
          sig.params.replace(new_params)

          return_type = sig.return_type
          sig.return_type = qualifier.visit(return_type) if return_type.is_a?(::RBI::Type)
        end
      end
    end
  end
end
