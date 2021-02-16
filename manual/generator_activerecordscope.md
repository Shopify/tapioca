## ActiveRecordScope

`Tapioca::Compilers::Dsl::ActiveRecordScope` decorates RBI files for
subclasses of `ActiveRecord::Base` which declare
[`scope` fields](https://api.rubyonrails.org/classes/ActiveRecord/Scoping/Named/ClassMethods.html#method-i-scope).

For example, with the following `ActiveRecord::Base` subclass:

~~~rb
class Post < ApplicationRecord
  scope :public_kind, -> { where.not(kind: 'private') }
  scope :private_kind, -> { where(kind: 'private') }
end
~~~

this generator will produce the RBI file `post.rbi` with the following content:

~~~rbi
# post.rbi
# typed: true
class Post
  extend GeneratedRelationMethods

  class PrivateCollectionProxy
    include GeneratedRelationMethods
  end

  module GeneratedRelationMethods
    sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
    def private_kind(*args, &blk); end

    sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
    def public_kind(*args, &blk); end
  end
end
~~~
