## ActiveRecordColumns

`Tapioca::Compilers::Dsl::ActiveRecordColumns` refines RBI files for subclasses of
[`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html).
This compiler is only responsible for defining the attribute methods that would be
created for the columns that are defined in the Active Record model.

For example, with the following model class:
~~~rb
class Post < ActiveRecord::Base
end
~~~

and the following database schema:

~~~rb
# db/schema.rb
create_table :posts do |t|
  t.string :title, null: false
  t.string :body
  t.boolean :published
  t.timestamps
end
~~~

this compiler will produce the following methods in the RBI file
`post.rbi`:

~~~rbi
# post.rbi
# typed: true
class Post
  include GeneratedAttributeMethods

  module GeneratedAttributeMethods
    sig { returns(T.nilable(::String)) }
    def body; end

    sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
    def body=; end

    sig { returns(T::Boolean) }
    def body?; end

    sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
    def created_at; end

    sig { params(value: ::ActiveSupport::TimeWithZone).returns(::ActiveSupport::TimeWithZone) }
    def created_at=; end

    sig { returns(T::Boolean) }
    def created_at?; end

    sig { returns(T.nilable(T::Boolean)) }
    def published; end

    sig { params(value: T::Boolean).returns(T::Boolean) }
    def published=; end

    sig { returns(T::Boolean) }
    def published?; end

    sig { returns(::String) }
    def title; end

    sig { params(value: ::String).returns(::String) }
    def title=(value); end

    sig { returns(T::Boolean) }
    def title?; end

    sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
    def updated_at; end

    sig { params(value: ::ActiveSupport::TimeWithZone).returns(::ActiveSupport::TimeWithZone) }
    def updated_at=; end

    sig { returns(T::Boolean) }
    def updated_at?; end

    ## Also the methods added by https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Dirty.html
    ## Also the methods added by https://api.rubyonrails.org/classes/ActiveModel/Dirty.html
    ## Also the methods added by https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/BeforeTypeCast.html
  end
end
~~~
