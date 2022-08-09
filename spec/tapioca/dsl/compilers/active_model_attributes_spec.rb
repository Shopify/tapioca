# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveModelAttributesSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveModelAttributes" do
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
          end
        end
      end
    end
  end
end
