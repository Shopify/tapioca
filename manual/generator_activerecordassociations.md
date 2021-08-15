## ActiveRecordAssociations

`Tapioca::Compilers::Dsl::ActiveRecordAssociations` refines RBI files for subclasses of
[`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html).
This generator is only responsible for defining the methods that would be created for the associations that
are defined in the Active Record model.

For example, with the following model class:

~~~rb
class Post < ActiveRecord::Base
  belongs_to :category
  has_many :comments
  has_one :author, class_name: "User"

  accepts_nested_attributes_for :category, :comments, :author
end
~~~

this generator will produce the following methods in the RBI file
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
  end
end
~~~
