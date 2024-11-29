# frozen_string_literal: true

module Blog
  class Post < ApplicationRecord
    self.table_name = "posts"
  end
end
