## GraphqlImplements

`Tapioca::Dsl::Compilers::GraphqlImplements` generates RBI files for subclasses of
[`GraphQL::Schema::Object`](https://graphql-ruby.org/api-doc/2.0.11/GraphQL/Schema/Object)
that implement an interface.

For example, with the following `GraphQL::Schema::Object` subclass:

~~~rb
class Post < GraphQL::Schema::Object
  implements Commentable
end
~~~

this compiler will produce the RBI file `post.rbi` with the following content:

~~~rbi
# post.rbi
# typed: true
class Post
  include Commentable
end
~~~
