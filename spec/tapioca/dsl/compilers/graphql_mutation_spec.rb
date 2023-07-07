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

            it "generates correct RBI for all graphql types" do
              add_ruby_file("create_comment.rb", <<~RUBY)
                class LoadedType < GraphQL::Schema::Object
                  field "foo", type: String
                end

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
                  argument :loaded_argument_id, ID, required: true, loads: LoadedType

                  def resolve(boolean:, float:, id:, int:, date:, datetime:, json:, string:, enum_a:, enum_b:, input_object:, custom_scalar:, loaded_argument:)
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class CreateComment
                  sig { params(boolean: T::Boolean, float: ::Float, id: ::String, int: ::Integer, date: ::Date, datetime: ::Time, json: T::Hash[::String, T.untyped], string: ::String, enum_a: ::String, enum_b: T.any(::String, ::Symbol), input_object: ::CreateCommentInput, custom_scalar: T.untyped, loaded_argument: T.untyped).returns(T.untyped) }
                  def resolve(boolean:, float:, id:, int:, date:, datetime:, json:, string:, enum_a:, enum_b:, input_object:, custom_scalar:, loaded_argument:); end
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
