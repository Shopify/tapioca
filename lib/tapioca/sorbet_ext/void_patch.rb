# typed: true
# frozen_string_literal: true

# If Signature has `effective_return_type`, then `return_type` always returns the correct type.
# Ref: https://github.com/sorbet/sorbet/pull/10121
return if T::Private::Methods::Signature.method_defined?(:effective_return_type)

module T
  module Private
    module Methods
      module DeclBuilderPatch
        def void
          super.tap do
            @_real_returns_is_void = true
          end
        end

        def finalize!
          super.tap do
            #: self as untyped
            decl.returns = T::Private::Types::Void::Private::INSTANCE if @_real_returns_is_void
          end
        end
      end

      DeclBuilder.prepend(DeclBuilderPatch)
    end
  end
end
