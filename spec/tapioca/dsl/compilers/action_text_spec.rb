# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActionTextSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActionText" do
          before do
            add_ruby_file("require.rb", <<~RUBY)
              require "active_record"
              require "action_text"
              ::ActiveRecord::Base.include(::ActionText::Attribute)
              ::ActiveRecord::Base.prepend(::ActionText::Encryption) if defined?(::ActionText::Encryption)
            RUBY
          end

          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord classes" do
              assert_empty(gathered_constants)
            end

            it "gathers only ActiveRecord constants with rich text" do
              add_ruby_file("conversation.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  has_rich_text :body
                end

                class Product < ActiveRecord::Base
                  self.abstract_class = true
                  has_rich_text :title
                end

                class User
                end
              RUBY

              assert_equal(["Post"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates RBI file for ActiveRecord classes with a rich text" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  has_rich_text :body
                  has_rich_text :title
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Post
                  sig { returns(ActionText::RichText) }
                  def body; end

                  sig { params(value: T.nilable(T.any(ActionText::RichText, String))).returns(T.untyped) }
                  def body=(value); end

                  sig { returns(T::Boolean) }
                  def body?; end

                  sig { returns(ActionText::RichText) }
                  def title; end

                  sig { params(value: T.nilable(T.any(ActionText::RichText, String))).returns(T.untyped) }
                  def title=(value); end

                  sig { returns(T::Boolean) }
                  def title?; end
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates RBI file for ActiveRecord classes with encrypted rich text" do
              skip unless defined?(::ActionText::Encryption)

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  has_rich_text :body, encrypted: true
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Post
                  sig { returns(ActionText::EncryptedRichText) }
                  def body; end

                  sig { params(value: T.nilable(T.any(ActionText::EncryptedRichText, String))).returns(T.untyped) }
                  def body=(value); end

                  sig { returns(T::Boolean) }
                  def body?; end
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
