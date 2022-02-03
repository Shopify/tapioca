# typed: strict
# frozen_string_literal: true

module Tapioca
  module Compilers
    module Gem
      module Listeners
        class RemoveEmptyPayloadScopes < Base
          extend T::Sig

          include Reflection

          private

          sig { override.params(event: ScopeNodeAdded).void }
          def on_scope(event)
            event.node.detach if @compiler.symbol_in_payload?(event.symbol) && event.node.empty?
          end
        end
      end
    end
  end
end
