# frozen_string_literal: true

module Foo
  PI = 3.1415

  def self.bar(a = 1, b: 2, **opts)
    number = opts[:number] || 0
    39 + a + b + number
  end
end
