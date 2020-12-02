## ActiveRecordTypedStore

`Tapioca::Compilers::DSL::ActiveRecordTypedStore` generates RBI files for Active Record models that use
[`ActiveRecord::TypedStore`](https://github.com/byroot/activerecord-typedstore) features.

For example, with the following ActiveRecord class:

~~~rb
# post.rb
class Post < ApplicationRecord
  typed_store :metadata do |s|
    s.string(:reviewer, blank: false, accessor: false)
    s.date(:review_date)
    s.boolean(:reviewed, null: false, default: false)
  end
end
~~~

this generator will produce the RBI file `post.rbi` with the following content:

~~~rbi
# post.rbi
# typed: true
class Post
  sig { params(review_date: T.nilable(Date)).returns(T.nilable(Date)) }
  def review_date=(review_date); end

  sig { returns(T.nilable(Date)) }
  def review_date; end

  sig { returns(T.nilable(Date)) }
  def review_date_was; end

  sig { returns(T::Boolean) }
  def review_date_changed?; end

  sig { returns(T.nilable(Date)) }
  def review_date_before_last_save; end

  sig { returns(T::Boolean) }
  def saved_change_to_review_date?; end

  sig { returns(T.nilable([T.nilable(Date), T.nilable(Date)])) }
  def review_date_change; end

  sig { returns(T.nilable([T.nilable(Date), T.nilable(Date)])) }
  def saved_change_to_review_date; end

  sig { params(reviewd: T::Boolean).returns(T::Boolean) }
  def reviewed=(reviewed); end

  sig { returns(T::Boolean) }
  def reviewed; end

  sig { returns(T::Boolean) }
  def reviewed_was; end

  sig { returns(T::Boolean) }
  def reviewed_changed?; end

  sig { returns(T::Boolean) }
  def reviewed_before_last_save; end

  sig { returns(T::Boolean) }
  def saved_change_to_reviewed?; end

  sig { returns(T.nilable([T::Boolean, T::Boolean])) }
  def reviewed_change; end

  sig { returns(T.nilable([T::Boolean, T::Boolean])) }
  def saved_change_to_reviewed; end
end
~~~
