# typed: true

module Bar
  class Test
    sig { params(a: T.nilable(Integer), b: T.nilable(Integer)).void }
    def fizz(a = T.unsafe(nil), b = T.unsafe(nil)); end

    sig { params(a: T.nilable(Integer)).void }
    def foo(a = T.unsafe(nil)); end
  end
end
