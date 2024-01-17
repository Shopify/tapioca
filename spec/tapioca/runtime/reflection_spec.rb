# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Runtime
    class LyingFoo < BasicObject
      include ::Kernel

      class << self
        def constants
          [::Symbol, ::String]
        end

        def name
          "Foo"
        end

        def singleton_class
          ::String
        end

        def ancestors
          [::Integer, ::String, ::Symbol]
        end

        def superclass
          ::Integer
        end

        def public_instance_methods
          [:foo, :bar, :baz]
        end

        def protected_instance_methods
          [:foo, :bar, :baz]
        end

        def private_instance_methods
          [:foo, :bar, :baz]
        end

        def method(_name)
          :lies
        end
      end

      def class
        ::String
      end

      def __id__
        1
      end

      def equal?(other)
        other == 1
      end
    end
  end
end

describe Tapioca::Runtime::Reflection do
  it "might return the wrong results without Reflection helpers" do
    foo = Tapioca::Runtime::LyingFoo.new

    refute_equal([], Tapioca::Runtime::LyingFoo.constants)
    refute_equal("Tapioca::LyingFoo", Tapioca::Runtime::LyingFoo.name)
    refute_equal([Object, Kernel, BasicObject], Tapioca::Runtime::LyingFoo.ancestors)
    refute_equal(Object, Tapioca::Runtime::LyingFoo.superclass)
    assert_equal(String, Tapioca::Runtime::LyingFoo.singleton_class)
    assert_equal([:foo, :bar, :baz], Tapioca::Runtime::LyingFoo.public_instance_methods)
    assert_equal([:foo, :bar, :baz], Tapioca::Runtime::LyingFoo.protected_instance_methods)
    assert_equal([:foo, :bar, :baz], Tapioca::Runtime::LyingFoo.private_instance_methods)
    assert_equal(:lies, Tapioca::Runtime::LyingFoo.method(:class))

    refute_equal(Tapioca::Runtime::LyingFoo, foo.class)
    assert_equal(1, foo.__id__)
    refute(foo.equal?(foo))
    assert(foo.equal?(1))
  end

  it "return the correct results with Reflection helpers" do
    foo = Tapioca::Runtime::LyingFoo.new

    assert_equal([], Tapioca::Runtime::Reflection.constants_of(Tapioca::Runtime::LyingFoo))
    assert_equal("Tapioca::Runtime::LyingFoo", Tapioca::Runtime::Reflection.name_of(Tapioca::Runtime::LyingFoo))
    assert_equal(
      [Tapioca::Runtime::LyingFoo, Kernel, BasicObject],
      Tapioca::Runtime::Reflection.ancestors_of(Tapioca::Runtime::LyingFoo),
    )
    assert_equal(BasicObject, Tapioca::Runtime::Reflection.superclass_of(Tapioca::Runtime::LyingFoo))
    refute_equal(String, Tapioca::Runtime::Reflection.singleton_class_of(Tapioca::Runtime::LyingFoo))
    refute_equal(
      [:foo, :bar, :baz],
      Tapioca::Runtime::Reflection.public_instance_methods_of(Tapioca::Runtime::LyingFoo),
    )
    refute_equal(
      [:foo, :bar, :baz],
      Tapioca::Runtime::Reflection.protected_instance_methods_of(Tapioca::Runtime::LyingFoo),
    )
    refute_equal(
      [:foo, :bar, :baz],
      Tapioca::Runtime::Reflection.private_instance_methods_of(Tapioca::Runtime::LyingFoo),
    )

    method = Tapioca::Runtime::Reflection.method_of(Tapioca::Runtime::LyingFoo, :class)
    assert_equal(:class, method.name)
    assert_instance_of(Method, method)

    assert_equal(Tapioca::Runtime::LyingFoo, Tapioca::Runtime::Reflection.class_of(foo))
    refute_equal(1, Tapioca::Runtime::Reflection.object_id_of(foo))
    assert(Tapioca::Runtime::Reflection.are_equal?(foo, foo))
    refute(Tapioca::Runtime::Reflection.are_equal?(foo, 1))
  end

  it "returns nil if the class is anonymous" do
    klass = Class.new

    assert_nil(Tapioca::Runtime::Reflection.qualified_name_of(klass))
  end

  it "returns top level anchored name for named class" do
    assert_equal(
      "::Tapioca::Runtime::LyingFoo",
      Tapioca::Runtime::Reflection.qualified_name_of(Tapioca::Runtime::LyingFoo),
    )
  end
end
