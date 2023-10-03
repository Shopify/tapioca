# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class GraphqlMutationSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::GraphqlMutation" do
          describe "initialize" do
            it "gathers no constants if there are no GraphQL::Schema::Mutation subclasses" do
              assert_empty(gathered_constants)
            end

            it "gathers only GraphQL::Schema::Mutation subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class CreateComment < GraphQL::Schema::Mutation
                end

                class User
                end
              RUBY

              assert_equal(["CreateComment"], gathered_constants)
            end

            it "gathers subclasses of GraphQL::Schema::Mutation subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class BaseMutation < GraphQL::Schema::Mutation
                end

                class CreateComment < BaseMutation
                end
              RUBY

              assert_equal(["BaseMutation", "CreateComment"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates an empty RBI file if there is no resolve method" do
              add_ruby_file("create_comment.rb", <<~RUBY)
                class CreateComment < GraphQL::Schema::Mutation
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:CreateComment))
            end

            it "generates correct RBI file for subclass with methods" do
              add_ruby_file("create_comment.rb", <<~RUBY)
                class CreateComment < GraphQL::Schema::Mutation
                  argument :body, String, required: true
                  argument :post_id, ID, required: true

                  def resolve(body:, post_id:)
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class CreateComment
                  sig { params(body: ::String, post_id: ::String).returns(T.untyped) }
                  def resolve(body:, post_id:); end
                end
              RBI

              assert_equal(expected, rbi_for(:CreateComment))
            end

            it "generates an empty RBI file if there is an inline signature" do
              add_ruby_file("create_comment.rb", <<~RUBY)
                class CreateComment < GraphQL::Schema::Mutation
                  extend T::Sig

                  argument :body, String, required: true
                  argument :post_id, ID, required: true

                  sig { params(body: String, post_id: String).returns(T.untyped) }
                  def resolve(body:, post_id:)
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:CreateComment))
            end

            it "generates correct RBI for default values with replacement" do
              add_ruby_file("create_comment.rb", <<~RUBY)
                class CreateComment < GraphQL::Schema::Mutation
                  argument :body, String, required: false, default_value: "comment", replace_null_with_default: true
                  argument :author, String, required: false, default_value: nil, replace_null_with_default: true
                  argument :post_id, ID, required: true

                  def resolve(body:, author:, post_id:)
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class CreateComment
                  sig { params(body: ::String, author: T.nilable(::String), post_id: ::String).returns(T.untyped) }
                  def resolve(body:, author:, post_id:); end
                end
              RBI

              assert_equal(expected, rbi_for(:CreateComment))
            end

            it "generates correct RBI for all graphql types" do
              add_ruby_file("create_comment.rb", <<~RUBY)
                class EnumA < GraphQL::Schema::Enum
                  value "foo"
                end

                class EnumB < GraphQL::Schema::Enum
                  value "foo", value: "foo"
                  value "bar", value: :bar
                end

                class CreateCommentInput < GraphQL::Schema::InputObject
                end

                class CustomScalar < GraphQL::Schema::Scalar; end

                class CreateComment < GraphQL::Schema::Mutation
                  argument :boolean, Boolean, required: true
                  argument :float, Float, required: true
                  argument :id, ID, required: true
                  argument :int, Int, required: true
                  argument :date, GraphQL::Types::ISO8601Date, required: true
                  argument :datetime, GraphQL::Types::ISO8601DateTime, required: true
                  argument :json, GraphQL::Types::JSON, required: true
                  argument :string, String, required: true
                  argument :enum_a, EnumA, required: true
                  argument :enum_b, EnumB, required: true
                  argument :input_object, CreateCommentInput, required: true
                  argument :custom_scalar, CustomScalar, required: true

                  def resolve(boolean:, float:, id:, int:, date:, datetime:, json:, string:, enum_a:, enum_b:, input_object:, custom_scalar:)
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class CreateComment
                  sig { params(boolean: T::Boolean, float: ::Float, id: ::String, int: ::Integer, date: ::Date, datetime: ::Time, json: T::Hash[::String, T.untyped], string: ::String, enum_a: ::String, enum_b: T.any(::String, ::Symbol), input_object: ::CreateCommentInput, custom_scalar: T.untyped).returns(T.untyped) }
                  def resolve(boolean:, float:, id:, int:, date:, datetime:, json:, string:, enum_a:, enum_b:, input_object:, custom_scalar:); end
                end
              RBI

              assert_equal(expected, rbi_for(:CreateComment))
            end

            it "generates correct RBI for mutation loaders" do
              add_ruby_file("create_comment.rb", <<~RUBY)
                class LoadedType < GraphQL::Schema::Object
                  field "foo", type: String
                end

                class CreateComment < GraphQL::Schema::Mutation
                  argument :loaded_argument_id, ID, required: true, loads: LoadedType
                  argument :optional_loaded_argument_id, ID, required: false, loads: LoadedType
                  argument :loaded_argument_ids, [ID], required: true, loads: LoadedType
                  argument :optional_loaded_argument_ids, [ID], required: false, loads: LoadedType
                  argument :renamed_loaded_argument, ID, required: true, loads: LoadedType, as: :custom_name

                  def resolve(loaded_argument:, loaded_arguments:, custom_name:, optional_loaded_argument: nil, optional_loaded_arguments: nil)
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class CreateComment
                  sig { params(loaded_argument: ::LoadedType, loaded_arguments: T::Array[::LoadedType], custom_name: ::LoadedType, optional_loaded_argument: T.nilable(::LoadedType), optional_loaded_arguments: T.nilable(T::Array[::LoadedType])).returns(T.untyped) }
                  def resolve(loaded_argument:, loaded_arguments:, custom_name:, optional_loaded_argument: T.unsafe(nil), optional_loaded_arguments: T.unsafe(nil)); end
                end
              RBI

              assert_equal(expected, rbi_for(:CreateComment))
            end

            it "generates correct RBI for custom scalars with return types" do
              add_ruby_file("create_comment.rb", <<~RUBY)
                class CustomScalar; end

                class CustomScalarType < GraphQL::Schema::Scalar
                  class << self
                    extend T::Sig

                    sig { params(value: T.untyped, context: GraphQL::Query::Context).returns(CustomScalar) }
                    def coerce_input(value, context)
                      CustomScalar.new
                    end
                  end
                end

                class CreateComment < GraphQL::Schema::Mutation
                  argument :custom_scalar, CustomScalarType, required: true
                  argument :custom_scalar_array, [CustomScalarType], required: true
                  argument :optional_custom_scalar, CustomScalarType, required: false

                  def resolve(custom_scalar:, custom_scalar_array:, optional_custom_scalar: nil)
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class CreateComment
                  sig { params(custom_scalar: ::CustomScalar, custom_scalar_array: T::Array[::CustomScalar], optional_custom_scalar: T.nilable(::CustomScalar)).returns(T.untyped) }
                  def resolve(custom_scalar:, custom_scalar_array:, optional_custom_scalar: T.unsafe(nil)); end
                end
              RBI

              assert_equal(expected, rbi_for(:CreateComment))
            end
          end
        end
      end
    end
  end
end
