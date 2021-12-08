# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveRecordAssociationsSpec < DslSpec
  describe("#initialize") do
    after(:each) do
      T.unsafe(self).assert_no_generated_errors
    end

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

    describe("with relations enabled") do
      subject do
        T.bind(self, DslSpec)
        require "tapioca/compilers/dsl/active_record_relations"
        generator_for_names(target_class_name, "Tapioca::Compilers::Dsl::ActiveRecordRelations")
      end

      describe("without errors") do
        after(:each) do
          T.unsafe(self).assert_no_generated_errors
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
          add_ruby_file("category.rb", <<~RUBY)
            class Category < ActiveRecord::Base
            end
          RUBY

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

        it("generates RBI file for polymorphic has_many association") do
          add_ruby_file("model.rb", <<~RUBY)
            class Picture < ActiveRecord::Base
              belongs_to :imageable, polymorphic: true
            end

            class Employee < ActiveRecord::Base
              has_many :pictures, as: :imageable
            end

            class Product < ActiveRecord::Base
              has_many :pictures, as: :imageable
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Employee
              include GeneratedAssociationMethods

              module GeneratedAssociationMethods
                sig { returns(T::Array[T.untyped]) }
                def picture_ids; end

                sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
                def picture_ids=(ids); end

                sig { returns(ActiveRecord::Associations::CollectionProxy) }
                def pictures; end

                sig { params(value: T::Enumerable[T.untyped]).void }
                def pictures=(value); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Employee))
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
          add_ruby_file("schema.rb", <<~RUBY)
            ActiveRecord::Migration.suppress_messages do
              ActiveRecord::Schema.define do
                create_table :posts do |t|
                end

                create_table :comments do |t|
                end
              end
            end
          RUBY

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

                sig { returns(::Comment::PrivateCollectionProxy) }
                def comments; end

                sig { params(value: T::Enumerable[::Comment]).void }
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

                sig { returns(::Commenter::PrivateCollectionProxy) }
                def commenters; end

                sig { params(value: T::Enumerable[::Commenter]).void }
                def commenters=(value); end

                sig { params(attributes: T.untyped).returns(T.untyped) }
                def commenters_attributes=(attributes); end

                sig { returns(::Comment::PrivateCollectionProxy) }
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
            ActiveRecord::Migration.suppress_messages do
              ActiveRecord::Schema.define do
                create_table :commenters do |t|
                end

                create_table :posts do |t|
                end
              end
            end
          RUBY

          add_ruby_file("commenter.rb", <<~RUBY)
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

                sig { returns(::Commenter::PrivateCollectionProxy) }
                def commenters; end

                sig { params(value: T::Enumerable[::Commenter]).void }
                def commenters=(value); end

                sig { params(attributes: T.untyped).returns(T.untyped) }
                def commenters_attributes=(attributes); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it("generates RBI files for models under different namespaces with associations to each other") do
          add_ruby_file("schema.rb", <<~RUBY)
            ActiveRecord::Migration.suppress_messages do
              ActiveRecord::Schema.define do
                create_table :posts do |t|
                end

                create_table :drafts do |t|
                end

                create_table :authors do |t|
                end

                create_table :comments do |t|
                end
              end
            end
          RUBY

          add_ruby_file("models.rb", <<~RUBY)
            module Blog
              module Core
                class Post < ActiveRecord::Base
                  belongs_to :author
                end
              end

              class Draft < ActiveRecord::Base
                belongs_to :author
              end

              class Author < ActiveRecord::Base
                has_many :comments
                has_many :drafts
              end
            end

            class Comment < ActiveRecord::Base
              belongs_to :post, class_name: "Blog::Core::Post"
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Blog::Core::Post
              include GeneratedAssociationMethods

              module GeneratedAssociationMethods
                sig { returns(T.nilable(::Blog::Author)) }
                def author; end

                sig { params(value: T.nilable(::Blog::Author)).void }
                def author=(value); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Blog::Author) }
                def build_author(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Blog::Author) }
                def create_author(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Blog::Author) }
                def create_author!(*args, &blk); end

                sig { returns(T.nilable(::Blog::Author)) }
                def reload_author; end
              end
            end
          RBI

          assert_equal(expected, rbi_for("Blog::Core::Post"))

          expected = <<~RBI
            # typed: strong

            class Blog::Author
              include GeneratedAssociationMethods

              module GeneratedAssociationMethods
                sig { returns(T::Array[T.untyped]) }
                def comment_ids; end

                sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
                def comment_ids=(ids); end

                sig { returns(::Comment::PrivateCollectionProxy) }
                def comments; end

                sig { params(value: T::Enumerable[::Comment]).void }
                def comments=(value); end

                sig { returns(T::Array[T.untyped]) }
                def draft_ids; end

                sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
                def draft_ids=(ids); end

                sig { returns(::Blog::Draft::PrivateCollectionProxy) }
                def drafts; end

                sig { params(value: T::Enumerable[::Blog::Draft]).void }
                def drafts=(value); end
              end
            end
          RBI

          assert_equal(expected, rbi_for("Blog::Author"))

          expected = <<~RBI
            # typed: strong

            class Comment
              include GeneratedAssociationMethods

              module GeneratedAssociationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(::Blog::Core::Post) }
                def build_post(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Blog::Core::Post) }
                def create_post(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Blog::Core::Post) }
                def create_post!(*args, &blk); end

                sig { returns(T.nilable(::Blog::Core::Post)) }
                def post; end

                sig { params(value: T.nilable(::Blog::Core::Post)).void }
                def post=(value); end

                sig { returns(T.nilable(::Blog::Core::Post)) }
                def reload_post; end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Comment))
        end
      end

      describe("with errors") do
        it("generates RBI file for broken associations") do
          add_ruby_file("schema.rb", <<~RUBY)
            ActiveRecord::Migration.suppress_messages do
              ActiveRecord::Schema.define do
                create_table :posts do |t|
                end
              end
            end
          RUBY

          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
              has_one :author
              has_many :comments
              belongs_to :blog
              has_and_belongs_to_many :commenters
              has_many :readers, through: :author
              has_one :award, through: :blog
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              include GeneratedAssociationMethods

              module GeneratedAssociationMethods; end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))

          assert_equal(6, generated_errors.size)

          # rubocop:disable Layout/LineLength
          expected_errors = [
            "Cannot generate association `has_one :author` on `Post` since the constant `Author` does not exist.",
            "Cannot generate association `has_many :comments` on `Post` since the constant `Comment` does not exist.",
            "Cannot generate association `belongs_to :blog` on `Post` since the constant `Blog` does not exist.",
            "Cannot generate association `has_and_belongs_to_many :commenters` on `Post` since the constant `Commenter` does not exist.",
            "Cannot generate association `has_many :readers, through: :author` on `Post` since the constant `Reader` does not exist.",
            "Cannot generate association `has_one :award, through: :blog` on `Post` since the constant `Award` does not exist.",
          ]
          # rubocop:enable Layout/LineLength

          assert_equal(expected_errors, generated_errors)
        end

        it("generates RBI file for broken has_many :through collection association") do
          add_ruby_file("schema.rb", <<~RUBY)
            ActiveRecord::Migration.suppress_messages do
              ActiveRecord::Schema.define do
                create_table :posts do |t|
                  t.references(:shop)
                end

                create_table :shops do |t|
                end

                create_table :managers do |t|
                  t.references(:shop)
                end
              end
            end
          RUBY

          add_ruby_file("commenter.rb", <<~RUBY)
            class Manager < ActiveRecord::Base
              belongs_to :shop
            end
          RUBY

          add_ruby_file("comment.rb", <<~RUBY)
            class Shop < ActiveRecord::Base
              has_many :managers
            end
          RUBY

          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
              belongs_to :shop
              has_one :manager, through: :shop
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              include GeneratedAssociationMethods

              module GeneratedAssociationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(::Shop) }
                def build_shop(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Shop) }
                def create_shop(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Shop) }
                def create_shop!(*args, &blk); end

                sig { returns(T.nilable(::Shop)) }
                def reload_shop; end

                sig { returns(T.nilable(::Shop)) }
                def shop; end

                sig { params(value: T.nilable(::Shop)).void }
                def shop=(value); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))

          assert_equal(1, generated_errors.size)
          assert_equal(<<~MSG.strip, generated_errors.first)
            Cannot generate association `manager` on `Post` since the source of the through association is missing.
          MSG
        end
      end
    end

    describe("without relations enabled") do
      describe("without errors") do
        after(:each) do
          T.unsafe(self).assert_no_generated_errors
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
          add_ruby_file("category.rb", <<~RUBY)
            class Category < ActiveRecord::Base
            end
          RUBY

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

        it("generates RBI file for polymorphic has_many association") do
          add_ruby_file("model.rb", <<~RUBY)
            class Picture < ActiveRecord::Base
              belongs_to :imageable, polymorphic: true
            end

            class Employee < ActiveRecord::Base
              has_many :pictures, as: :imageable
            end

            class Product < ActiveRecord::Base
              has_many :pictures, as: :imageable
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Employee
              include GeneratedAssociationMethods

              module GeneratedAssociationMethods
                sig { returns(T::Array[T.untyped]) }
                def picture_ids; end

                sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
                def picture_ids=(ids); end

                sig { returns(ActiveRecord::Associations::CollectionProxy[T.untyped]) }
                def pictures; end

                sig { params(value: T::Enumerable[T.untyped]).void }
                def pictures=(value); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Employee))
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
          add_ruby_file("schema.rb", <<~RUBY)
            ActiveRecord::Migration.suppress_messages do
              ActiveRecord::Schema.define do
                create_table :posts do |t|
                end

                create_table :comments do |t|
                end
              end
            end
          RUBY

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

                sig { returns(::ActiveRecord::Associations::CollectionProxy[::Comment]) }
                def comments; end

                sig { params(value: T::Enumerable[::Comment]).void }
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

                sig { returns(::ActiveRecord::Associations::CollectionProxy[::Commenter]) }
                def commenters; end

                sig { params(value: T::Enumerable[::Commenter]).void }
                def commenters=(value); end

                sig { params(attributes: T.untyped).returns(T.untyped) }
                def commenters_attributes=(attributes); end

                sig { returns(::ActiveRecord::Associations::CollectionProxy[::Comment]) }
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
            ActiveRecord::Migration.suppress_messages do
              ActiveRecord::Schema.define do
                create_table :commenters do |t|
                end

                create_table :posts do |t|
                end
              end
            end
          RUBY

          add_ruby_file("commenter.rb", <<~RUBY)
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

                sig { returns(::ActiveRecord::Associations::CollectionProxy[::Commenter]) }
                def commenters; end

                sig { params(value: T::Enumerable[::Commenter]).void }
                def commenters=(value); end

                sig { params(attributes: T.untyped).returns(T.untyped) }
                def commenters_attributes=(attributes); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it("generates RBI files for models under different namespaces with associations to each other") do
          add_ruby_file("schema.rb", <<~RUBY)
            ActiveRecord::Migration.suppress_messages do
              ActiveRecord::Schema.define do
                create_table :posts do |t|
                end

                create_table :drafts do |t|
                end

                create_table :authors do |t|
                end

                create_table :comments do |t|
                end
              end
            end
          RUBY

          add_ruby_file("models.rb", <<~RUBY)
            module Blog
              module Core
                class Post < ActiveRecord::Base
                  belongs_to :author
                end
              end

              class Draft < ActiveRecord::Base
                belongs_to :author
              end

              class Author < ActiveRecord::Base
                has_many :comments
                has_many :drafts
              end
            end

            class Comment < ActiveRecord::Base
              belongs_to :post, class_name: "Blog::Core::Post"
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Blog::Core::Post
              include GeneratedAssociationMethods

              module GeneratedAssociationMethods
                sig { returns(T.nilable(::Blog::Author)) }
                def author; end

                sig { params(value: T.nilable(::Blog::Author)).void }
                def author=(value); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Blog::Author) }
                def build_author(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Blog::Author) }
                def create_author(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Blog::Author) }
                def create_author!(*args, &blk); end

                sig { returns(T.nilable(::Blog::Author)) }
                def reload_author; end
              end
            end
          RBI

          assert_equal(expected, rbi_for("Blog::Core::Post"))

          expected = <<~RBI
            # typed: strong

            class Blog::Author
              include GeneratedAssociationMethods

              module GeneratedAssociationMethods
                sig { returns(T::Array[T.untyped]) }
                def comment_ids; end

                sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
                def comment_ids=(ids); end

                sig { returns(::ActiveRecord::Associations::CollectionProxy[::Comment]) }
                def comments; end

                sig { params(value: T::Enumerable[::Comment]).void }
                def comments=(value); end

                sig { returns(T::Array[T.untyped]) }
                def draft_ids; end

                sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
                def draft_ids=(ids); end

                sig { returns(::ActiveRecord::Associations::CollectionProxy[::Blog::Draft]) }
                def drafts; end

                sig { params(value: T::Enumerable[::Blog::Draft]).void }
                def drafts=(value); end
              end
            end
          RBI

          assert_equal(expected, rbi_for("Blog::Author"))

          expected = <<~RBI
            # typed: strong

            class Comment
              include GeneratedAssociationMethods

              module GeneratedAssociationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(::Blog::Core::Post) }
                def build_post(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Blog::Core::Post) }
                def create_post(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Blog::Core::Post) }
                def create_post!(*args, &blk); end

                sig { returns(T.nilable(::Blog::Core::Post)) }
                def post; end

                sig { params(value: T.nilable(::Blog::Core::Post)).void }
                def post=(value); end

                sig { returns(T.nilable(::Blog::Core::Post)) }
                def reload_post; end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Comment))
        end
      end

      describe("with errors") do
        it("generates RBI file for broken associations") do
          add_ruby_file("schema.rb", <<~RUBY)
            ActiveRecord::Migration.suppress_messages do
              ActiveRecord::Schema.define do
                create_table :posts do |t|
                end
              end
            end
          RUBY

          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
              has_one :author
              has_many :comments
              belongs_to :blog
              has_and_belongs_to_many :commenters
              has_many :readers, through: :author
              has_one :award, through: :blog
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              include GeneratedAssociationMethods

              module GeneratedAssociationMethods; end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))

          assert_equal(6, generated_errors.size)

          # rubocop:disable Layout/LineLength
          expected_errors = [
            "Cannot generate association `has_one :author` on `Post` since the constant `Author` does not exist.",
            "Cannot generate association `has_many :comments` on `Post` since the constant `Comment` does not exist.",
            "Cannot generate association `belongs_to :blog` on `Post` since the constant `Blog` does not exist.",
            "Cannot generate association `has_and_belongs_to_many :commenters` on `Post` since the constant `Commenter` does not exist.",
            "Cannot generate association `has_many :readers, through: :author` on `Post` since the constant `Reader` does not exist.",
            "Cannot generate association `has_one :award, through: :blog` on `Post` since the constant `Award` does not exist.",
          ]
          # rubocop:enable Layout/LineLength

          assert_equal(expected_errors, generated_errors)
        end

        it("generates RBI file for broken has_many :through collection association") do
          add_ruby_file("schema.rb", <<~RUBY)
            ActiveRecord::Migration.suppress_messages do
              ActiveRecord::Schema.define do
                create_table :posts do |t|
                  t.references(:shop)
                end

                create_table :shops do |t|
                end

                create_table :managers do |t|
                  t.references(:shop)
                end
              end
            end
          RUBY

          add_ruby_file("commenter.rb", <<~RUBY)
            class Manager < ActiveRecord::Base
              belongs_to :shop
            end
          RUBY

          add_ruby_file("comment.rb", <<~RUBY)
            class Shop < ActiveRecord::Base
              has_many :managers
            end
          RUBY

          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
              belongs_to :shop
              has_one :manager, through: :shop
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              include GeneratedAssociationMethods

              module GeneratedAssociationMethods
                sig { params(args: T.untyped, blk: T.untyped).returns(::Shop) }
                def build_shop(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Shop) }
                def create_shop(*args, &blk); end

                sig { params(args: T.untyped, blk: T.untyped).returns(::Shop) }
                def create_shop!(*args, &blk); end

                sig { returns(T.nilable(::Shop)) }
                def reload_shop; end

                sig { returns(T.nilable(::Shop)) }
                def shop; end

                sig { params(value: T.nilable(::Shop)).void }
                def shop=(value); end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))

          assert_equal(1, generated_errors.size)
          assert_equal(<<~MSG.strip, generated_errors.first)
            Cannot generate association `manager` on `Post` since the source of the through association is missing.
          MSG
        end
      end
    end
  end

  describe("#decorate_active_storage") do
    subject do
      T.bind(self, DslSpec)
      require "tapioca/compilers/dsl/active_record_relations"
      generator_for_names(target_class_name, "Tapioca::Compilers::Dsl::ActiveRecordRelations")
    end

    before(:each) do
      T.bind(self, Tapioca::Compilers::Dsl::ActiveRecordAssociationsSpec)
      add_ruby_file("application.rb", <<~RUBY)
        ENV["DATABASE_URL"] = "sqlite3::memory:"

        require "active_storage/engine"

        class Dummy < Rails::Application
          config.eager_load = true
          config.active_storage.service = :local
          config.active_storage.service_configurations = {
            local: {
              service: "Disk",
              root: Rails.root.join("storage")
            }
          }
          config.logger = Logger.new('/dev/null')
        end
        Rails.application.initialize!
      RUBY
    end

    after(:each) do
      T.unsafe(self).assert_no_generated_errors
    end

    it("generates RBI file for has_one_attached ActiveStorage association") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          has_one_attached :photo
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include GeneratedAssociationMethods

          module GeneratedAssociationMethods
            sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
            def build_photo_attachment(*args, &blk); end

            sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
            def build_photo_blob(*args, &blk); end

            sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
            def create_photo_attachment(*args, &blk); end

            sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
            def create_photo_attachment!(*args, &blk); end

            sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
            def create_photo_blob(*args, &blk); end

            sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
            def create_photo_blob!(*args, &blk); end

            sig { returns(T.nilable(T.untyped)) }
            def photo_attachment; end

            sig { params(value: T.nilable(T.untyped)).void }
            def photo_attachment=(value); end

            sig { returns(T.nilable(T.untyped)) }
            def photo_blob; end

            sig { params(value: T.nilable(T.untyped)).void }
            def photo_blob=(value); end

            sig { returns(T.nilable(T.untyped)) }
            def reload_photo_attachment; end

            sig { returns(T.nilable(T.untyped)) }
            def reload_photo_blob; end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for has_many_attached ActiveStorage association") do
      add_ruby_file("schema.rb", <<~RUBY)
        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Schema.define do
            create_table :posts do |t|
            end
          end
        end
      RUBY

      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          has_many_attached :photos
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include GeneratedAssociationMethods

          module GeneratedAssociationMethods
            sig { returns(T::Array[T.untyped]) }
            def photos_attachment_ids; end

            sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
            def photos_attachment_ids=(ids); end

            sig { returns(::ActiveStorage::Attachment::PrivateCollectionProxy) }
            def photos_attachments; end

            sig { params(value: T::Enumerable[::ActiveStorage::Attachment]).void }
            def photos_attachments=(value); end

            sig { returns(T::Array[T.untyped]) }
            def photos_blob_ids; end

            sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
            def photos_blob_ids=(ids); end

            sig { returns(::ActiveStorage::Blob::PrivateCollectionProxy) }
            def photos_blobs; end

            sig { params(value: T::Enumerable[::ActiveStorage::Blob]).void }
            def photos_blobs=(value); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end
  end
end
