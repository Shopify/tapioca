## ActiveRecordEnum

`Tapioca::Dsl::Compilers::ActiveRecordEnum` decorates RBI files for subclasses of
`ActiveRecord::Base` which declare [`enum` fields](https://api.rubyonrails.org/classes/ActiveRecord/Enum.html).

For example, with the following `ActiveRecord::Base` subclass:

~~~rb
class Post < ApplicationRecord
  enum :title_type, %i(book all web), suffix: :title
end
~~~

this compiler will produce the RBI file `post.rbi` with the following content:

~~~rbi
# post.rbi
# typed: true
class Post
  include EnumMethodsModule

  module EnumMethodsModule
    sig { void }
    def all_title!; end

    sig { returns(T::Boolean) }
    def all_title?; end

    sig { returns(T::Hash[T.any(String, Symbol), Integer]) }
    def self.title_types; end

    sig { void }
    def book_title!; end

    sig { returns(T::Boolean) }
    def book_title?; end

    sig { void }
    def web_title!; end

    sig { returns(T::Boolean) }
    def web_title?; end
  end
end
~~~
