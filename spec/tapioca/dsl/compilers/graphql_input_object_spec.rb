# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class GraphqlInputObjectSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::GraphqlInputObject" do
          describe "initialize" do
            it "gathers no constants if there are no GraphQL::Schema::InputObject subclasses" do
              assert_empty(gathered_constants)
            end

            it "gathers only GraphQL::Schema::InputObject subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class CreateCommentInput < GraphQL::Schema::InputObject
                end

                class User
                end
              RUBY

              assert_equal(["CreateCommentInput"], gathered_constants)
            end

            it "gathers subclasses of GraphQL::Schema::InputObject subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class BaseInputObject < GraphQL::Schema::InputObject
                end

                class CreateCommentInput < BaseInputObject
                end
              RUBY

              assert_equal(["BaseInputObject", "CreateCommentInput"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates an empty RBI file if there is no resolve method" do
              add_ruby_file("create_comment_input.rb", <<~RUBY)
                class CreateCommentInput < GraphQL::Schema::InputObject
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:CreateCommentInput))
            end

            it "generates correct RBI file for subclass with methods" do
              add_ruby_file("create_comment_input.rb", <<~RUBY)
                class CreateCommentInput < GraphQL::Schema::InputObject
                  argument :body, String, required: true
                  argument :post_id, ID, required: true

                  def resolve(body:, post_id:)
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class CreateCommentInput
                  sig { returns(::String) }
                  def body; end

                  sig { returns(::String) }
                  def post_id; end
                end
              RBI

              assert_equal(expected, rbi_for(:CreateCommentInput))
            end
          end
        end
      end
    end
  end
end
