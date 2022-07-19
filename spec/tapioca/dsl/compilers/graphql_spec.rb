# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class GraphqlSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::Graphql" do
          describe "initialize" do
            it "gathers only graphql types" do
              add_ruby_file("content.rb", <<~RUBY)
                class Article < GraphQL::Schema::Object
                  field :title, String, null: false
                end

                class User
                end
              RUBY

              assert_includes(gathered_constants, "Article")
              refute_includes(gathered_constants, "User")
            end
          end

          describe "decorate" do
            it "generates an empty RBI file if there are no fields" do
              add_ruby_file("article.rb", <<~RUBY)
                class Article < GraphQL::Schema::Object
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:Article))
            end

            it "generates methods with signatures for types" do
              add_ruby_file("user.rb", <<~RUBY)
                module Admin
                  class User < GraphQL::Schema::Object
                    field :name, String, null: false
                  end
                end
              RUBY

              add_ruby_file("enum.rb", <<~RUBY)
                class Enum < GraphQL::Schema::Enum
                  value "SOMETHING", "Description 1"
                  value "OTHER_THING", "Description 2"
                end
              RUBY

              add_ruby_file("article.rb", <<~RUBY)
                class Article < GraphQL::Schema::Object
                  field :title, String, null: false

                  field :body, String

                  field :author, Admin::User, null: true do
                    argument :name, String
                  end

                  field :score, Integer
                  field :published, Boolean

                  field :comments, [String], resolver_method: :find_comments

                  field :the_enum, Enum, null: false

                  def find_comments
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Article
                  sig { params(name: String).returns(T.nilable(Admin::User)) }
                  def author(name:); end

                  sig { returns(T.nilable(String)) }
                  def body; end

                  sig { returns(T::Array[String]) }
                  def find_comments; end

                  sig { returns(T.nilable(T::Boolean)) }
                  def published; end

                  sig { returns(T.nilable(Integer)) }
                  def score; end

                  sig { returns(Enum) }
                  def the_enum; end

                  sig { returns(String) }
                  def title; end
                end
              RBI

              assert_equal(expected, rbi_for(:Article))
            end
          end
        end
      end
    end
  end
end
