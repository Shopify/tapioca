# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::IdentityCacheSpec < DslSpec
  describe("Tapioca::Compilers::Dsl::IdentityCache") do
    describe("#initialize") do
      it("gathers no constants if there are no IdentityCache classes") do
        assert_empty(gathered_constants)
      end

      it("gather only IdentityCache classes") do
        add_ruby_file("content.rb", <<~RUBY)
          class Post < ActiveRecord::Base
            include IdentityCache
          end

          class CustomPost < Post
          end

          class Shop < ActiveRecord::Base
          end

          class User
          end
        RUBY

        assert_equal(["CustomPost", "Post"], gathered_constants)
      end

      it("gathers IdentityCache::WithoutPrimaryIndex classes") do
        add_ruby_file("content.rb", <<~RUBY)
          class Post < ActiveRecord::Base
            include IdentityCache::WithoutPrimaryIndex
          end
        RUBY

        assert_equal(["Post"], gathered_constants)
      end
    end

    describe("#decorate") do
      it("generates RBI file for classes with multiple cache_indexes") do
        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveRecord::Base
            include IdentityCache
            cache_index :blog_id
            cache_index :title
          end
        RUBY

        expected = <<~RBI
          # typed: strong
          class Post
            sig { params(blog_id: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
            def self.fetch_by_blog_id(blog_id, includes: nil); end

            sig { params(title: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
            def self.fetch_by_title(title, includes: nil); end

            sig { params(index_values: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
            def self.fetch_multi_by_blog_id(index_values, includes: nil); end

            sig { params(index_values: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
            def self.fetch_multi_by_title(index_values, includes: nil); end
          end
        RBI

        assert_equal(expected, rbi_for(:Post))
      end

      it("generates multiple methods for singled cache_index with unique field") do
        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveRecord::Base
            include IdentityCache
            cache_index :blog_id
            cache_index :title, unique: true
          end
        RUBY

        expected = <<~RBI
          # typed: strong
          class Post
            sig { params(blog_id: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
            def self.fetch_by_blog_id(blog_id, includes: nil); end

            sig { params(title: T.untyped, includes: T.untyped).returns(T.nilable(::Post)) }
            def self.fetch_by_title(title, includes: nil); end

            sig { params(title: T.untyped, includes: T.untyped).returns(::Post) }
            def self.fetch_by_title!(title, includes: nil); end

            sig { params(index_values: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
            def self.fetch_multi_by_blog_id(index_values, includes: nil); end

            sig { params(index_values: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
            def self.fetch_multi_by_title(index_values, includes: nil); end
          end
        RBI

        assert_equal(expected, rbi_for(:Post))
      end

      it("generates methods for combined cache_indexes") do
        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveRecord::Base
            include IdentityCache
            cache_index :title
            cache_index :title, :review_date, unique: true
          end
        RUBY

        expected = <<~RBI
          # typed: strong
          class Post
            sig { params(title: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
            def self.fetch_by_title(title, includes: nil); end

            sig { params(title: T.untyped, review_date: T.untyped, includes: T.untyped).returns(T.nilable(::Post)) }
            def self.fetch_by_title_and_review_date(title, review_date, includes: nil); end

            sig { params(title: T.untyped, review_date: T.untyped, includes: T.untyped).returns(::Post) }
            def self.fetch_by_title_and_review_date!(title, review_date, includes: nil); end

            sig { params(index_values: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
            def self.fetch_multi_by_title(index_values, includes: nil); end
          end
        RBI

        assert_equal(expected, rbi_for(:Post))
      end

      it("generates methods for classes with cache_has_manys index") do
        add_ruby_file("user.rb", <<~RUBY)
          class User < ActiveRecord::Base
          end
        RUBY

        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveRecord::Base
            include IdentityCache
            has_many :users
            cache_has_many :users
          end
        RUBY

        expected = <<~RBI
          # typed: strong
          class Post
            sig { returns(T::Array[T.untyped]) }
            def fetch_user_ids; end

            sig { returns(T::Array[::User]) }
            def fetch_users; end
          end
        RBI

        assert_equal(expected, rbi_for(:Post))
      end

      it("generates methods for classes with cache_has_one index") do
        add_ruby_file("user.rb", <<~RUBY)
          class User < ActiveRecord::Base
          end
        RUBY

        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveRecord::Base
            include IdentityCache
            has_one :user
            cache_has_one :user, embed: :id
          end
        RUBY

        expected = <<~RBI
          # typed: strong
          class Post
            sig { returns(T.nilable(::User)) }
            def fetch_user; end

            sig { returns(T.untyped) }
            def fetch_user_id; end
          end
        RBI

        assert_equal(expected, rbi_for(:Post))
      end

      it("generates methods for classes with cache_belongs_to index on a polymorphic relation") do
        add_ruby_file("user.rb", <<~RUBY)
          class User < ActiveRecord::Base
          end
        RUBY

        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveRecord::Base
            include IdentityCache
            belongs_to :user, polymorphic: true
            cache_belongs_to :user
          end
        RUBY

        expected = <<~RBI
          # typed: strong
          class Post
            sig { returns(T.untyped) }
            def fetch_user; end
          end
        RBI

        assert_equal(expected, rbi_for(:Post))
      end

      it("generates methods for classes with cache_belongs_to index and a simple belong_to") do
        add_ruby_file("user.rb", <<~RUBY)
          class User < ActiveRecord::Base
          end
        RUBY

        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveRecord::Base
            include IdentityCache
            belongs_to :user
            cache_belongs_to :user
          end
        RUBY

        expected = <<~RBI
          # typed: strong
          class Post
            sig { returns(T.nilable(::User)) }
            def fetch_user; end
          end
        RBI

        assert_equal(expected, rbi_for(:Post))
      end
    end
  end
end
