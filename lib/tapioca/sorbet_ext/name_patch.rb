# typed: true
# frozen_string_literal: true

# We need sorbet to compile this signature before applying the patch
# to avoid an infinite loop.
::Tapioca::Reflection.qualified_name_of(String)

module T
  module Types
    class Simple
      module NamePatch
        def name
          # Sorbet memoizes this method into the `@name` instance variable but
          # doing so means that types get memoized before this patch is applied
          ::Tapioca::Reflection.qualified_name_of(@raw_type)
        end
      end

      prepend NamePatch
    end
  end
end
