# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class Documentation < Base
        IGNORED_COMMENTS = [
          ":doc:",
          ":nodoc:",
          "typed:",
          "frozen_string_literal:",
          "encoding:",
          "warn_indent:",
          "shareable_constant_value:",
          "rubocop:",
          "@requires_ancestor:",
        ] #: Array[String]

        #: (Pipeline pipeline, Rubydex::Graph gem_graph) -> void
        def initialize(pipeline, gem_graph)
          super(pipeline)

          @gem_graph = gem_graph
        end

        private

        #: (String line) -> bool
        def rbs_comment?(line)
          line.start_with?(": ", "| ")
        end

        # @override
        #: (ConstNodeAdded event) -> void
        def on_const(event)
          event.node.comments = documentation_comments(event.symbol)
        end

        # @override
        #: (ScopeNodeAdded event) -> void
        def on_scope(event)
          event.node.comments = documentation_comments(event.symbol)
        end

        # @override
        #: (MethodNodeAdded event) -> void
        def on_method(event)
          name = if event.constant.singleton_class?
            "#{event.symbol}::<#{event.symbol.split("::").last}>##{event.node.name}()"
          else
            "#{event.symbol}##{event.node.name}()"
          end
          event.node.comments = documentation_comments(name, sigs: event.node.sigs)
        end

        #: (String name, ?sigs: Array[RBI::Sig]) -> Array[RBI::Comment]
        def documentation_comments(name, sigs: [])
          declaration = @gem_graph[name]
          # For attr_writer methods (name ending in =), fall back to reader docs
          if declaration.nil? && name.end_with?("=()")
            declaration = @gem_graph[name.delete_suffix("=()") + "()"]
          end
          # For singleton methods (Class::<Class>#method()), fall back to instance method docs.
          # This handles module_function and extend self methods which Rubydex indexes
          # only under the instance method name.
          if declaration.nil? && name.include?("::<")
            declaration = @gem_graph[name.sub(/::<[^>]+>#/, "#")]
          end
          return [] unless declaration

          # Use comments from the first definition that has comments to avoid duplicates
          # when a method is defined in multiple places with identical documentation.
          comments = declaration.definitions.lazy.map(&:comments).find { |c| c.to_a.any? }
          return [] unless comments

          lines = comments
            .map { |comment| comment.string.gsub(/^#+ ?/, "") }
            .reject { |line| IGNORED_COMMENTS.any? { |comment| line.include?(comment) } || rbs_comment?(line) }

          # Strip leading and trailing blank lines, matching YARD's behavior
          lines = lines.drop_while(&:empty?).reverse.drop_while(&:empty?).reverse

          lines.map! { |line| RBI::Comment.new(line) }
        end

        # @override
        #: (NodeAdded event) -> bool
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end
