## GraphqlMutation

`Tapioca::Dsl::Compilers::GraphqlMutation` generates RBI files for subclasses of
[`GraphQL::Schema::Mutation`](https://graphql-ruby.org/api-doc/2.0.11/GraphQL/Schema/Mutation).

For example, with the following `GraphQL::Schema::Mutation` subclass:

~~~rb
class CreateComment < GraphQL::Schema::Mutation
  argument :body, String, required: true
  argument :post_id, ID, required: true

  def resolve(body:, post_id:)
    # ...
  end
end
~~~

this compiler will produce the RBI file `notify_user_job.rbi` with the following content:

~~~rbi
# create_comment.rbi
# typed: true
class CreateComment
  sig { params(body: String, post_id: String).returns(T.untyped) }
  def resolve(body:, post_id:); end
end
~~~
