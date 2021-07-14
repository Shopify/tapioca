# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveRecordAssociationsSpec < DslSpec
  describe("#initialize") do
    it("gathers no constants if there are no ActiveRecord subclasses") do
      assert_empty(gathered_constants)
    end

    it("gathers only ActiveRecord subclasses") do
      add_ruby_file("content.rb", <<~RUBY)
        class Post < ActiveRecord::Base
        end

        class Current
        end
      RUBY

      assert_equal(["Post"], gathered_constants)
    end

    it("rejects abstract ActiveRecord subclasses") do
      add_ruby_file("content.rb", <<~RUBY)
        class Comment < ActiveRecord::Base
        end

        class Post < Comment
        end

        class Current < ActiveRecord::Base
          self.abstract_class = true
        end
      RUBY

      assert_equal(["Comment", "Post"], gathered_constants)
    end
  end

  describe("#decorate") do
    before(:each) do
      require "active_record"

      ::ActiveRecord::Base.establish_connection(
        adapter: "sqlite3",
        database: ":memory:"
      )
    end

    it("generates empty RBI file if there are no associations") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
        end
      RUBY

      expected = <<~RBI
        # typed: strong
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for belongs_to single association") do
      add_ruby_file("schema.rb", <<~RUBY)
        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Schema.define do
            create_table :posts do |t|
              t.references(:category, null: true)
              t.references(:author, null: false)
            end
          end
        end
      RUBY

      add_ruby_file("category.rb", <<~RUBY)
        class Category < ActiveRecord::Base
        end
      RUBY

      add_ruby_file("user.rb", <<~RUBY)
        class User < ActiveRecord::Base
        end
      RUBY

      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          belongs_to :category
          belongs_to :author, class_name: "User"

          accepts_nested_attributes_for :category, :author
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include GeneratedAssociationMethods

          module GeneratedAssociationMethods
            sig { returns(T.nilable(::User)) }
            def author; end

            sig { params(value: T.nilable(::User)).void }
            def author=(value); end

            sig { params(attributes: T.untyped).returns(T.untyped) }
            def author_attributes=(attributes); end

            sig { params(args: T.untyped, blk: T.untyped).returns(::User) }
            def build_author(*args, &blk); end

            sig { params(args: T.untyped, blk: T.untyped).returns(::Category) }
            def build_category(*args, &blk); end

            sig { returns(T.nilable(::Category)) }
            def category; end

            sig { params(value: T.nilable(::Category)).void }
            def category=(value); end

            sig { params(attributes: T.untyped).returns(T.untyped) }
            def category_attributes=(attributes); end

            sig { params(args: T.untyped, blk: T.untyped).returns(::User) }
            def create_author(*args, &blk); end

            sig { params(args: T.untyped, blk: T.untyped).returns(::User) }
            def create_author!(*args, &blk); end

            sig { params(args: T.untyped, blk: T.untyped).returns(::Category) }
            def create_category(*args, &blk); end

            sig { params(args: T.untyped, blk: T.untyped).returns(::Category) }
            def create_category!(*args, &blk); end

            sig { returns(T.nilable(::User)) }
            def reload_author; end

            sig { returns(T.nilable(::Category)) }
            def reload_category; end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for polymorphic belongs_to single association") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          belongs_to :category, polymorphic: true

          accepts_nested_attributes_for :category
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include GeneratedAssociationMethods

          module GeneratedAssociationMethods
            sig { returns(T.nilable(T.untyped)) }
            def category; end

            sig { params(value: T.nilable(T.untyped)).void }
            def category=(value); end

            sig { params(attributes: T.untyped).returns(T.untyped) }
            def category_attributes=(attributes); end

            sig { returns(T.nilable(T.untyped)) }
            def reload_category; end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for has_one single association") do
      add_ruby_file("schema.rb", <<~RUBY)
        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Schema.define do
            create_table :posts do |t|
            end
          end
        end
      RUBY

      add_ruby_file("user.rb", <<~RUBY)
        class User
        end
      RUBY

      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          has_one :author, class_name: "User"

          accepts_nested_attributes_for :author
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include GeneratedAssociationMethods

          module GeneratedAssociationMethods
            sig { returns(T.nilable(::User)) }
            def author; end

            sig { params(value: T.nilable(::User)).void }
            def author=(value); end

            sig { params(attributes: T.untyped).returns(T.untyped) }
            def author_attributes=(attributes); end

            sig { params(args: T.untyped, blk: T.untyped).returns(::User) }
            def build_author(*args, &blk); end

            sig { params(args: T.untyped, blk: T.untyped).returns(::User) }
            def create_author(*args, &blk); end

            sig { params(args: T.untyped, blk: T.untyped).returns(::User) }
            def create_author!(*args, &blk); end

            sig { returns(T.nilable(::User)) }
            def reload_author; end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for has_many collection association") do
      add_ruby_file("comment.rb", <<~RUBY)
        class Comment
        end
      RUBY

      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          has_many :comments

          accepts_nested_attributes_for :comments
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include GeneratedAssociationMethods

          module GeneratedAssociationMethods
            sig { returns(T::Array[T.untyped]) }
            def comment_ids; end

            sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
            def comment_ids=(ids); end

            sig { returns(::ActiveRecord::Associations::CollectionProxy[Comment]) }
            def comments; end

            sig { params(value: T::Enumerable[T.untyped]).void }
            def comments=(value); end

            sig { params(attributes: T.untyped).returns(T.untyped) }
            def comments_attributes=(attributes); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for has_many :through collection association") do
      add_ruby_file("schema.rb", <<~RUBY)
        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Schema.define do
            create_table :posts do |t|
            end
          end
        end
      RUBY

      add_ruby_file("commenter.rb", <<~RUBY)
        class Commenter < ActiveRecord::Base
          has_many :comments
          has_many :posts, through: :comments
        end
      RUBY

      add_ruby_file("comment.rb", <<~RUBY)
        class Comment < ActiveRecord::Base
          belongs_to :commenter
          belongs_to :post
        end
      RUBY

      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          has_many :comments
          has_many :commenters, through: :comments

          accepts_nested_attributes_for :commenters
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include GeneratedAssociationMethods

          module GeneratedAssociationMethods
            sig { returns(T::Array[T.untyped]) }
            def comment_ids; end

            sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
            def comment_ids=(ids); end

            sig { returns(T::Array[T.untyped]) }
            def commenter_ids; end

            sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
            def commenter_ids=(ids); end

            sig { returns(::ActiveRecord::Associations::CollectionProxy[Commenter]) }
            def commenters; end

            sig { params(value: T::Enumerable[::Commenter]).void }
            def commenters=(value); end

            sig { params(attributes: T.untyped).returns(T.untyped) }
            def commenters_attributes=(attributes); end

            sig { returns(::ActiveRecord::Associations::CollectionProxy[Comment]) }
            def comments; end

            sig { params(value: T::Enumerable[::Comment]).void }
            def comments=(value); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for has_and_belongs_to_many collection association") do
      add_ruby_file("schema.rb", <<~RUBY)
        class Commenter < ActiveRecord::Base
          has_and_belongs_to_many :posts
        end
      RUBY

      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          has_and_belongs_to_many :commenters

          accepts_nested_attributes_for :commenters
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include GeneratedAssociationMethods

          module GeneratedAssociationMethods
            sig { returns(T::Array[T.untyped]) }
            def commenter_ids; end

            sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
            def commenter_ids=(ids); end

            sig { returns(::ActiveRecord::Associations::CollectionProxy[Commenter]) }
            def commenters; end

            sig { params(value: T::Enumerable[T.untyped]).void }
            def commenters=(value); end

            sig { params(attributes: T.untyped).returns(T.untyped) }
            def commenters_attributes=(attributes); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end
  end
end
