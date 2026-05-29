# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SorbetHelpers < Base
        include Runtime::Reflection

        private

        # @override
        #: (ScopeNodeAdded event) -> void
        def on_scope(event)
          constant = event.constant
          node = event.node

          # Sorbet-runtime tracked helpers (set via `abstract!`, `final!`,
          # `sealed!`).
          abstract_type = abstract_type_of(constant)
          node << RBI::Helper.new(abstract_type.to_s) if abstract_type
          node << RBI::Helper.new("final") if final_module?(constant)
          node << RBI::Helper.new("sealed") if sealed_module?(constant)

          # Inline RBS `# @abstract`, `# @interface`, `# @sealed`, `# @final`
          # annotations. Without the require-hook rewriter we don't get the
          # runtime tracking above for these, so we synthesize the helpers
          # straight from source.
          add_rbs_helpers(event)
        end

        #: (ScopeNodeAdded event) -> void
        def add_rbs_helpers(event)
          rbs_comments = @pipeline.rbs_comments_for_constant(event.constant)
          return unless rbs_comments

          existing = event.node.nodes.grep(RBI::Helper).map(&:name).to_set

          rbs_comments.class_annotations.each do |annotation|
            helper_name = case annotation.string
            when "@abstract"
              "abstract"
            when "@interface"
              "interface"
            when "@sealed"
              "sealed"
            when "@final"
              "final"
            end
            next unless helper_name
            next if existing.include?(helper_name)

            event.node << RBI::Helper.new(helper_name)
            existing << helper_name
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
