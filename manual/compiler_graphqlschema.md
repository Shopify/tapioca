## GraphqlSchema

`Tapioca::Dsl::Compilers::GraphqlSchema` generates RBI files for subclasses of
[`GraphQL::Schema`](https://graphql-ruby.org/api-doc/2.1.7/GraphQL/Schema).

For example, with the following `GraphQL::Schema` subclass:

~~~rb
class MySchema> < GraphQL::Schema
  class MyContext < GraphQL::Query::Context; end

  context_class MyContext

  # ...
end
~~~

this compiler will produce the RBI file `my_schema.rbi` with the following content:

~~~rbi
# my_schema.rbi
# typed: true
class MySchema
  sig { returns(MySchema::MyContext) }
  def context; end
end
~~~
