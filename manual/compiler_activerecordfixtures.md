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
  sig { params(fixture_names: Symbol).returns(T.untyped) }
  def posts(*fixture_names); end
end
~~~
