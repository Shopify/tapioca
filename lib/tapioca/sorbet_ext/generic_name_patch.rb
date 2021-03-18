# typed: true
# frozen_string_literal: true

require "tapioca/sorbet_ext/name_patch"

module T
  module Generic
    # This module intercepts calls to generic type instantiation and type variable definitions.
    # Tapioca stores the data from those calls in a `GenericTypeRegistry` which can then be used
    # for looking up the original call details when we are trying to do code generation.
    #
    # We are interested in the data of the `[]`, `type_member` and `type_template` calls which
    # are all needed to generate good generic information at runtime.
    module TypeStoragePatch
      def [](*types)
        Tapioca::GenericTypeRegistry.register_type(self, types)
      end

      def type_member(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        Tapioca::GenericTypeRegistry.register_type_member(self, super, fixed, lower, upper)
      end

      def type_template(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        Tapioca::GenericTypeRegistry.register_type_template(self, super, fixed, lower, upper)
      end
    end

    prepend TypeStoragePatch
  end

  module Types
    class Simple
      # This module intercepts calls to the `name` method for
      # simple types, so that it can ask the name to the type if
      # the type is generic, since, by this point, we've created
      # a clone of that type with the `name` method returning the
      # appropriate name for that specific concrete type.
      module GenericNamePatch
        def name
          if T::Generic === @raw_type
            # for types that are generic, use the name
            # returned by the "name" method of this instance
            @name ||= T.unsafe(@raw_type).name.freeze
          else
            # otherwise, fallback to the normal name lookup
            super
          end
        end
      end

      prepend GenericNamePatch
    end
  end
end
