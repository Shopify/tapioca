# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SorbetSignatures < Base
        private

        # @override
        #: (MethodNodeAdded event) -> void
        def on_method(event)
          signature = event.signature
          return unless signature

          event.node.sigs.concat(
            signature.compile_to_rbi_sig(event.parameters) { |sym| @pipeline.push_symbol(sym) },
          )
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
