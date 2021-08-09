# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class LyingFoo < BasicObject
    include ::Kernel

    def class
      ::String
    end

    def self.constants
      [::Symbol, ::String]
    end

    def self.name
      "Foo"
    end

    def self.singleton_class
      ::String
    end

    def self.ancestors
      [::Integer, ::String, ::Symbol]
    end

    def self.superclass
      ::Integer
    end

    def __id__
      1
    end

    def equal?(other)
      other == 1
    end

    def self.public_instance_methods
      [:foo, :bar, :baz]
    end

    def self.protected_instance_methods
      [:foo, :bar, :baz]
    end

    def self.private_instance_methods
      [:foo, :bar, :baz]
    end
  end

  class ReflectionSpec < Minitest::Spec
    describe("reflection methods") do
      it("might return the wrong results without Reflection helpers") do
        foo = LyingFoo.new

        refute_equal([], LyingFoo.constants)
        refute_equal("Tapioca::LyingFoo", LyingFoo.name)
        refute_equal([Object, Kernel, BasicObject], LyingFoo.ancestors)
        refute_equal(Object, LyingFoo.superclass)
        assert_equal(String, LyingFoo.singleton_class)
        assert_equal([:foo, :bar, :baz], LyingFoo.public_instance_methods)
        assert_equal([:foo, :bar, :baz], LyingFoo.protected_instance_methods)
        assert_equal([:foo, :bar, :baz], LyingFoo.private_instance_methods)

        refute_equal(LyingFoo, foo.class)
        assert_equal(1, foo.__id__)
        refute(foo.equal?(foo))
        assert(foo.equal?(1))
      end

      it("return the correct results with Reflection helpers") do
        foo = LyingFoo.new

        assert_equal([], Reflection.constants_of(LyingFoo))
        assert_equal("Tapioca::LyingFoo", Reflection.name_of(LyingFoo))
        assert_equal([Tapioca::LyingFoo, Kernel, BasicObject], Reflection.ancestors_of(LyingFoo))
        assert_equal(BasicObject, Reflection.superclass_of(LyingFoo))
        refute_equal(String, Reflection.singleton_class_of(LyingFoo))
        refute_equal([:foo, :bar, :baz], Reflection.public_instance_methods_of(LyingFoo))
        refute_equal([:foo, :bar, :baz], Reflection.protected_instance_methods_of(LyingFoo))
        refute_equal([:foo, :bar, :baz], Reflection.private_instance_methods_of(LyingFoo))

        assert_equal(LyingFoo, Reflection.class_of(foo))
        refute_equal(1, Reflection.object_id_of(foo))
        assert(Reflection.are_equal?(foo, foo))
        refute(Reflection.are_equal?(foo, 1))
      end
    end

    describe("#qualified_name_of") do
      it("returns nil if the class is anonymous") do
        klass = Class.new

        assert_nil(Reflection.qualified_name_of(klass))
      end

      it("returns top level anchored name for named class") do
        assert_equal("::Tapioca::LyingFoo", Reflection.qualified_name_of(LyingFoo))
      end
    end
  end
end
