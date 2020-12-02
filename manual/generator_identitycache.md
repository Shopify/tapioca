## IdentityCache

`Tapioca::Compilers::DSL::IdentityCache` generates RBI files for Active Record models
 that use `include IdentityCache`.
[`IdentityCache`](https://github.com/Shopify/identity_cache) is a blob level caching solution
to plug into Active Record.

For example, with the following Active Record class:

~~~rb
# post.rb
class Post < ApplicationRecord
   include IdentityCache

   cache_index :blog_id
   cache_index :title, unique: true
   cache_index :title, :review_date, unique: true

end
~~~

this generator will produce the RBI file `post.rbi` with the following content:

~~~rbi
# post.rbi
# typed: true
class Post
  sig { params(blog_id: T.untyped, includes: T.untyped).returns(T::Array[::Post])
  def fetch_by_blog_id(blog_id, includes: nil); end

  sig { params(blog_ids: T.untyped, includes: T.untyped).returns(T::Array[::Post])
  def fetch_multi_by_blog_id(index_values, includes: nil); end

  sig { params(title: T.untyped, includes: T.untyped).returns(::Post) }
  def fetch_by_title!(title, includes: nil); end

  sig { params(title: T.untyped, includes: T.untyped).returns(T.nilable(::Post)) }
  def fetch_by_title(title, includes: nil); end

  sig { params(index_values: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
  def fetch_multi_by_title(index_values, includes: nil); end

  sig { params(title: T.untyped, review_date: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
  def fetch_by_title_and_review_date!(title, review_date, includes: nil); end

  sig { params(title: T.untyped, review_date: T.untyped, includes: T.untyped).returns(T::Array[::Post]) }
  def fetch_by_title_and_review_date(title, review_date, includes: nil); end
end
~~~
