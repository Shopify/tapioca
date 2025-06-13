# typed: strict
# frozen_string_literal: true

require "spec_helper"
require "active_model"
require "tapioca/dsl/helpers/active_model_type_helper"

module Tapioca
  module Dsl
    module Helpers
      class ActiveModelTypeHelperSpec < Minitest::Spec
        class ValueType
          extend T::Generic

          Elem = type_member
        end

        class CustomWithTypeVariable < ActiveModel::Type::Value
          extend T::Sig
          extend T::Generic

          Elem = type_member

          #: (untyped value) -> Elem
          def cast(value)
            super
          end
        end

        describe "type_for" do
          it "discovers custom type from __tapioca_type method" do
            klass = Class.new(ActiveModel::Type::Value) do
              extend T::Sig

              #: -> untyped
              def __tapioca_type
                T.any(Integer, String)
              end

              #: (untyped value) -> String
              def cast(value)
                super
              end

              #: (untyped value) -> Float
              def deserialize(value)
                super
              end

              #: (Symbol value) -> untyped
              def serialize(value)
                super
              end

              #: (untyped value) -> Integer
              def cast_value(value)
                super
              end
            end

            assert_equal(
              "T.any(::Integer, ::String)",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
              "The type returned from `__tapioca_type` has the highest priority.",
            )
          end

          it "discovers custom type from signature on deserialize method" do
            klass = Class.new(ActiveModel::Type::Value) do
              extend T::Sig

              #: (untyped value) -> String
              def cast(value)
                super
              end

              #: (untyped value) -> Float
              def deserialize(value)
                super
              end

              #: (Symbol value) -> untyped
              def serialize(value)
                super
              end

              #: (untyped value) -> Integer
              def cast_value(value)
                super
              end
            end

            assert_equal(
              "::Float",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
              "The return type of `deserialize` has second priority.",
            )
          end

          it "discovers custom type from signature on cast method" do
            klass = Class.new(ActiveModel::Type::Value) do
              extend T::Sig

              #: (untyped value) -> String
              def cast(value)
                super
              end

              #: (untyped value) -> untyped
              def deserialize(value)
                super
              end

              #: (Symbol value) -> untyped
              def serialize(value)
                super
              end

              #: (untyped value) -> Integer
              def cast_value(value)
                super
              end
            end

            assert_equal(
              "::String",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
              "The return type of `cast` has third priority.",
            )
          end

          it "discovers custom type from signature on cast_value method" do
            klass = Class.new(ActiveModel::Type::Value) do
              extend T::Sig

              #: (untyped value) -> untyped
              def cast(value)
                super
              end

              #: (untyped value) -> untyped
              def deserialize(value)
                super
              end

              #: (Symbol value) -> untyped
              def serialize(value)
                super
              end

              #: (untyped value) -> Integer
              def cast_value(value)
                super
              end
            end

            assert_equal(
              "::Integer",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
              "The return type of `cast_value` has fourth priority.",
            )
          end

          it "discovers custom type from signature on serialize method" do
            klass = Class.new(ActiveModel::Type::Value) do
              extend T::Sig

              #: (untyped value) -> untyped
              def cast(value)
                super
              end

              #: (untyped value) -> untyped
              def deserialize(value)
                super
              end

              #: (Symbol value) -> untyped
              def serialize(value)
                super
              end

              #: (untyped value) -> untyped
              def cast_value(value)
                super
              end
            end

            assert_equal(
              "::Symbol",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
              "The argument type of `serialize` has fifth priority.",
            )
          end

          it "discovers custom type even if it is not ActiveModel::Type::Value" do
            klass = Class.new do
              extend T::Sig

              #: (untyped value) -> Integer
              def cast(value)
              end
            end

            assert_equal(
              "::Integer",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
            )
          end

          it "discovers custom type even if it is generic" do
            klass = Class.new(ActiveModel::Type::Value) do
              extend T::Sig

              #: (untyped value) -> ValueType[Integer]
              def cast(value)
              end
            end

            assert_equal(
              "Tapioca::Dsl::Helpers::ActiveModelTypeHelperSpec::ValueType[::Integer]",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
            )
          end

          it "returns a weak type when the custom column type is a type variable" do
            assert_equal(
              "T.untyped",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(CustomWithTypeVariable[Integer].new),
            )
          end

          it "returns a weak type if custom type cannot be discovered from signatures" do
            klass = Class.new(ActiveModel::Type::Value) do
              extend T::Sig

              #: (untyped value) -> untyped
              def cast(value)
                super
              end

              #: (untyped value) -> bot
              def deserialize(value)
                super
              end

              #: (untyped value) -> untyped
              def serialize(value)
                super
              end

              #: (untyped value) -> untyped
              def cast_value(value)
                super
              end
            end

            assert_equal(
              "T.untyped",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
            )
          end

          it "returns a weak type if custom type does not have any signatures" do
            klass = Class.new(ActiveModel::Type::Value) do
              def cast(value)
                super
              end

              def deserialize(value)
                super
              end

              def serialize(value)
                super
              end

              def cast_value(value)
                super
              end
            end

            assert_equal(
              "T.untyped",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
            )
          end

          it "returns a weak type if custom type does not have any methods" do
            klass = Class.new(ActiveModel::Type::Value)

            assert_equal(
              "T.untyped",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
            )
          end
        end

        describe "assume_nilable?" do
          it "assumes the type is nilable when `#__tapioca_type` is not defined" do
            klass = Class.new(ActiveModel::Type::Value)

            assert_equal(
              true,
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.assume_nilable?(klass.new),
            )
          end

          it "does not assume the type is nilable when `#__tapioca_type` is defined" do
            klass = Class.new(ActiveModel::Type::Value) do
              extend T::Sig

              #: -> Module
              def __tapioca_type = String
            end

            assert_equal(
              false,
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.assume_nilable?(klass.new),
            )
          end
        end
      end
    end
  end
end
