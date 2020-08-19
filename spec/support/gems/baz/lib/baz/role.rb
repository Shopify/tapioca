# frozen_string_literal: true

module Baz
  class Role
    include SmartProperties
    property :title, accepts: String
  end
end
