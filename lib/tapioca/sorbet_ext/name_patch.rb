# typed: true
# frozen_string_literal: true

module T
  module Types
    class Simple
      module NamePatch
        def name
          # Sorbet memoizes this method into the `@name` instance variable but
          # doing so means that types get memoized before this patch is applied
          name = Tapioca::Runtime::Reflection.qualified_name_of(@raw_type)
          name = "::T.untyped" if name.nil?

          name
        end
      end

      prepend NamePatch
    end
  end
end
