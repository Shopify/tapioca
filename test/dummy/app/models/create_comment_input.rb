class CreateCommentInput < GraphQL::Schema::InputObject
  argument :body, String, required: true
  argument :post_id, ID, required: true
end
