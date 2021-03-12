# typed: true
# frozen_string_literal: true

require "tapioca/sorbet_ext/name_patch"

module T
  module Generic
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
