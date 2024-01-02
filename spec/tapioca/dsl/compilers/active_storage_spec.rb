# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveStorageSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveStorage" do
          before do
            Tapioca::RailsSpecHelper.load_active_storage
          end

          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord classes" do
              assert_equal(
                ["ActiveStorage::Attachment", "ActiveStorage::Blob", "ActiveStorage::VariantRecord"],
                gathered_constants,
              )
            end

            it "gathers only ActiveRecord constants with no abstract classes" do
              add_ruby_file("conversation.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end

                class Product < ActiveRecord::Base
                  self.abstract_class = true
                end

                class User
                end
              RUBY

              assert_equal(
                [
                  "ActiveStorage::Attachment",
                  "ActiveStorage::Blob",
                  "ActiveStorage::VariantRecord",
                  "Post",
                ],
                gathered_constants,
              )
            end
          end

          describe "decorate" do
            it "generates an empty RBI file for ActiveRecord classes with no attachment" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates RBI file for ActiveRecord classes with an attachment" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  has_one_attached :photo
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Post
                  sig { returns(ActiveStorage::Attached::One) }
                  def photo; end

                  sig { params(attachable: T.untyped).returns(T.untyped) }
                  def photo=(attachable); end
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates RBI file for ActiveRecord classes with attachments" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  has_many_attached :photos
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Post
                  sig { returns(ActiveStorage::Attached::Many) }
                  def photos; end

                  sig { params(attachable: T.untyped).returns(T.untyped) }
                  def photos=(attachable); end
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
