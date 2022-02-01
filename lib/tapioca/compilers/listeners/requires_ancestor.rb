# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    module NodeListeners
      class RequiresAncestor < Base
        extend T::Sig

        private

        sig { override.params(event: Tapioca::Compilers::SymbolTableCompiler::NodeEvent).void }
        def on_node(event)
          node = event.node

          case node
          when RBI::Scope
            ancestors = Trackers::RequiredAncestor.required_ancestors_by(T.cast(event.constant, Module))
            ancestors.each do |ancestor|
              next unless ancestor # TODO: We should have a way to warn from here
              node << RBI::RequiresAncestor.new(ancestor.to_s)
            end
          end
        end
      end
    end
  end
end
