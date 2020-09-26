# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveRecordScopeSpec < DslSpec
  describe("#initialize") do
    it("gathers no constants if there are no ActiveRecord classes") do
      assert_empty(constants_from(""))
    end

    it("gathers only ActiveRecord constants with no abstract classes") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
        end

        class Product < ActiveRecord::Base
          self.abstract_class = true
        end

        class User
        end
      RUBY

      assert_equal(["Post"], constants_from(content))
    end
  end

  describe("#decorate") do
    it("generates an empty RBI file for ActiveRecord classes with no scope field") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
        end

      RUBY

      expected = <<~RUBY
        # typed: strong

      RUBY

      assert_equal(expected, rbi_for(:Post, content))
    end

    it("generates RBI file for ActiveRecord classes with a scope field") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          scope :public_kind, -> { where.not(kind: 'private') }
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          extend Post::GeneratedRelationMethods
        end

        module Post::GeneratedRelationMethods
          sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
          def public_kind(*args, &blk); end
        end
      RUBY

      assert_equal(expected, rbi_for(:Post, content))
    end

    it("generates RBI file for ActiveRecord classes with multiple scope fields") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          scope :public_kind, -> { where.not(kind: 'private') }
          scope :private_kind, -> { where(kind: 'private') }
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          extend Post::GeneratedRelationMethods
        end

        module Post::GeneratedRelationMethods
          sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
          def private_kind(*args, &blk); end

          sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
          def public_kind(*args, &blk); end
        end
      RUBY

      assert_equal(expected, rbi_for(:Post, content))
    end
  end
end
