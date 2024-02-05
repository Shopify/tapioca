# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveModelAttributesSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveModelAttributes" do
          sig { void }
          def before_setup
            require "active_model"
          end

          describe "initialize" do
            it "gathers no constants if there are no classes using ActiveModel::Attributes" do
              assert_empty(gathered_constants)
            end

            it "gathers only classes including ActiveModel::Attributes" do
              add_ruby_file("shop.rb", <<~RUBY)
                class Shop
                end

                class ShopWithAttributes
                  include ActiveModel::Attributes
                end
              RUBY
              assert_equal(["ShopWithAttributes"], gathered_constants)
            end

            it "does not gather Active Record models" do
              add_ruby_file("post.rb", <<~RUBY)
                require "active_record"

                class Post < ActiveRecord::Base
                end
              RUBY

              assert_equal([], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates empty RBI file if there are no attributes in the class" do
              add_ruby_file("shop.rb", <<~RUBY)
                class Shop
                  include ActiveModel::Attributes
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:Shop))
            end

            it "generates method sigs for every active model attribute" do
              add_ruby_file("shop.rb", <<~RUBY)
                class Shop
                  include ActiveModel::Attributes

                  attribute :name
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Shop
                  sig { returns(T.untyped) }
                  def name; end

                  sig { params(value: T.untyped).returns(T.untyped) }
                  def name=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Shop))
            end

            it "only generates method for Active Model attributes and no other" do
              add_ruby_file("shop.rb", <<~RUBY)
                class Shop
                  include ActiveModel::Attributes
                  include ActiveModel::Dirty

                  attribute :name
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Shop
                  sig { returns(T.untyped) }
                  def name; end

                  sig { params(value: T.untyped).returns(T.untyped) }
                  def name=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Shop))
            end

            it "generates method sigs with param types when type set on attribute" do
              add_ruby_file("shop.rb", <<~RUBY)
                class Shop
                  include ActiveModel::Attributes

                  attribute :id, :integer
                  attribute :name, :string
                  attribute :latitude, :float
                  attribute :created_at, :datetime
                  attribute :test_shop, :boolean
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Shop
                  sig { returns(T.nilable(::Time)) }
                  def created_at; end

                  sig { params(value: T.nilable(::Time)).returns(T.nilable(::Time)) }
                  def created_at=(value); end

                  sig { returns(T.nilable(::Integer)) }
                  def id; end

                  sig { params(value: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
                  def id=(value); end

                  sig { returns(T.nilable(::Float)) }
                  def latitude; end

                  sig { params(value: T.nilable(::Float)).returns(T.nilable(::Float)) }
                  def latitude=(value); end

                  sig { returns(T.nilable(::String)) }
                  def name; end

                  sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                  def name=(value); end

                  sig { returns(T.nilable(T::Boolean)) }
                  def test_shop; end

                  sig { params(value: T.nilable(T::Boolean)).returns(T.nilable(T::Boolean)) }
                  def test_shop=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Shop))
            end

            it "generates method sigs for attribute with type set on attribute is a custom ActiveModel::Type::Value" do
              add_ruby_file("shop.rb", <<~RUBY)
                class CustomWithCastSig < ActiveModel::Type::Value
                  extend T::Sig

                  def type
                    :custom_with_cast_sig
                  end

                  sig { params(value: T.untyped).returns(String) }
                  def cast(value)
                  end

                  sig { params(value: T.untyped).returns(T.untyped) }
                  def deserialize(value)
                  end

                  sig { params(value: Symbol).returns(T.untyped) }
                  def serialize(value)
                  end

                  private

                  sig { params(value: T.untyped).returns(Integer) }
                  def cast_value(value)
                  end
                end

                class CustomWithCastValueSig < ActiveModel::Type::Value
                  extend T::Sig

                  def type
                    :custom_with_cast_value_sig
                  end

                  private

                  sig { params(value: T.untyped).returns(Integer) }
                  def cast_value(value)
                  end
                end

                class CustomWithDeserializeSig < ActiveModel::Type::Value
                  extend T::Sig

                  def type
                    :custom_with_deserialize_sig
                  end

                  sig { params(value: T.untyped).returns(T.nilable(Float)) }
                  def deserialize(value)
                  end
                end

                class CustomWithSerializeSig < ActiveModel::Type::Value
                  extend T::Sig

                  def type
                    :custom_with_serialize_sig
                  end

                  sig { params(value: Symbol).returns(T.untyped) }
                  def serialize(value)
                  end
                end

                class CustomWithoutSig < ActiveModel::Type::Value
                  def type
                    :custom_without_sig
                  end

                  def cast(value)
                  end

                  def deserialize(value)
                  end

                  def serialize(value)
                  end

                  private

                  def cast_value(value)
                  end
                end

                class Shop
                  include ActiveModel::Attributes

                  attribute :custom_with_cast_sig_attr, CustomWithCastSig.new
                  attribute :custom_with_cast_value_sig_attr, CustomWithCastValueSig.new
                  attribute :custom_with_deserialize_sig_attr, CustomWithDeserializeSig.new
                  attribute :custom_with_serialize_sig_attr, CustomWithSerializeSig.new
                  attribute :custom_without_sig_attr, CustomWithoutSig.new
                  attribute :type_value_attr, ActiveModel::Type::Value.new
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Shop
                  sig { returns(T.nilable(::String)) }
                  def custom_with_cast_sig_attr; end

                  sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                  def custom_with_cast_sig_attr=(value); end

                  sig { returns(T.nilable(::Integer)) }
                  def custom_with_cast_value_sig_attr; end

                  sig { params(value: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
                  def custom_with_cast_value_sig_attr=(value); end

                  sig { returns(T.nilable(::Float)) }
                  def custom_with_deserialize_sig_attr; end

                  sig { params(value: T.nilable(::Float)).returns(T.nilable(::Float)) }
                  def custom_with_deserialize_sig_attr=(value); end

                  sig { returns(T.nilable(::Symbol)) }
                  def custom_with_serialize_sig_attr; end

                  sig { params(value: T.nilable(::Symbol)).returns(T.nilable(::Symbol)) }
                  def custom_with_serialize_sig_attr=(value); end

                  sig { returns(T.untyped) }
                  def custom_without_sig_attr; end

                  sig { params(value: T.untyped).returns(T.untyped) }
                  def custom_without_sig_attr=(value); end

                  sig { returns(T.untyped) }
                  def type_value_attr; end

                  sig { params(value: T.untyped).returns(T.untyped) }
                  def type_value_attr=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Shop))
            end

            it "generates method sigs for attribute with custom class not inheriting from ActiveModel::Type::Value" do
              add_ruby_file("shop.rb", <<~RUBY)
                class MyCustomClass
                  extend T::Sig

                  def type
                    :custom
                  end

                  sig { params(value: T.untyped).returns(String) }
                  def cast(value)
                  end
                end

                class Shop
                  include ActiveModel::Attributes

                  attribute :custom_attr, MyCustomClass.new
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Shop
                  sig { returns(T.nilable(::String)) }
                  def custom_attr; end

                  sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                  def custom_attr=(value); end
                end
              RBI

              assert_equal(expected, rbi_for(:Shop))
            end
          end
        end
      end
    end
  end
end
