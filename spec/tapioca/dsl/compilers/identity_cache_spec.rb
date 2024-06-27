# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class IdentityCacheSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::IdentityCache" do
          sig { void }
          def before_setup
            require "rails/railtie"
            require "identity_cache"
          end

          describe "initialize" do
            it "gathers no constants if there are no IdentityCache classes" do
              assert_empty(gathered_constants)
            end

            it "gather only IdentityCache classes" do
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

            it "gathers IdentityCache::WithoutPrimaryIndex classes" do
              add_ruby_file("content.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  include IdentityCache::WithoutPrimaryIndex
                end
              RUBY

              assert_equal(["Post"], gathered_constants)
            end
          end

          describe "decorate" do
            before do
              require "active_record"

              ::ActiveRecord::Base.establish_connection(
                adapter: "sqlite3",
                database: ":memory:",
              )
            end

            it "generates RBI file for classes with multiple cache_indexes" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.integer :blog_id
                      t.string :title
                    end
                  end
                end
              RUBY

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
                  class << self
                    sig { params(blog_id: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
                    def fetch_by_blog_id(blog_id, includes: nil); end

                    sig { params(title: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
                    def fetch_by_title(title, includes: nil); end

                    sig { params(blog_id: T.untyped).returns(T::Array[::T.nilable(::Integer)]) }
                    def fetch_id_by_blog_id(blog_id); end

                    sig { params(title: T.untyped).returns(T::Array[::T.nilable(::Integer)]) }
                    def fetch_id_by_title(title); end

                    sig { params(index_values: T::Enumerable[T.untyped], includes: T.untyped).returns(T::Array[::Post]) }
                    def fetch_multi_by_blog_id(index_values, includes: nil); end

                    sig { params(index_values: T::Enumerable[T.untyped], includes: T.untyped).returns(T::Array[::Post]) }
                    def fetch_multi_by_title(index_values, includes: nil); end

                    sig { params(keys: T::Enumerable[T.untyped]).returns(T::Array[::Integer]) }
                    def fetch_multi_id_by_blog_id(keys); end

                    sig { params(keys: T::Enumerable[T.untyped]).returns(T::Array[::Integer]) }
                    def fetch_multi_id_by_title(keys); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates multiple methods for singled cache_index with unique field" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.integer :blog_id
                      t.string :title
                    end
                  end
                end
              RUBY

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
                  class << self
                    sig { params(blog_id: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
                    def fetch_by_blog_id(blog_id, includes: nil); end

                    sig { params(title: T.untyped, includes: T.untyped).returns(T.nilable(::Post)) }
                    def fetch_by_title(title, includes: nil); end

                    sig { params(title: T.untyped, includes: T.untyped).returns(::Post) }
                    def fetch_by_title!(title, includes: nil); end

                    sig { params(blog_id: T.untyped).returns(T::Array[::T.nilable(::Integer)]) }
                    def fetch_id_by_blog_id(blog_id); end

                    sig { params(title: T.untyped).returns(T.nilable(::Integer)) }
                    def fetch_id_by_title(title); end

                    sig { params(index_values: T::Enumerable[T.untyped], includes: T.untyped).returns(T::Array[::Post]) }
                    def fetch_multi_by_blog_id(index_values, includes: nil); end

                    sig { params(index_values: T::Enumerable[T.untyped], includes: T.untyped).returns(T::Array[::Post]) }
                    def fetch_multi_by_title(index_values, includes: nil); end

                    sig { params(keys: T::Enumerable[T.untyped]).returns(T::Array[::Integer]) }
                    def fetch_multi_id_by_blog_id(keys); end

                    sig { params(keys: T::Enumerable[T.untyped]).returns(T::Array[::Integer]) }
                    def fetch_multi_id_by_title(keys); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates multiple methods for cache_index with multiple fields" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.integer :blog_id
                      t.string :title
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  include IdentityCache
                  cache_index :blog_id, :title
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Post
                  class << self
                    sig { params(blog_id: T.untyped, title: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
                    def fetch_by_blog_id_and_title(blog_id, title, includes: nil); end

                    sig { params(blog_id: T.untyped, title: T.untyped).returns(T::Array[::T.nilable(::Integer)]) }
                    def fetch_id_by_blog_id_and_title(blog_id, title); end

                    sig { params(index_values: T::Enumerable[T.untyped], includes: T.untyped).returns(T::Array[::Post]) }
                    def fetch_multi_by_blog_id_and_title(index_values, includes: nil); end

                    sig { params(keys: T::Enumerable[T.untyped]).returns(T::Array[::Integer]) }
                    def fetch_multi_id_by_blog_id_and_title(keys); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates methods for combined cache_indexes" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.string :title
                      t.datetime :review_date
                    end
                  end
                end
              RUBY

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
                  class << self
                    sig { params(title: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
                    def fetch_by_title(title, includes: nil); end

                    sig { params(title: T.untyped, review_date: T.untyped, includes: T.untyped).returns(T.nilable(::Post)) }
                    def fetch_by_title_and_review_date(title, review_date, includes: nil); end

                    sig { params(title: T.untyped, review_date: T.untyped, includes: T.untyped).returns(::Post) }
                    def fetch_by_title_and_review_date!(title, review_date, includes: nil); end

                    sig { params(title: T.untyped).returns(T::Array[::T.nilable(::Integer)]) }
                    def fetch_id_by_title(title); end

                    sig { params(title: T.untyped, review_date: T.untyped).returns(T.nilable(::Integer)) }
                    def fetch_id_by_title_and_review_date(title, review_date); end

                    sig { params(index_values: T::Enumerable[T.untyped], includes: T.untyped).returns(T::Array[::Post]) }
                    def fetch_multi_by_title(index_values, includes: nil); end

                    sig { params(index_values: T::Enumerable[T.untyped], includes: T.untyped).returns(T::Array[::Post]) }
                    def fetch_multi_by_title_and_review_date(index_values, includes: nil); end

                    sig { params(keys: T::Enumerable[T.untyped]).returns(T::Array[::Integer]) }
                    def fetch_multi_id_by_title(keys); end

                    sig { params(keys: T::Enumerable[T.untyped]).returns(T::Array[::Integer]) }
                    def fetch_multi_id_by_title_and_review_date(keys); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates methods for classes with cache_has_manys index" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                    end

                    create_table :users do |t|
                      t.belongs_to :post
                    end
                  end
                end
              RUBY

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

            it "generates methods for classes with cache_has_one index" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                    end

                    create_table :users do |t|
                      t.belongs_to :post
                    end
                  end
                end
              RUBY

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

            it "generates methods for classes with cache_belongs_to index on a polymorphic relation" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.belongs_to :user
                    end

                    create_table :users do |t|
                    end
                  end
                end
              RUBY

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

            it "takes cache aliases into account when generating methods" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.string :author
                    end
                  end
                end
              RUBY

              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                  include IdentityCache

                  cache_attribute :author, by: :id
                  cache_attribute :author, by: [:id, :author]
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Post
                  class << self
                    sig { params(id: T.untyped).returns(T.nilable(::String)) }
                    def fetch_author_by_id(id); end

                    sig { params(id: T.untyped, author: T.untyped).returns(T.nilable(::String)) }
                    def fetch_author_by_id_and_author(id, author); end

                    sig { params(keys: T::Enumerable[T.untyped]).returns(T::Array[::String]) }
                    def fetch_multi_author_by_id(keys); end

                    sig { params(keys: T::Enumerable[T.untyped]).returns(T::Array[::String]) }
                    def fetch_multi_author_by_id_and_author(keys); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates methods for classes with cache_belongs_to index and a simple belong_to" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :posts do |t|
                      t.belongs_to :user
                    end

                    create_table :users do |t|
                    end
                  end
                end
              RUBY

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
    end
  end
end
