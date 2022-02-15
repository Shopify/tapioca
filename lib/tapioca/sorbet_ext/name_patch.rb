# typed: true
# frozen_string_literal: true

# We need sorbet to compile the signature for `qualified_name_of` before applying
# the patch to avoid an infinite loop.
T::Utils.signature_for_method(::Tapioca::Runtime::Reflection.method(:qualified_name_of))

module T
  module Types
    class Simple
      module NamePatch
        def name
          # Sorbet memoizes this method into the `@name` instance variable but
          # doing so means that types get memoized before this patch is applied
          ::Tapioca::Runtime::Reflection.qualified_name_of(@raw_type)
        end
      end

      prepend NamePatch
    end
  end
end
