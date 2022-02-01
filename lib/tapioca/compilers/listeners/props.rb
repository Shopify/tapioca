# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    module NodeListeners
      class Props < Base
        extend T::Sig

        include Reflection

        private

        sig { override.params(event: Tapioca::Compilers::SymbolTableCompiler::ScopeEvent).void }
        def on_scope(event)
          constant = event.constant
          return unless T::Props::ClassMethods === constant

          constant.props.map do |name, prop|
            type = prop.fetch(:type_object, "T.untyped").to_s.gsub(".returns(<VOID>)", ".void")

            default = prop.key?(:default) ? "T.unsafe(nil)" : nil
            event.scope << if prop.fetch(:immutable, false)
              RBI::TStructConst.new(name.to_s, type, default: default)
            else
              RBI::TStructProp.new(name.to_s, type, default: default)
            end
          end
        end
      end
    end
  end
end
