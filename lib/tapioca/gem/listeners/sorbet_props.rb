# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SorbetProps < Base
        extend T::Sig

        private

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          constant = event.constant
          node = event.node

          return unless T::Props::ClassMethods === constant

          constant.props.map do |name, prop|
            type = prop.fetch(:type_object, "T.untyped").to_s.gsub(".returns(<VOID>)", ".void")

            default = prop.key?(:default) || prop.key?(:factory) ? "T.unsafe(nil)" : nil
            node << if prop.fetch(:immutable, false)
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
