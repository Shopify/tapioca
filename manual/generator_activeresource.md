## ActiveResource

`Tapioca::Compilers::Dsl::ActiveResource` decorates RBI files for subclasses of
[`ActiveResource::Base`](https://github.com/rails/activeresource) which declare
`schema` fields.

For example, with the following `ActiveResource::Base` subclass:

~~~rb
class Post < ActiveResource::Base
  schema do
    integer 'id', 'month', 'year'
  end
end
~~~

this generator will produce the RBI file `post.rbi` with the following content:

~~~rbi
# post.rbi
# typed: true
class Post
  sig { returns(Integer) }
  def id; end

  sig { params(id: Integer).returns(Integer) }
  def id=(id); end

  sig { returns(T::Boolean) }
  def id?; end

  sig { returns(Integer) }
  def month; end

  sig { params(month: Integer).returns(Integer) }
  def month=(month); end

  sig { returns(T::Boolean) }
  def month?; end

  sig { returns(Integer) }
  def year; end

  sig { params(year: Integer).returns(Integer) }
  def year=(year); end

  sig { returns(T::Boolean) }
  def year?; end
end
~~~
