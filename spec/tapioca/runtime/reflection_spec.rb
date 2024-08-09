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

    class SignatureFoo
      extend T::Sig

      sig { returns(String) }
      def good_method
        "Thank you."
      end

      # NOTE: leveraging eval to avoid actual sorbet typechecking
      eval <<~RUBY
        sig do
          raise ArgumentError
        end
        def bad_method
          "oh no..."
        end
      RUBY

      def unknown_method
        ' ¯\_(ツ)_/¯ '
      end
    end

    class ReflectionSpec < Minitest::Spec
      describe Tapioca::Runtime::Reflection do
        it "might return the wrong results without Reflection helpers" do
          foo = LyingFoo.new

          refute_equal([], LyingFoo.constants)
          refute_equal("Tapioca::LyingFoo", LyingFoo.name)
          refute_equal([Object, Kernel, BasicObject], LyingFoo.ancestors)
          refute_equal(Object, LyingFoo.superclass)
          assert_equal(String, LyingFoo.singleton_class)
          assert_equal([:foo, :bar, :baz], LyingFoo.public_instance_methods)
          assert_equal([:foo, :bar, :baz], LyingFoo.protected_instance_methods)
          assert_equal([:foo, :bar, :baz], LyingFoo.private_instance_methods)
          assert_equal(:lies, LyingFoo.method(:class))

          refute_equal(LyingFoo, foo.class)
          assert_equal(1, foo.__id__)
          refute(foo.equal?(foo))
          assert(foo.equal?(1))
        end

        it "return the correct results with Reflection helpers" do
          foo = LyingFoo.new

          assert_equal([], Runtime::Reflection.constants_of(LyingFoo))
          assert_equal("Tapioca::Runtime::LyingFoo", Runtime::Reflection.name_of(LyingFoo))
          assert_equal([Tapioca::Runtime::LyingFoo, Kernel, BasicObject], Runtime::Reflection.ancestors_of(LyingFoo))
          assert_equal(BasicObject, Runtime::Reflection.superclass_of(LyingFoo))
          refute_equal(String, Runtime::Reflection.singleton_class_of(LyingFoo))
          refute_equal([:foo, :bar, :baz], Runtime::Reflection.public_instance_methods_of(LyingFoo))
          refute_equal([:foo, :bar, :baz], Runtime::Reflection.protected_instance_methods_of(LyingFoo))
          refute_equal([:foo, :bar, :baz], Runtime::Reflection.private_instance_methods_of(LyingFoo))

          method = Runtime::Reflection.method_of(LyingFoo, :class)
          assert_equal(:class, method.name)
          assert_instance_of(Method, method)

          assert_equal(LyingFoo, Runtime::Reflection.class_of(foo))
          refute_equal(1, Runtime::Reflection.object_id_of(foo))
          assert(Runtime::Reflection.are_equal?(foo, foo))
          refute(Runtime::Reflection.are_equal?(foo, 1))
        end

        it "returns nil if the class is anonymous" do
          klass = Class.new

          assert_nil(Runtime::Reflection.qualified_name_of(klass))
        end

        it "returns top level anchored name for named class" do
          assert_equal("::Tapioca::Runtime::LyingFoo", Runtime::Reflection.qualified_name_of(LyingFoo))
        end

        describe "signature_for" do
          it "returns a valid signature" do
            method = SignatureFoo.instance_method(:good_method)
            refute_nil(Runtime::Reflection.signature_of(method))
          end

          it "returns nil when a signature is not defined" do
            method = SignatureFoo.instance_method(:unknown_method)
            assert_nil(Runtime::Reflection.signature_of(method))
          end

          it "returns nil when a signature block raises an exception" do
            method = SignatureFoo.instance_method(:bad_method)
            assert_nil(Runtime::Reflection.signature_of(method))
          end
        end

        describe "signature_for!" do
          it "returns a valid signature" do
            method = SignatureFoo.instance_method(:good_method)
            refute_nil(Runtime::Reflection.signature_of!(method))
          end

          it "returns nil when a signature is not defined" do
            method = SignatureFoo.instance_method(:unknown_method)
            assert_nil(Runtime::Reflection.signature_of!(method))
          end

          it "returns nil when a signature block raises an exception" do
            method = SignatureFoo.instance_method(:bad_method)
            assert_raises(ArgumentError) { Runtime::Reflection.signature_of!(method) }
          end
        end
      end
    end
  end
end
