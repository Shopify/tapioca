# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Helpers
      class GraphqlTypeHelperSpec < Minitest::Spec
        extend T::Sig

        require "graphql"
        require_relative "../../../../lib/tapioca/dsl/helpers/graphql_type_helper.rb"

        it "generates the expected sorbet type expression when using type GraphQL::Types::Boolean" do
          type = GraphQL::Types::Boolean
          assert_equal(
            "T.nilable(T::Boolean)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(type),
          )
          assert_equal(
            "T.nilable(T::Boolean)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::Wrapper.new(type)),
          )
          assert_equal(
            "T.nilable(T::Array[T::Boolean])",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::List.new(type)),
          )
          assert_equal(
            "T::Boolean",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::NonNull.new(type)),
          )
        end

        it "generates the expected sorbet type expression when using type GraphQL::Types::String" do
          type = GraphQL::Types::String
          assert_equal(
            "T.nilable(::String)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(type),
          )
          assert_equal(
            "T.nilable(::String)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::Wrapper.new(type)),
          )
          assert_equal(
            "T.nilable(T::Array[::String])",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::List.new(type)),
          )
          assert_equal(
            "::String",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::NonNull.new(type)),
          )
        end

        it "generates the expected sorbet type expression when using type GraphQL::Types::Float" do
          type = GraphQL::Types::Float
          assert_equal(
            "T.nilable(::Float)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(type),
          )
          assert_equal(
            "T.nilable(::Float)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::Wrapper.new(type)),
          )
          assert_equal(
            "T.nilable(T::Array[::Float])",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::List.new(type)),
          )
          assert_equal(
            "::Float",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::NonNull.new(type)),
          )
        end

        it "generates the expected sorbet type expression when using type GraphQL::Types::ID" do
          type = GraphQL::Types::ID
          assert_equal(
            "T.nilable(::String)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(type),
          )
          assert_equal(
            "T.nilable(::String)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::Wrapper.new(type)),
          )
          assert_equal(
            "T.nilable(T::Array[::String])",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::List.new(type)),
          )
          assert_equal(
            "::String",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::NonNull.new(type)),
          )
        end

        it "generates the expected sorbet type expression when using type GraphQL::Types::Int" do
          type = GraphQL::Types::Int
          assert_equal(
            "T.nilable(::Integer)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(type),
          )
          assert_equal(
            "T.nilable(::Integer)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::Wrapper.new(type)),
          )
          assert_equal(
            "T.nilable(T::Array[::Integer])",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::List.new(type)),
          )
          assert_equal(
            "::Integer",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::NonNull.new(type)),
          )
        end

        it "generates the expected sorbet type expression when using type GraphQL::Types::BigInt" do
          type = GraphQL::Types::BigInt
          assert_equal(
            "T.nilable(::Integer)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(type),
          )
          assert_equal(
            "T.nilable(::Integer)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::Wrapper.new(type)),
          )
          assert_equal(
            "T.nilable(T::Array[::Integer])",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::List.new(type)),
          )
          assert_equal(
            "::Integer",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::NonNull.new(type)),
          )
        end

        it "generates the expected sorbet type expression when using type GraphQL::Types::ISO8601Date" do
          type = GraphQL::Types::ISO8601Date
          assert_equal(
            "T.nilable(::Date)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(type),
          )
          assert_equal(
            "T.nilable(::Date)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::Wrapper.new(type)),
          )
          assert_equal(
            "T.nilable(T::Array[::Date])",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::List.new(type)),
          )
          assert_equal(
            "::Date",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::NonNull.new(type)),
          )
        end

        it "generates the expected sorbet type expression when using type GraphQL::Types::ISO8601DateTime" do
          type = GraphQL::Types::ISO8601DateTime
          assert_equal(
            "T.nilable(::Time)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(type),
          )
          assert_equal(
            "T.nilable(::Time)",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::Wrapper.new(type)),
          )
          assert_equal(
            "T.nilable(T::Array[::Time])",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::List.new(type)),
          )
          assert_equal(
            "::Time",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::NonNull.new(type)),
          )
        end

        it "generates the expected sorbet type expression when using type GraphQL::Types::JSON" do
          type = GraphQL::Types::JSON
          assert_equal(
            "T.nilable(T::Hash[::String, T.untyped])",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(type),
          )
          assert_equal(
            "T.nilable(T::Hash[::String, T.untyped])",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::Wrapper.new(type)),
          )
          assert_equal(
            "T.nilable(T::Array[T::Hash[::String, T.untyped]])",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::List.new(type)),
          )
          assert_equal(
            "T::Hash[::String, T.untyped]",
            Tapioca::Dsl::Helpers::GraphqlTypeHelper.type_for(GraphQL::Schema::NonNull.new(type)),
          )
        end
      end
    end
  end
end
