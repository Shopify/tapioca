## GraphqlInputObject

`Tapioca::Dsl::Compilers::GraphqlInputObject` generates RBI files for subclasses of
[`GraphQL::Schema::InputObject`](https://graphql-ruby.org/api-doc/2.0.11/GraphQL/Schema/InputObject).

For example, with the following `GraphQL::Schema::InputObject` subclass:

~~~rb
class CreateCommentInput < GraphQL::Schema::InputObject
  argument :body, String, required: true
  argument :post_id, ID, required: true
end
~~~

this compiler will produce the RBI file `notify_user_job.rbi` with the following content:

~~~rbi
# create_comment.rbi
# typed: true
class CreateCommentInput
  sig { returns(String) }
  def body; end

  sig { returns(String) }
  def post_id; end
end
~~~
