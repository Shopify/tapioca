# typed: false
# frozen_string_literal: true

class Class
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
  def descendants
    ObjectSpace.each_object(singleton_class).reject do |k|
      k.singleton_class? || k == self
    end
  end
end
