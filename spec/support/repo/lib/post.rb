# typed: true
# frozen_string_literal: true

class Post
  include SmartProperties
  property :title, accepts: String
end
