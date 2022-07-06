# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      class GraphqlTypeHelper
        extend T::Sig
        include RBIHelper
        include Runtime::Reflection

        sig { params(type: GraphQL::Schema::Wrapper).returns(String) }
        def type_for(type)
          unwrapped_type = type.unwrap

          parsed_type = case unwrapped_type
          when GraphQL::Types::Boolean.singleton_class
            "T::Boolean"
          when GraphQL::Types::Float.singleton_class
            qualified_name_of(Float)
          when GraphQL::Types::ID.singleton_class
            qualified_name_of(String)
          when GraphQL::Types::Int.singleton_class
            qualified_name_of(Integer)
          when GraphQL::Types::ISO8601Date.singleton_class
            qualified_name_of(Date)
          when GraphQL::Types::ISO8601DateTime.singleton_class
            qualified_name_of(DateTime)
          when GraphQL::Types::JSON.singleton_class
            "T::Hash[::String, T.untyped]"
          when GraphQL::Types::String.singleton_class
            qualified_name_of(String)
          when GraphQL::Schema::Enum.singleton_class
            enum_values = T.cast(unwrapped_type.enum_values, T::Array[GraphQL::Schema::EnumValue])
            value_types = enum_values.map { |v| qualified_name_of(v.value.class) }.uniq
            if value_types.size == 1
              value_types.first
            else
              "T.any(#{value_types.join(", ")})"
            end
          when GraphQL::Schema::InputObject.singleton_class
            qualified_name_of(unwrapped_type)
          else
            "T.untyped"
          end

          parsed_type = T.must(parsed_type)

          if type.list?
            parsed_type = "T::Array[#{parsed_type}]"
          end

          unless type.non_null?
            parsed_type = as_nilable_type(parsed_type)
          end

          parsed_type
        end
      end
    end
  end
end
