# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class GraphqlImplementsSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::GraphqlImplements" do
          describe "initialize" do
            it "gathers no constants if there are no GraphQL::Schema::Object subclasses" do
              assert_empty(gathered_constants)
            end

            it "gathers only GraphQL::Schema::Object subclasses that implement an interface" do
              add_ruby_file("content.rb", <<~RUBY)
                module Commentable
                  include GraphQL::Schema::Interface
                end

                class Post < GraphQL::Schema::Object
                  implements Commentable
                end

                class FeaturedPost < Post
                end

                class User < GraphQL::Schema::Object
                end

                class PostOrUser < GraphQL::Schema::Union
                  possible_types Post, User
                end
              RUBY

              assert_equal(["Post"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates correct RBI file for types that implement an interface" do
              add_ruby_file("post.rb", <<~RUBY)
                module Commentable
                  include GraphQL::Schema::Interface
                end

                class Post < GraphQL::Schema::Object
                  implements Commentable
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Post
                  include Commentable
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates correct RBI file for nested interfaces" do
              add_ruby_file("post.rb", <<~RUBY)
                module A
                  include GraphQL::Schema::Interface
                end

                module B
                  include GraphQL::Schema::Interface
                  implements A
                end

                class Post < GraphQL::Schema::Object
                  implements B
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Post
                  include A
                  include B
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end
          end
        end
      end
    end
  end
end
