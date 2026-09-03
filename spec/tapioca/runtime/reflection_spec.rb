# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Runtime
    class LyingFoo < BasicObject
      include ::Kernel

      class AttachedClass; end

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

      def __id__ # rubocop:disable Naming/MethodName
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

      sig { params(value: String).returns(String) }
      def wrapped_method(value)
        value
      end
    end

    module UnsignedSignatureWrapper
      def unknown_method(...)
        super
      end

      def wrapped_method(...)
        super
      end
    end

    SignatureFoo.prepend(UnsignedSignatureWrapper)

    module ParentSignatureWrapper
      def inherited_wrapped_method(...)
        super
      end
    end

    class ParentSignatureFoo
      extend T::Sig

      sig { returns(String) }
      def inherited_wrapped_method = "wrapped"

      prepend ParentSignatureWrapper
    end

    module ChildSignatureWrapper
      def inherited_wrapped_method(...)
        super
      end
    end

    class ChildSignatureFoo < ParentSignatureFoo
      prepend ChildSignatureWrapper
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

          assert_equal([:AttachedClass], Runtime::Reflection.constants_of(LyingFoo))
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

        it "returns the right name for attached classes" do
          assert_equal(
            "::Tapioca::Runtime::LyingFoo::AttachedClass",
            Runtime::Reflection.name_of_type(T::Types::Simple.new(LyingFoo::AttachedClass)),
          )
          assert_equal(
            "T.attached_class",
            Runtime::Reflection.name_of_type(T::Types::AttachedClassType.new),
          )
        end

        describe "signature_for" do
          it "returns a valid signature" do
            method = SignatureFoo.instance_method(:good_method)
            refute_nil(Runtime::Reflection.signature_of(method, lookup_from: SignatureFoo))
          end

          it "returns nil when a signature is not defined" do
            method = SignatureFoo.instance_method(:unknown_method)
            calls = []

            signature = T::Utils.stub(:signature_for_method, ->(current_method) do
              calls << current_method
              nil
            end) do
              Runtime::Reflection.signature_of(method, lookup_from: SignatureFoo)
            end

            assert_nil(signature)
            assert_equal([method, method.super_method], calls)
          end

          it "raises when the method was not looked up from lookup_from" do
            other_class = Class.new do
              def good_method; end
            end
            method = SignatureFoo.instance_method(:good_method)

            assert_raises(ArgumentError) do
              Runtime::Reflection.signature_of(method, lookup_from: other_class)
            end
          end

          it "raises when the method was looked up above an ordinary override" do
            parent = Class.new
            parent.class_eval <<~RUBY
              def overridden_method(value)
                value
              end
            RUBY
            child = Class.new(parent)
            child.class_eval <<~RUBY
              def overridden_method(value, suffix)
                value
              end
            RUBY
            method = parent.instance_method(:overridden_method)

            assert_raises(ArgumentError) do
              Runtime::Reflection.signature_of(method, lookup_from: child)
            end
          end

          it "does not inspect ancestors for a directly owned unsigned method" do
            klass = Class.new do
              def unsigned_method; end
            end
            method = klass.instance_method(:unsigned_method)

            Runtime::Reflection.stub(:ancestors_of, ->(_) { flunk("inspected ancestors") }) do
              assert_nil(Runtime::Reflection.signature_of(method, lookup_from: klass))
            end
          end

          it "returns a signature from a super method when a prepended method has none" do
            method = SignatureFoo.instance_method(:wrapped_method)
            signature = Runtime::Reflection.signature_of(method, lookup_from: SignatureFoo)

            refute_nil(signature)
            assert_equal("::String", signature.return_type.to_s)
          end

          it "returns an inherited signature hidden by prepended methods on both classes" do
            method = ChildSignatureFoo.instance_method(:inherited_wrapped_method)
            signature = Runtime::Reflection.signature_of(method, lookup_from: ChildSignatureFoo)

            refute_nil(signature)
            assert_equal(ParentSignatureFoo, signature.method.owner)
            assert_equal("::String", signature.return_type.to_s)
          end

          it "does not return an inherited signature for an unsigned override" do
            parent = Class.new
            parent.class_eval <<~RUBY
              extend T::Sig

              sig { params(value: String).returns(String) }
              def overridden_method(value)
                value
              end
            RUBY
            child = Class.new(parent)
            child.class_eval <<~RUBY
              def overridden_method(value, suffix)
                value
              end
            RUBY
            method = child.instance_method(:overridden_method)

            assert_nil(Runtime::Reflection.signature_of(method, lookup_from: child))
          end

          it "does not return an inherited signature through an included method" do
            parent = Class.new
            parent.class_eval <<~RUBY
              extend T::Sig

              sig { params(value: String).returns(String) }
              def included_method(value)
                value
              end
            RUBY
            implementation = Module.new do
              def included_method(value)
                value
              end
            end
            child = Class.new(parent)
            child.include(implementation)
            method = child.instance_method(:included_method)

            assert_nil(Runtime::Reflection.signature_of(method, lookup_from: child))
          end

          it "returns a signature through a module prepended to a singleton class" do
            klass = Class.new
            klass.class_eval <<~RUBY
              extend T::Sig

              sig { params(value: String).returns(String) }
              def self.singleton_wrapped_method(value)
                value
              end
            RUBY
            wrapper = Module.new do
              def singleton_wrapped_method(...)
                super
              end
            end
            klass.singleton_class.prepend(wrapper)
            method = klass.method(:singleton_wrapped_method)

            signature = Runtime::Reflection.signature_of(method, lookup_from: klass)

            refute_nil(signature)
            assert_equal(klass.singleton_class, signature.method.owner)
            assert_equal("::String", signature.return_type.to_s)
          end

          it "returns nil when a signature block raises an exception" do
            method = SignatureFoo.instance_method(:bad_method)
            assert_nil(Runtime::Reflection.signature_of(method, lookup_from: SignatureFoo))
          end
        end

        describe "signature_for!" do
          it "returns a valid signature" do
            method = SignatureFoo.instance_method(:good_method)
            refute_nil(Runtime::Reflection.signature_of!(method, lookup_from: SignatureFoo))
          end

          it "returns nil when a signature is not defined" do
            method = SignatureFoo.instance_method(:unknown_method)
            assert_nil(Runtime::Reflection.signature_of!(method, lookup_from: SignatureFoo))
          end

          it "returns nil when a signature block raises an exception" do
            method = SignatureFoo.instance_method(:bad_method)
            assert_raises(Tapioca::Runtime::Reflection::SignatureBlockError) do
              Runtime::Reflection.signature_of!(method, lookup_from: SignatureFoo)
            end
          end
        end
      end
    end
  end
end
