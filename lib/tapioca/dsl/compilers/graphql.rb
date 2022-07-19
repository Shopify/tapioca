# typed: strict
# frozen_string_literal: true

begin
  require "graphql"
rescue LoadError
  return
end

module Tapioca
  module Dsl
    module Compilers
      class Graphql < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(::GraphQL::Schema::Object) } }

        sig { override.void }
        def decorate
          root.create_path(constant) do |object|
            constant.fields.each do |_name, config|
              parameters = config.arguments.map do |name, config|
                create_kw_param(name, type: graphl_to_type(config.type))
              end

              object.create_method(
                config.resolver_method.to_s,
                parameters: parameters,
                return_type: graphl_to_type(config.type)
              )
            end
          end
        rescue GraphQL::Schema::DuplicateNamesError
          # do nothing
        end

        sig { override.returns(T::Enumerable[Module]) }
        def self.gather_constants
          descendants_of(::GraphQL::Schema::Object)
        end

        private

        sig { params(field_type: T.any(Class, GraphQL::Schema::NonNull, GraphQL::Schema::List)).returns(String) }
        def graphl_to_type(field_type)
          case field_type
          when Class
            sanitize_type(field_type.to_s, T.unsafe(field_type).non_null?)
          when GraphQL::Schema::NonNull
            sanitize_type(field_type.of_type.to_s, field_type.non_null?)
          when GraphQL::Schema::List
            "T::Array[#{graphl_to_type(field_type.of_type)}]"
          end
        end

        sig { params(type: String, non_null: T::Boolean).returns(String) }
        def sanitize_type(type, non_null)
          type.delete_prefix!("GraphQL::Types::")
          type.gsub!(/Boolean$/, "T::Boolean")
          type.gsub!(/Int$/, "Integer")
          type = "T.nilable(#{type})" unless non_null
          type
        end
      end
    end
  end
end
