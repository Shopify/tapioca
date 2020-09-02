## ActiveRecordColumns

`Tapioca::Compilers::Dsl::ActiveRecordColumns` refines RBI files for subclasses of `ActiveRecord::Base`
(see https://api.rubyonrails.org/classes/ActiveRecord/Base.html). This generator is only
responsible for defining the attribute methods that would be created for the columns that
are defined in the Active Record model.

**Note:** This generator, by default, generates weak signatures for column methods and treats each
column to be `T.untyped`. This is done on purpose to ensure that the nilability of Active Record
columns do not make it hard for existing code to adopt gradual typing. It is possible, however, to
generate stricter type signatures for your ActiveRecord column types. If your ActiveRecord model extends
a module with name `StrongTypeGeneration`, this generator will generate stricter signatures that follow
closely with the types defined in the schema.

The `StrongTypeGeneration` module you define in your application should add an `after_initialize` callback
to the model and ensure that all the non-nilable attributes of the model are actually initialized with non-`nil`
values.

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

this generator will produce the following methods in the RBI file
`post.rbi`:

~~~rbi
# post.rbi
# typed: true
class Post
  sig { returns(T.nilable(::String)) }
  def body; end

  sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
  def body=; end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def body?; end

  sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
  def created_at; end

  sig { params(value: ::ActiveSupport::TimeWithZone).returns(::ActiveSupport::TimeWithZone) }
  def created_at=; end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def created_at?; end

  sig { returns(T.nilable(T::Boolean)) }
  def published; end

  sig { params(value: T::Boolean).returns(T::Boolean) }
  def published=; end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def published?; end

  sig { returns(::String) }
  def title; end

  sig { params(value: ::String).returns(::String) }
  def title=(value); end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def title?(*args); end

  sig { returns(T.nilable(::ActiveSupport::TimeWithZone)) }
  def updated_at; end

  sig { params(value: ::ActiveSupport::TimeWithZone).returns(::ActiveSupport::TimeWithZone) }
  def updated_at=; end

  sig { params(args: T.untyped).returns(T::Boolean) }
  def updated_at?; end

  ## Also the methods added by https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Dirty.html
  ## Also the methods added by https://api.rubyonrails.org/classes/ActiveModel/Dirty.html
  ## Also the methods added by https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/BeforeTypeCast.html
end
~~~
