## ActiveRecordColumns

`Tapioca::Dsl::Compilers::ActiveRecordColumns` refines RBI files for subclasses of
[`ActiveRecord::Base`](https://api.rubyonrails.org/classes/ActiveRecord/Base.html).
This compiler is only responsible for defining the attribute methods that would be
created for columns and virtual attributes that are defined in the Active Record
model.

This compiler accepts a `ActiveRecordColumnTypes` option that can be used to specify
how the types of the column related methods should be generated. The option can be one of the following:
 - `persisted` (_default_): The methods will be generated with the type that matches the actual database
 column type as the return type. This means that if the column is a string, the method return type
 will be `String`, but if the column is also nullable, then the return type will be `T.nilable(String)`. This
 mode basically treats each model as if it was a valid and persisted model. Note that this makes typing
 Active Record models easier, but does not match the behaviour of non-persisted or invalid models, which can
 have all kinds of non-sensical values in their column attributes.
 - `nilable`: All column methods will be generated with `T.nilable` return types. This is strictly the most
 correct way to type the methods, but it can make working with the models more cumbersome, as you will have to
 handle the `nil` cases explicitly using `T.must` or the safe navigation operator `&.`, even for valid
 persisted models.
 - `untyped`: The methods will be generated with `T.untyped` return types. This mode is practical if you are not
 ready to start typing your models strictly yet, but still want to generate RBI files for them.

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

this compiler will, by default, produce the following methods in the RBI file
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

However, if `ActiveRecordColumnTypes` is set to `nilable`, the `title` method will be generated as:
~~~rbi
    sig { returns(T.nilable(::String)) }
    def title; end
~~~
and if the option is set to `untyped`, the `title` method will be generated as:
~~~rbi
    sig { returns(T.untyped) }
    def title; end
~~~
