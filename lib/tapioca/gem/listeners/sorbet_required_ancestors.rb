# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SorbetRequiredAncestors < Base
        extend T::Sig

        private

        # @override
        #: (ScopeNodeAdded event) -> void
        def on_scope(event)
          ancestors = Runtime::Trackers::RequiredAncestor.required_ancestors_by(event.constant)
          ancestors.each do |ancestor|
            unless ancestor
              # Emit a lightweight warning without crashing the pipeline
              @pipeline.error_handler.call(
                "Missing required ancestor information for #{event.constant}. " \
                "This may indicate an incomplete runtime tracker state."
              )
              next
            end

            event.node << RBI::RequiresAncestor.new(ancestor.to_s)
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
