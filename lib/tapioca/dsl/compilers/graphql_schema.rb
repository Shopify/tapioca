# typed: strict
# frozen_string_literal: true

begin
  gem("graphql", ">= 1.13")
  require "graphql"
rescue LoadError
  return
end

require "tapioca/dsl/helpers/graphql_type_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::GraphqlSchema` generates RBI files for subclasses of
      # [`GraphQL::Schema`](https://graphql-ruby.org/api-doc/2.1.7/GraphQL/Schema).
      #
      # For example, with the following `GraphQL::Schema` subclass:
      #
      # ~~~rb
      # class MySchema> < GraphQL::Schema
      #   class MyContext < GraphQL::Query::Context; end
      #
      #   context_class MyContext
      #
      #   # ...
      # end
      # ~~~
      #
      # this compiler will produce the RBI file `my_schema.rbi` with the following content:
      #
      # ~~~rbi
      # # my_schema.rbi
      # # typed: true
      # class MySchema
      #   sig { returns(MySchema::MyContext) }
      #   def context; end
      # end
      # ~~~
      class GraphqlSchema < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: T.class_of(GraphQL::Schema) } }

        sig { override.void }
        def decorate
          custom_context_class = constant.context_class
          # Skip decoration if the context class hasn't been customized
          return if custom_context_class == GraphQL::Query::Context

          return if constant.method_defined?(:context, false) # Skip if the Schema overrides the `#context` getter.

          root.create_path(constant) do |schema|
            schema.create_method("context", return_type: T.must(name_of(custom_context_class)))
          end
        end

        class << self
          extend T::Sig

          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            all_classes.select { |c| c < GraphQL::Schema && c != GraphQL::Query::NullContext::NullSchema }
          end
        end
      end
    end
  end
end
