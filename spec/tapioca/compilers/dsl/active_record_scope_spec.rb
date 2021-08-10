# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveRecordScopeSpec < DslSpec
  describe("#initialize") do
    it("gathers no constants if there are no ActiveRecord classes") do
      assert_empty(gathered_constants)
    end

    it("gathers only ActiveRecord constants with no abstract classes") do
      add_ruby_file("conversation.rb", <<~RUBY)
        class Post < ActiveRecord::Base
        end

        class Product < ActiveRecord::Base
          self.abstract_class = true
        end

        class User
        end
      RUBY

      assert_equal(["Post"], gathered_constants)
    end
  end

  describe("#decorate") do
    it("generates an empty RBI file for ActiveRecord classes with no scope field") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
        end
      RUBY

      expected = <<~RBI
        # typed: strong
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for ActiveRecord classes with a scope field") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          scope :public_kind, -> { where.not(kind: 'private') }
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          extend GeneratedRelationMethods

          module GeneratedRelationMethods
            sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
            def public_kind(*args, &blk); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for ActiveRecord classes with multiple scope fields") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          scope :public_kind, -> { where.not(kind: 'private') }
          scope :private_kind, -> { where(kind: 'private') }
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          extend GeneratedRelationMethods

          module GeneratedRelationMethods
            sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
            def private_kind(*args, &blk); end

            sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
            def public_kind(*args, &blk); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end
  end

  describe("#decorate_active_storage") do
    before(:each) do
      require "active_record"
      require "active_storage/attached"
      require "active_storage/reflection"
      ActiveRecord::Base.include(ActiveStorage::Attached::Model)
      ActiveRecord::Base.include(ActiveStorage::Reflection::ActiveRecordExtensions)
      ActiveRecord::Reflection.singleton_class.prepend(ActiveStorage::Reflection::ReflectionExtension)
    end

    it("generates RBI file for ActiveRecord classes with has_one_attached scope fields") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          has_one_attached :photo
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          extend GeneratedRelationMethods

          module GeneratedRelationMethods
            sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
            def with_attached_photo(*args, &blk); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for ActiveRecord classes with has_many_attached scope fields") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          has_many_attached :photos
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          extend GeneratedRelationMethods

          module GeneratedRelationMethods
            sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
            def with_attached_photos(*args, &blk); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end
  end
end
