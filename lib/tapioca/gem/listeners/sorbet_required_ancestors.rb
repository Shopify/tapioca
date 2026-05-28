# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SorbetRequiredAncestors < Base
        private

        # @override
        #: (ScopeNodeAdded event) -> void
        def on_scope(event)
          # Sorbet-runtime tracked ancestors (set via `requires_ancestor {}`).
          ancestors = Runtime::Trackers::RequiredAncestor.required_ancestors_by(event.constant)
          ancestors.each do |ancestor|
            next unless ancestor # TODO: We should have a way to warn from here

            event.node << RBI::RequiresAncestor.new(ancestor.to_s)
          end

          # Inline RBS `# @requires_ancestor: Type` annotations — these are
          # picked up from source so we don't need the require-hook rewriter
          # to translate them into `requires_ancestor {}` calls at load time.
          add_rbs_required_ancestors(event)
        end

        #: (ScopeNodeAdded event) -> void
        def add_rbs_required_ancestors(event)
          rbs_comments = @pipeline.rbs_comments_for_constant(event.constant)
          return unless rbs_comments

          qualifier = Tapioca::RBS::TypeQualifier.new(
            @pipeline.gem_graph,
            event.symbol.delete_prefix("::").split("::").reject(&:empty?),
          )

          rbs_comments.class_annotations.each do |annotation|
            string = annotation.string
            next unless string.start_with?("@requires_ancestor:")

            type_string = string.delete_prefix("@requires_ancestor:").strip

            begin
              srb_type = ::RBS::Parser.parse_type(type_string)
              rbi_type = ::RBI::RBS::TypeTranslator.translate(srb_type)
            rescue ::RBS::ParsingError, ::RBI::Error
              next
            end

            event.node << RBI::RequiresAncestor.new(qualifier.visit(rbi_type))
          end
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
