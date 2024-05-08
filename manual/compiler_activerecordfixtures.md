## ActiveRecordFixtures

`Tapioca::Dsl::Compilers::ActiveRecordFixtures` decorates RBIs for test fixture methods
that are created dynamically by Rails.

For example, given an application with a posts table, we can have a fixture file

~~~yaml
first_post:
  author: John
  title: My post
~~~

Rails will allow us to invoke `posts(:first_post)` in tests to get the fixture record.
The generated RBI by this compiler will produce the following

~~~rbi
# test_case.rbi
# typed: true
class ActiveSupport::TestCase
  sig { params(fixture_name: NilClass, other_fixtures: NilClass).returns(T::Array[Post]) }
  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: NilClass).returns(Post) }
  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: T.any(String, Symbol))
          .returns(T::Array[Post]) }
  def posts(fixture_name = nil, *other_fixtures); end
end
~~~
