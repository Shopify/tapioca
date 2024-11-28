## Kaminari

`Tapioca::Dsl::Compilers::Kaminari` decorates RBI files for models
using Kaminari.

For example, with Kaminari installed and the following `ActiveRecord::Base` subclass:

~~~rb
class Post < ApplicationRecord
end
~~~

This compiler will produce the RBI file `post.rbi` with the following content:

~~~rbi
# post.rbi
# typed: true
class Post
  extend GeneratedRelationMethods

  module GeneratedRelationMethods
    sig do
      params(
        num: T.any(Integer, String)
      ).returns(T.all(PrivateRelation, Kaminari::PageScopeMethods, Kaminari::ActiveRecordRelationMethods))
    end
    def page(num = nil); end
  end
end
~~~
