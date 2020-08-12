# frozen_string_literal: true

module Qux
  PI = 3.1415

  def self.qux(a = 1, b: 2, **opts)
    number = opts[:number] || 0
    39 + a + b + number
  end
end
