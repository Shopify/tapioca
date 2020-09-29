# typed: strict
# frozen_string_literal: true

class Class
  extend T::Sig

  # Returns an array with all classes that are < than its receiver.
  #
  #   class C; end
  #   C.descendants # => []
  #
  #   class B < C; end
  #   C.descendants # => [B]
  #
  #   class A < B; end
  #   C.descendants # => [B, A]
  #
  #   class D < C; end
  #   C.descendants # => [B, A, D]
  sig { returns(T::Array[Class]) }
  def descendants
    result = ObjectSpace.each_object(singleton_class).reject do |k|
      T.cast(k, Module).singleton_class? || k == self
    end

    T.cast(result, T::Array[Class])
  end
end
