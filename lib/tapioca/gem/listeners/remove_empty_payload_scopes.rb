# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class RemoveEmptyPayloadScopes < RBIGenerator::Listeners::Base
        extend T::Sig

        include Runtime::Reflection

        private

        sig { override.params(event: RBIGenerator::ScopeNodeAdded).void }
        def on_scope(event)
          event.node.detach if @pipeline.skip_object?(event.symbol, event.constant) && event.node.empty?
        end

        sig { override.params(event: RBIGenerator::NodeAdded).returns(T::Boolean) }
        def ignore?(event)
          event.is_a?(RBIGenerator::ForeignScopeNodeAdded)
        end
      end
    end
  end
end
