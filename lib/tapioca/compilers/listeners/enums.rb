# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    module NodeListeners
      class Enums < Base
        extend T::Sig

        include Reflection

        private

        sig { override.params(event: Tapioca::Compilers::SymbolTableCompiler::NodeEvent).void }
        def on_node(event)
          node = event.node
          case node
          when RBI::Scope
            constant = event.constant
            return unless T::Enum > constant

            enums = T.unsafe(constant).values.map do |enum_type|
              enum_type.instance_variable_get(:@const_name).to_s
            end

            node << RBI::TEnumBlock.new(enums)
          end
        end
      end
    end
  end
end
