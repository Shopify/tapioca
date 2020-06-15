# typed: false
# frozen_string_literal: true

require "spec_helper"

describe("Tapioca::Compilers::Dsl::ActiveRecordAssociations") do
  before(:each) do
    require "tapioca/compilers/dsl/active_record_associations"
  end

  subject do
    Tapioca::Compilers::Dsl::ActiveRecordAssociations.new
  end

  describe("#initialize") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    it("gathers no constants if there are no ActiveRecord subclasses") do
      assert_empty(subject.processable_constants)
    end

    it("gathers only ActiveRecord subclasses") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
        end

        class Current
        end
      RUBY

      assert_equal(constants_from(content), ["Post"])
    end

    it("rejects abstract ActiveRecord subclasses") do
      content = <<~RUBY
        class Comment < ActiveRecord::Base
        end

        class Post < Comment
        end

        class Current < ActiveRecord::Base
          self.abstract_class = true
        end
      RUBY

      assert_equal(constants_from(content), ["Comment", "Post"])
    end
  end

  describe("#decorate") do
    before(:each) do
      ActiveRecord::Base.establish_connection(
        adapter: 'sqlite3',
        database: ':memory:'
      )
    end

    def rbi_for(content)
      with_content(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Post)
        parlour.rbi
      end
    end

    it("generates empty RBI file if there are no associations") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
        end
      RUBY

      expected = <<~RUBY
        # typed: strong

      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for belongs_to single association") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          belongs_to :category
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          include Post::GeneratedAssociationMethods
        end

        module Post::GeneratedAssociationMethods
          sig { params(args: T.untyped, blk: T.untyped).returns(T.nilable(T.untyped)) }
          def build_category(*args, &blk); end

          sig { returns(T.nilable(T.untyped)) }
          def category; end

          sig { params(value: T.nilable(T.untyped)).void }
          def category=(value); end

          sig { params(args: T.untyped, blk: T.untyped).returns(T.nilable(T.untyped)) }
          def create_category(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(T.nilable(T.untyped)) }
          def create_category!(*args, &blk); end

          sig { returns(T.nilable(T.untyped)) }
          def reload_category; end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for polymorphic belongs_to single association") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          belongs_to :category, polymorphic: true
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          include Post::GeneratedAssociationMethods
        end

        module Post::GeneratedAssociationMethods
          sig { returns(T.nilable(T.untyped)) }
          def category; end

          sig { params(value: T.nilable(T.untyped)).void }
          def category=(value); end

          sig { returns(T.nilable(T.untyped)) }
          def reload_category; end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for has_one single association") do
      content = <<~RUBY
        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Schema.define do
            create_table :posts do |t|
            end
          end
        end

        class User
        end

        class Post < ActiveRecord::Base
          has_one :author, class_name: "User"
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          include Post::GeneratedAssociationMethods
        end

        module Post::GeneratedAssociationMethods
          sig { returns(T.nilable(::User)) }
          def author; end

          sig { params(value: T.nilable(::User)).void }
          def author=(value); end

          sig { params(args: T.untyped, blk: T.untyped).returns(T.nilable(::User)) }
          def build_author(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(T.nilable(::User)) }
          def create_author(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(T.nilable(::User)) }
          def create_author!(*args, &blk); end

          sig { returns(T.nilable(::User)) }
          def reload_author; end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for has_many collection association") do
      content = <<~RUBY
        class Comment
        end

        class Post < ActiveRecord::Base
          has_many :comments
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          include Post::GeneratedAssociationMethods
        end

        module Post::GeneratedAssociationMethods
          sig { returns(T::Array[T.untyped]) }
          def comment_ids; end

          sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
          def comment_ids=(ids); end

          sig { returns(::ActiveRecord::Associations::CollectionProxy[Comment]) }
          def comments; end

          sig { params(value: T::Enumerable[T.untyped]).void }
          def comments=(value); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for has_many :through collection association") do
      content = <<~RUBY
        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Schema.define do
            create_table :posts do |t|
            end
          end
        end

        class Commenter < ActiveRecord::Base
          has_many :comments
          has_many :posts, through: :comments
        end

        class Comment < ActiveRecord::Base
          belongs_to :commenter
          belongs_to :post
        end

        class Post < ActiveRecord::Base
          has_many :comments
          has_many :commenters, through: :comments
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          include Post::GeneratedAssociationMethods
        end

        module Post::GeneratedAssociationMethods
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

          sig { returns(::ActiveRecord::Associations::CollectionProxy[Comment]) }
          def comments; end

          sig { params(value: T::Enumerable[::Comment]).void }
          def comments=(value); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for has_and_belongs_to_many collection association") do
      content = <<~RUBY
        class Commenter < ActiveRecord::Base
          has_and_belongs_to_many :posts
        end

        class Post < ActiveRecord::Base
          has_and_belongs_to_many :commenters
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          include Post::GeneratedAssociationMethods
        end

        module Post::GeneratedAssociationMethods
          sig { returns(T::Array[T.untyped]) }
          def commenter_ids; end

          sig { params(ids: T::Array[T.untyped]).returns(T::Array[T.untyped]) }
          def commenter_ids=(ids); end

          sig { returns(::ActiveRecord::Associations::CollectionProxy[Commenter]) }
          def commenters; end

          sig { params(value: T::Enumerable[T.untyped]).void }
          def commenters=(value); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end
  end
end
