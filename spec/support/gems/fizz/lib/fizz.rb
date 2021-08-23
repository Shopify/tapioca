# typed: true
# frozen_string_literal: true

module Fizz
  extend T::Sig

  sig { params(a: Integer, b: Integer).returns(Integer) }
  def self.baz(a = 5, b = 1)
    a - b
  end
end
