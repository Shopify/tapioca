# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class JsonApiClientResourceSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::JsonApiClientResource" do
          describe "#initialize" do
            it "gathers no constants if there are no Resource classes" do
              assert_empty(gathered_constants)
            end

            it "gathers only Resource classes" do
              add_ruby_file("content.rb", <<~RUBY)
                class Post < ::JsonApiClient::Resource
                end

                User = Class.new(::JsonApiClient::Resource)

                class Comment
                end
              RUBY

              assert_equal(["Post", "User"], gathered_constants)
            end

            it "ignores Resource classes without a name" do
              add_ruby_file("content.rb", <<~RUBY)
                post = Class.new(::JsonApiClient::Resource)
              RUBY

              assert_empty(gathered_constants)
            end
          end

          describe "#decorate" do
            it "generates empty RBI file if there are no properties" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post < ::JsonApiClient::Resource
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates RBI file for example resource class" do
              add_ruby_file("post.rb", <<~RUBY)
                class User < JsonApiClient::Resource
                  has_many :posts

                  property :name, type: :string
                  property :is_admin, type: :boolean, default: false
                end

                class Post < JsonApiClient::Resource
                  belongs_to :user

                  property :title, type: :string
                end
              RUBY

              assert_equal(<<~RBI, rbi_for(:User))
                # typed: strong

                class User
                  include JsonApiClientResourceGeneratedMethods

                  module JsonApiClientResourceGeneratedMethods
                    sig { returns(T::Boolean) }
                    def is_admin; end

                    sig { params(is_admin: T::Boolean).returns(T::Boolean) }
                    def is_admin=(is_admin); end

                    sig { returns(T.nilable(::String)) }
                    def name; end

                    sig { params(name: T.nilable(::String)).returns(T.nilable(::String)) }
                    def name=(name); end

                    sig { returns(T.nilable(T::Array[Post])) }
                    def posts; end

                    sig { params(posts: T.nilable(T::Array[Post])).returns(T.nilable(T::Array[Post])) }
                    def posts=(posts); end
                  end
                end
              RBI

              assert_equal(<<~RBI, rbi_for(:Post))
                # typed: strong

                class Post
                  include JsonApiClientResourceGeneratedMethods

                  module JsonApiClientResourceGeneratedMethods
                    sig { returns(T.nilable(::String)) }
                    def title; end

                    sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
                    def title=(title); end

                    sig { returns(T.nilable(::String)) }
                    def user_id; end

                    sig { params(user_id: T.nilable(::String)).returns(T.nilable(::String)) }
                    def user_id=(user_id); end
                  end
                end
              RBI
            end

            it "generates properties that have been overridden" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post < JsonApiClient::Resource
                  property :name, type: :string
                  property :title, type: :string

                  protected :name

                  def name
                    "name"
                  end

                  def title
                    "title"
                  end

                  def title=
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Post
                  include JsonApiClientResourceGeneratedMethods

                  module JsonApiClientResourceGeneratedMethods
                    sig { returns(T.nilable(::String)) }
                    def name; end

                    sig { params(name: T.nilable(::String)).returns(T.nilable(::String)) }
                    def name=(name); end

                    sig { returns(T.nilable(::String)) }
                    def title; end

                    sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
                    def title=(title); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "does not generate a method for a broken association" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post < JsonApiClient::Resource
                  belongs_to :user
                end
              RUBY

              # We let the generation raise, the user should not define an association without a corresponding class.
              # The association will be unusable anyway.

              assert_raises(NameError, /uninitialized constant Post::User/) do
                rbi_for(:Post)
              end
            end

            it "generates associations" do
              add_ruby_file("content.rb", <<~RUBY)
                class Image < JsonApiClient::Resource
                  belongs_to :user
                end

                class User < JsonApiClient::Resource
                  has_many :posts
                  has_one :image
                end

                class Post < JsonApiClient::Resource
                  belongs_to :user
                end
              RUBY

              assert_equal(<<~RBI, rbi_for(:Image))
                # typed: strong

                class Image
                  include JsonApiClientResourceGeneratedMethods

                  module JsonApiClientResourceGeneratedMethods
                    sig { returns(T.nilable(::String)) }
                    def user_id; end

                    sig { params(user_id: T.nilable(::String)).returns(T.nilable(::String)) }
                    def user_id=(user_id); end
                  end
                end
              RBI

              assert_equal(<<~RBI, rbi_for(:User))
                # typed: strong

                class User
                  include JsonApiClientResourceGeneratedMethods

                  module JsonApiClientResourceGeneratedMethods
                    sig { returns(T.nilable(Image)) }
                    def image; end

                    sig { params(image: T.nilable(Image)).returns(T.nilable(Image)) }
                    def image=(image); end

                    sig { returns(T.nilable(T::Array[Post])) }
                    def posts; end

                    sig { params(posts: T.nilable(T::Array[Post])).returns(T.nilable(T::Array[Post])) }
                    def posts=(posts); end
                  end
                end
              RBI

              assert_equal(<<~RBI, rbi_for(:Post))
                # typed: strong

                class Post
                  include JsonApiClientResourceGeneratedMethods

                  module JsonApiClientResourceGeneratedMethods
                    sig { returns(T.nilable(::String)) }
                    def user_id; end

                    sig { params(user_id: T.nilable(::String)).returns(T.nilable(::String)) }
                    def user_id=(user_id); end
                  end
                end
              RBI
            end

            it "generates untyped properties" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post < JsonApiClient::Resource
                  property :name
                  property :title, type: :foo
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Post
                  include JsonApiClientResourceGeneratedMethods

                  module JsonApiClientResourceGeneratedMethods
                    sig { returns(T.untyped) }
                    def name; end

                    sig { params(name: T.untyped).returns(T.untyped) }
                    def name=(name); end

                    sig { returns(T.untyped) }
                    def title; end

                    sig { params(title: T.untyped).returns(T.untyped) }
                    def title=(title); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            describe "with custom type" do
              before do
                add_ruby_file("custom_type.rb", <<~RB)
                  class CustomType
                    class << self
                      def cast(value, default)
                        value
                      end
                    end
                  end

                  ::JsonApiClient::Schema::TypeFactory.register({
                    custom_type: CustomType,
                  })
                RB
              end

              it "generates untyped properties for custom types" do
                add_ruby_file("post.rb", <<~RUBY)
                  class Post < JsonApiClient::Resource
                    property :name, type: :custom_type
                  end
                RUBY

                expected = <<~RBI
                  # typed: strong

                  class Post
                    include JsonApiClientResourceGeneratedMethods

                    module JsonApiClientResourceGeneratedMethods
                      sig { returns(T.untyped) }
                      def name; end

                      sig { params(name: T.untyped).returns(T.untyped) }
                      def name=(name); end
                    end
                  end
                RBI

                assert_equal(expected, rbi_for(:Post))
              end

              it "honours types that declare sorbet_type" do
                add_ruby_file("post.rb", <<~RUBY)
                  class CustomType
                    def self.sorbet_type
                      "Integer"
                    end
                  end

                  class Post < JsonApiClient::Resource
                    property :comment_count, type: :custom_type
                    property :tag_count, type: :custom_type, default: 0
                  end
                RUBY

                expected = <<~RBI
                  # typed: strong

                  class Post
                    include JsonApiClientResourceGeneratedMethods

                    module JsonApiClientResourceGeneratedMethods
                      sig { returns(T.nilable(Integer)) }
                      def comment_count; end

                      sig { params(comment_count: T.nilable(Integer)).returns(T.nilable(Integer)) }
                      def comment_count=(comment_count); end

                      sig { returns(Integer) }
                      def tag_count; end

                      sig { params(tag_count: Integer).returns(Integer) }
                      def tag_count=(tag_count); end
                    end
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
end
