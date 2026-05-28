# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      module ActiveModelTypeHelper
        class << self
          # Returns the type indicated by the custom ActiveModel::Type::Value.
          # Accepts subclasses of ActiveModel::Type::Value as well as classes that implement similar methods.
          #: (untyped type_value) -> String
          def type_for(type_value)
            return "T.untyped" if Runtime::GenericTypeRegistry.generic_type_instance?(type_value)

            return_type = lookup_tapioca_type(type_value)
            return return_type.to_s if return_type

            [:deserialize, :cast, :cast_value].each do |method|
              type = lookup_return_type_of_method(type_value, method)
              return type if type
            end

            arg_type = lookup_arg_type_of_method(type_value, :serialize)
            return arg_type if arg_type

            "T.untyped"
          end

          #: (untyped type_value) -> bool
          def assume_nilable?(type_value)
            !type_value.respond_to?(:__tapioca_type)
          end

          private

          MEANINGLESS_TYPES = [
            T.untyped,
            T.noreturn,
            T::Private::Types::Void,
            T::Private::Types::NotTyped,
          ].freeze #: Array[Object]

          MEANINGLESS_TYPE_STRINGS = [
            "T.untyped",
            "::T.untyped",
            "T.noreturn",
            "::T.noreturn",
            "void",
            "<NOT-TYPED>",
            "<VOID>",
          ].to_set.freeze #: Set[String]

          #: (untyped type) -> bool
          def meaningful_type?(type)
            !MEANINGLESS_TYPES.include?(type)
          end

          #: (String type_string) -> bool
          def meaningful_type_string?(type_string)
            !MEANINGLESS_TYPE_STRINGS.include?(type_string)
          end

          #: (untyped obj) -> T::Types::Base?
          def lookup_tapioca_type(obj)
            T::Utils.coerce(obj.__tapioca_type) if obj.respond_to?(:__tapioca_type)
          end

          # Returns the return type of `method` on `obj` as a string, using
          # the Sorbet runtime signature when one is registered and falling
          # back to inline RBS comments otherwise. Returns nil when no
          # meaningful type can be discovered.
          #: (untyped obj, Symbol method) -> String?
          def lookup_return_type_of_method(obj, method)
            method_def = lookup_method(obj, method)
            return unless method_def

            signature = Runtime::Reflection.signature_of(method_def)
            if signature
              return_type = signature.return_type

              return return_type.to_s if return_type && meaningful_type?(return_type)

              return
            end

            rbs_sig = Tapioca::RBS::DslSignatures.build(method_def)
            return unless rbs_sig

            type_string = rbs_sig.return_type.to_s
            return unless meaningful_type_string?(type_string)

            type_string
          end

          # Returns the first arg's type of `method` on `obj` as a string,
          # using the Sorbet runtime signature when one is registered and
          # falling back to inline RBS comments otherwise. Returns nil when
          # no meaningful type can be discovered.
          #: (untyped obj, Symbol method) -> String?
          def lookup_arg_type_of_method(obj, method)
            method_def = lookup_method(obj, method)
            return unless method_def

            signature = Runtime::Reflection.signature_of(method_def)
            if signature
              first_arg_type = signature.arg_types.dig(0, 1)

              return first_arg_type.to_s if first_arg_type && meaningful_type?(first_arg_type)

              return
            end

            rbs_sig = Tapioca::RBS::DslSignatures.build(method_def)
            return unless rbs_sig

            first_param = rbs_sig.params.first
            return unless first_param

            type_string = first_param.type.to_s
            return unless meaningful_type_string?(type_string)

            type_string
          end

          #: (untyped obj, Symbol method) -> Method?
          def lookup_method(obj, method)
            obj.method(method)
          rescue NameError
            nil
          end
        end
      end
    end
  end
end
