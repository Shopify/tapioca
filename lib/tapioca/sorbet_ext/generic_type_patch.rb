# typed: true
# frozen_string_literal: true

module T
  module Utils
    module Private
      # Preserve Tapioca's generic type variables and instantiated generic
      # names when Sorbet coerces them into runtime types.
      module TapiocaGenericTypeCoercePatch
        def coerce_and_check_module_types(val, check_val, check_module_type)
          if val.is_a?(Tapioca::TypeVariableModule)
            val.coerce_to_type_variable
          elsif val.respond_to?(:__tapioca_override_type)
            val.__tapioca_override_type
          else
            super
          end
        end
      end

      class << self
        prepend(TapiocaGenericTypeCoercePatch)
      end
    end
  end

  module Private
    module Casts
      module TapiocaGenericTypeCastPatch
        # https://github.com/sorbet/sorbet/commit/b8d64c7fd9a08e2b9159b5d592bc2de6d586b44a
        # inlines the Module fast path in `T.let`, `T.cast`, `T.bind`, and
        # `T.assert_type!`, so generic module clones can reach this cast path
        # without going through `T::Utils::Private::TapiocaGenericTypeCoercePatch`.
        def cast(value, type, cast_method)
          if type.respond_to?(:__tapioca_override_type)
            type = type.__tapioca_override_type
          end

          super(value, type, cast_method)
        end
      end

      class << self
        prepend(TapiocaGenericTypeCastPatch)
      end
    end
  end
end
