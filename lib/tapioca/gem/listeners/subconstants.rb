# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class Subconstants < Base
        extend T::Sig

        include Runtime::Reflection

        private

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          symbol = event.symbol
          return if @pipeline.symbol_in_payload?(symbol) && event.node.empty?

          prefix = symbol == "Object" ? "" : symbol

          constant = event.constant
          constants_of(constant).sort.uniq.map do |constant_name|
            name = "#{prefix}::#{constant_name}"
            subconstant = constantize(name)

            # Don't compile modules of Object because Object::Foo == Foo
            # Don't compile modules of BasicObject because BasicObject::BasicObject == BasicObject
            next if (Object == constant || BasicObject == constant) && Module === subconstant
            next unless subconstant

            @pipeline.push_constant(name, subconstant)
          end
        end
      end
    end
  end
end
