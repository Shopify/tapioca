## ActiveRecordAssociations

`Tapioca::Dsl::Compilers::ActiveRecordAssociations` refines RBI files for subclasses of
[`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html).
This compiler is only responsible for defining the methods that would be created for the associations that
are defined in the Active Record model.

This compiler accepts a `ActiveRecordAssociationTypes` option that can be used to specify
how the types of `belongs_to` and `has_one` associations should be generated. The option can be one of the
following:
 - `nilable (_default_)`: All association methods will be generated with `T.nilable` return types. This is
 strictly the most correct way to type the methods, but it can make working with the models more cumbersome, as
 you will have to handle the `nil` cases explicitly using `T.must` or the safe navigation operator `&.`, even
 for valid persisted models.
 - `persisted`: The methods will be generated with the type that matches validations on the association. If
 there is a `required: true` or `optional: false`, then the types will be generated as non-nilable. This mode
 basically treats each model as if it was a valid and persisted model. Note that this makes typing Active Record
 models easier, but does not match the behaviour of non-persisted or invalid models, which can have `nil`
 associations.

For example, with the following model class:

~~~rb
class Post < ActiveRecord::Base
  belongs_to :category
  has_many :comments
  has_one :author, class_name: "User", optional: false

  accepts_nested_attributes_for :category, :comments, :author
end
~~~

this compiler will produce, by default, the following methods in the RBI file
`post.rbi`:

~~~rbi
# post.rbi
# typed: true

class Post
  include Post::GeneratedAssociationMethods

  module Post::GeneratedAssociationMethods
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

    sig { void }
    def reset_author; end

    sig { void }
    def reset_category; end
  end
end
~~~
If `ActiveRecordAssociationTypes` is `persisted`, the `author` method will be generated as:
~~~rbi
    sig { returns(::User) }
    def author; end
~~~
and if the option is set to `untyped`, the `author` method will be generated as:
~~~rbi
    sig { returns(T.untyped) }
    def author; end
~~~
