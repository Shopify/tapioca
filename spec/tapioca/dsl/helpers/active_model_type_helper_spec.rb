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

          sig { params(value: T.untyped).returns(Elem) }
          def cast(value)
            super
          end
        end

        describe "type_for" do
          it "discovers custom type from signature on deserialize method" do
            klass = Class.new(ActiveModel::Type::Value) do
              extend T::Sig

              sig { params(value: T.untyped).returns(String) }
              def cast(value)
                super
              end

              sig { params(value: T.untyped).returns(Float) }
              def deserialize(value)
                super
              end

              sig { params(value: Symbol).returns(T.untyped) }
              def serialize(value)
                super
              end

              sig { params(value: T.untyped).returns(Integer) }
              def cast_value(value)
                super
              end
            end

            assert_equal(
              "::Float",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
              "The return type of `deserialize` has the highest priority.",
            )
          end

          it "discovers custom type from signature on cast method" do
            klass = Class.new(ActiveModel::Type::Value) do
              extend T::Sig

              sig { params(value: T.untyped).returns(String) }
              def cast(value)
                super
              end

              sig { params(value: T.untyped).returns(T.untyped) }
              def deserialize(value)
                super
              end

              sig { params(value: Symbol).returns(T.untyped) }
              def serialize(value)
                super
              end

              sig { params(value: T.untyped).returns(Integer) }
              def cast_value(value)
                super
              end
            end

            assert_equal(
              "::String",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
              "The return type of `cast` has second priority.",
            )
          end

          it "discovers custom type from signature on cast_value method" do
            klass = Class.new(ActiveModel::Type::Value) do
              extend T::Sig

              sig { params(value: T.untyped).returns(T.untyped) }
              def cast(value)
                super
              end

              sig { params(value: T.untyped).returns(T.untyped) }
              def deserialize(value)
                super
              end

              sig { params(value: Symbol).returns(T.untyped) }
              def serialize(value)
                super
              end

              sig { params(value: T.untyped).returns(Integer) }
              def cast_value(value)
                super
              end
            end

            assert_equal(
              "::Integer",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
              "The return type of `cast_value` has third priority.",
            )
          end

          it "discovers custom type from signature on serialize method" do
            klass = Class.new(ActiveModel::Type::Value) do
              extend T::Sig

              sig { params(value: T.untyped).returns(T.untyped) }
              def cast(value)
                super
              end

              sig { params(value: T.untyped).returns(T.untyped) }
              def deserialize(value)
                super
              end

              sig { params(value: Symbol).returns(T.untyped) }
              def serialize(value)
                super
              end

              sig { params(value: T.untyped).returns(T.untyped) }
              def cast_value(value)
                super
              end
            end

            assert_equal(
              "::Symbol",
              Tapioca::Dsl::Helpers::ActiveModelTypeHelper.type_for(klass.new),
              "The argument type of `serialize` has fourth priority.",
            )
          end

          it "discovers custom type even if it is not ActiveModel::Type::Value" do
            klass = Class.new do
              extend T::Sig

              sig { params(value: T.untyped).returns(Integer) }
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

              sig { params(value: T.untyped).returns(ValueType[Integer]) }
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

              sig { params(value: T.untyped).returns(T.untyped) }
              def cast(value)
                super
              end

              sig { params(value: T.untyped).returns(T.noreturn) }
              def deserialize(value)
                super
              end

              sig { params(value: T.untyped).returns(T.untyped) }
              def serialize(value)
                super
              end

              sig { params(value: T.untyped).returns(T.untyped) }
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
      end
    end
  end
end
