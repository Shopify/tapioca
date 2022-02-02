# typed: strict
# frozen_string_literal: true

module Tapioca
  module Compilers
    module Gem
      module Listeners
        class SorbetRequiredAncestors < Base
          extend T::Sig

          private

          sig { override.params(event: ScopeNodeAdded).void }
          def on_scope(event)
            ancestors = Trackers::RequiredAncestor.required_ancestors_by(event.constant)
            ancestors.each do |ancestor|
              next unless ancestor # TODO: We should have a way to warn from here
              event.node << RBI::RequiresAncestor.new(ancestor.to_s)
            end
          end
        end
      end
    end
  end
end
