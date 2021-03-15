# typed: true
# frozen_string_literal: true

module Namespace
  class Comment
    include SmartProperties
    property! :body, accepts: String
  end
end
