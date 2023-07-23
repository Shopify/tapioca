# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      module GraphqlTypeHelper
        extend self

        extend T::Sig

        sig { params(type: GraphQL::Schema::Wrapper).returns(String) }
        def type_for(type)
          unwrapped_type = type.unwrap

          parsed_type = case unwrapped_type
          when GraphQL::Types::Boolean.singleton_class
            "T::Boolean"
          when GraphQL::Types::Float.singleton_class
            type_for_constant(Float)
          when GraphQL::Types::ID.singleton_class, GraphQL::Types::String.singleton_class
            type_for_constant(String)
          when GraphQL::Types::Int.singleton_class
            type_for_constant(Integer)
          when GraphQL::Types::ISO8601Date.singleton_class
            type_for_constant(Date)
          when GraphQL::Types::ISO8601DateTime.singleton_class
            type_for_constant(Time)
          when GraphQL::Types::JSON.singleton_class
            "T::Hash[::String, T.untyped]"
          when GraphQL::Schema::Enum.singleton_class
            enum_values = T.cast(unwrapped_type.enum_values, T::Array[GraphQL::Schema::EnumValue])
            value_types = enum_values.map { |v| type_for_constant(v.value.class) }.uniq

            if value_types.size == 1
              T.must(value_types.first)
            else
              "T.any(#{value_types.join(", ")})"
            end
          when GraphQL::Schema::InputObject.singleton_class
            type_for_constant(unwrapped_type)
          when GraphQL::Schema::NonNull.singleton_class
            type_for(unwrapped_type.of_type)
          when Module
            Runtime::Reflection.qualified_name_of(unwrapped_type) || "T.untyped"
          else
            "T.untyped"
          end

          if type.list?
            parsed_type = "T::Array[#{parsed_type}]"
          end

          unless type.non_null?
            parsed_type = RBIHelper.as_nilable_type(parsed_type)
          end

          parsed_type
        end

        private

        sig { params(constant: Module).returns(String) }
        def type_for_constant(constant)
          Runtime::Reflection.qualified_name_of(constant) || "T.untyped"
        end
      end
    end
  end
end
