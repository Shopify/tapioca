# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SorbetHelpers < Base
        extend T::Sig

        include Reflection

        private

        sig { override.params(event: ScopeNodeAdded).void }
        def on_scope(event)
          constant = event.constant
          node = event.node

          abstract_type = T::Private::Abstract::Data.get(constant, :abstract_type) ||
            T::Private::Abstract::Data.get(singleton_class_of(constant), :abstract_type)

          node << RBI::Helper.new(abstract_type.to_s) if abstract_type
          node << RBI::Helper.new("final") if T::Private::Final.final_module?(constant)
          node << RBI::Helper.new("sealed") if T::Private::Sealed.sealed_module?(constant)
        end
      end
    end
  end
end
