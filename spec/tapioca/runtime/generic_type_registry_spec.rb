# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Runtime
    class GenericTypeRegistrySpec < Minitest::Spec
      describe Tapioca::Runtime::GenericTypeRegistry do
        describe ".generic_type_instance?" do
          it "returns false for instances of non-generic classes" do
            refute(GenericTypeRegistry.generic_type_instance?(Object.new))
          end

          it "returns true for instances of generic classes" do
            assert(GenericTypeRegistry.generic_type_instance?(SampleGenericClass[Object].new))
          end
        end

        describe ".lookup_type_variables" do
          it "returns nil for non-generic types" do
            assert_nil(GenericTypeRegistry.lookup_type_variables(Object))
          end

          it "returns the type variables for generic types" do
            assert_equal([SampleGenericClass::Element], GenericTypeRegistry.lookup_type_variables(SampleGenericClass))
          end
        end

        describe ".register_type_variable" do
          it " registers a type variable that can be looked up later" do
            not_actually_generic = Class.new

            fake_type_member1 = Tapioca::TypeVariableModule.new(
              not_actually_generic,
              Tapioca::TypeVariableModule::Type::Member,
              :invariant,
              nil,
              nil,
              nil,
              nil,
            )

            fake_type_member2 = Tapioca::TypeVariableModule.new(
              not_actually_generic,
              Tapioca::TypeVariableModule::Type::Member,
              :invariant,
              nil,
              nil,
              nil,
              nil,
            )

            GenericTypeRegistry.register_type_variable(not_actually_generic, fake_type_member1)
            GenericTypeRegistry.register_type_variable(not_actually_generic, fake_type_member2)

            type_variables = T.must(GenericTypeRegistry.lookup_type_variables(not_actually_generic))

            assert_equal([fake_type_member1, fake_type_member2], type_variables)
            # Let's double-check that they're not just equal, but identical:
            assert_same(fake_type_member1, type_variables[0])
            assert_same(fake_type_member2, type_variables[1])
          end
        end

        describe "the patch for .inherited on generic classes" do
          # This is more of an internal detail and cross-cutting concern of all the public APIs,
          # but it's easier to test here on its own.

          it "rescues exceptions that would prevent subclassing" do
            assert_raises(RuntimeError) do # Precondition
              # If not caught by the patch, the error raised from `.inherited` would have blocked our subclassing.
              Class.new(RaisesInInheritedCallback)
            end

            result = RaisesInInheritedCallback[Object] # Should be a distinct subclass
            refute_same(result, RaisesInInheritedCallback)
            assert_operator(result, :<, RaisesInInheritedCallback)
          end

          it "works for classes that specify a 'loose' sig on .inherited" do
            # By "loose", we mean `T::Class[T.anything]` instead of `T::Class[SampleGenericClass[T.anything]]`
            _ = HasNonRecursiveInheritedSig[Object]
          end

          it "works for classes whose .inherited sig reference the generic type itself" do
            # Our swizzled implementation of the `.inherited` method needs to be carefully implemented to not fall into
            # infinite recursion when the sig for the method references the class that it's defined on.
            _ = HasRecursiveInheritedSig[Object]
          end
        end
      end

      class SampleGenericClass
        extend T::Generic

        Element = type_member
      end

      class RaisesInInheritedCallback
        extend T::Generic

        Element = type_member

        class << self
          def inherited(subclass)
            super
            raise "Boom"
          end
        end
      end

      class HasNonRecursiveInheritedSig
        extend T::Generic

        Element = type_member

        class << self
          extend T::Sig

          sig { params(subclass: T::Class[T.anything]).void }
          def inherited(subclass)
            super
          end
        end
      end

      class HasRecursiveInheritedSig
        extend T::Generic

        Element = type_member

        class << self
          extend T::Sig

          # This sig references an instantiation of this class itself.
          sig { params(subclass: T::Class[HasRecursiveInheritedSig[T.anything]]).void }
          def inherited(subclass)
            super
          end
        end
      end
    end
  end
end
