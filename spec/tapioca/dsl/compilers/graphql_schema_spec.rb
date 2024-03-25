# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class GraphqlSchemaSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::GraphqlSchema" do
          describe "initialize" do
            it "gathers no constants if there are no GraphQL::Schema subclasses" do
              assert_empty(gathered_constants)
            end

            it "gathers only GraphQL::Schema subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class MySchema < GraphQL::Schema
                end

                class User
                end
              RUBY

              assert_equal(["MySchema"], gathered_constants)
            end

            it "gathers subclasses of GraphQL::Schema subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class MyBaseSchema < GraphQL::Schema
                end

                class MySchema < MyBaseSchema
                end
              RUBY

              assert_equal(["MyBaseSchema", "MySchema"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates an empty RBI file if there is no custom context_class is set" do
              add_ruby_file("create_comment.rb", <<~RUBY)
                class MySchema < GraphQL::Schema
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:MySchema))
            end

            it "generates correct RBI file for subclass that sets context_class" do
              add_ruby_file("create_comment.rb", <<~RUBY)
                class MySchema < GraphQL::Schema
                  class MyContext < GraphQL::Query::Context; end

                  context_class MyContext
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class MySchema
                  sig { returns(MySchema::MyContext) }
                  def context; end
                end
              RBI

              assert_equal(expected, rbi_for(:MySchema))
            end

            it "generates an empty RBI file if there is an inline signature" do
              add_ruby_file("create_comment.rb", <<~RUBY)
                class MySchema < GraphQL::Schema
                  extend T::Sig

                  class MyContext < GraphQL::Query::Context; end

                  context_class MyContext

                  sig { returns(SomethingElse) }
                  def context
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:MySchema))
            end
          end
        end
      end
    end
  end
end
