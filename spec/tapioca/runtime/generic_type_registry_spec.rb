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
          it "registers a type variable that can be looked up later" do
            not_actually_generic = Class.new

            fake_type_member1 = Tapioca::TypeVariableModule.new(
              not_actually_generic,
              Tapioca::TypeVariableModule::Type::Member,
              :invariant,
              nil,
            )

            fake_type_member2 = Tapioca::TypeVariableModule.new(
              not_actually_generic,
              Tapioca::TypeVariableModule::Type::Member,
              :invariant,
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

        describe ".register_type" do
          it "allows generic interface implementations to be cast to generic interface types" do
            T.let(SampleGenericInterfaceImplementation.new, SampleGenericInterface[Object])
          end

          it "recognizes underlying-type instances via recursively_valid? in composite/T::Props members (issue #2130)" do
            struct_class = T.let(
              Class.new(T::Struct) do
                const :members, T::Hash[Symbol, SampleGenericInterface[Object]]
              end,
              T.untyped,
            )

            instance = struct_class.new(members: { key: SampleGenericInterfaceImplementation.new })

            assert_instance_of(SampleGenericInterfaceImplementation, instance.members.fetch(:key))
          end

          it "recognizes underlying-type instances in a bare T::Props member (issue #2130)" do
            # `T::Props::Private::SetterFactory` takes a `T::Types::Simple` fast path
            # that reads `raw_type` directly and bypasses `valid?`/`recursively_valid?`.
            # A bare generic member (not nested in a composite) exercises that path.
            struct_class = T.let(
              Class.new(T::Struct) do
                const :member, SampleGenericInterface[Object]
              end,
              T.untyped,
            )

            instance = struct_class.new(member: SampleGenericInterfaceImplementation.new)

            assert_instance_of(SampleGenericInterfaceImplementation, instance.member)
          end

          it "does not reuse generic instances for redefined constants with the same name" do
            first_constant, first_generic_type = register_reloadable_generic

            self.class.send(:remove_const, :ReloadableGeneric) # rubocop:disable RSpec/RemoveConst

            second_constant, second_generic_type = register_reloadable_generic

            refute_same(first_generic_type, second_generic_type)
            assert_operator(first_generic_type, :<, first_constant)
            assert_operator(second_generic_type, :<, second_constant)
          ensure
            if self.class.const_defined?(:ReloadableGeneric, false)
              self.class.send(:remove_const, :ReloadableGeneric) # rubocop:disable RSpec/RemoveConst
            end
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
        end
      end

      def register_reloadable_generic
        constant = T.let(Class.new, T.untyped)
        constant.extend(T::Generic)
        constant.const_set(:Element, constant.type_member)

        self.class.const_set(:ReloadableGeneric, constant)
        [constant, constant[Object]]
      end

      class SampleGenericClass
        extend T::Generic

        Element = type_member
      end

      module SampleGenericInterface
        extend T::Generic

        interface!

        Element = type_member
      end

      class SampleGenericInterfaceImplementation
        extend T::Generic

        include SampleGenericInterface

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
    end
  end
end
