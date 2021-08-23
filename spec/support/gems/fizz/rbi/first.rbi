# typed: true

module Fizz
  class << self
    sig { params(a: T.nilable(Integer)).void }
    def baz(a = T.unsafe(nil)); end
  end
end
