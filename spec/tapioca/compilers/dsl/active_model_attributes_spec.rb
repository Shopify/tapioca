# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveModelAttributesSpec < DslSpec
  describe("#initialize") do
    it("gathers no constants if there are no classes using ActiveModel::Attributes") do
      assert_empty(gathered_constants)
    end

    it("gathers only classes including ActiveModel::Attributes") do
      add_ruby_file("shop.rb", <<~RUBY)
        class Shop
        end

        class ShopWithAttributes
          include ActiveModel::Attributes
        end
      RUBY
      assert_equal(["ShopWithAttributes"], gathered_constants)
    end
  end

  describe("#decorate") do
    it("generates empty RBI file if there are no attributes in the class") do
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

    it("generates method sigs for every active model attribute") do
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

    it("generates method sigs with param types when type set on attribute") do
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
          sig { returns(::DateTime) }
          def created_at; end

          sig { params(value: ::DateTime).returns(::DateTime) }
          def created_at=(value); end

          sig { returns(::Integer) }
          def id; end

          sig { params(value: ::Integer).returns(::Integer) }
          def id=(value); end

          sig { returns(::Float) }
          def latitude; end

          sig { params(value: ::Float).returns(::Float) }
          def latitude=(value); end

          sig { returns(::String) }
          def name; end

          sig { params(value: ::String).returns(::String) }
          def name=(value); end

          sig { returns(T::Boolean) }
          def test_shop; end

          sig { params(value: T::Boolean).returns(T::Boolean) }
          def test_shop=(value); end
        end
      RBI

      assert_equal(expected, rbi_for(:Shop))
    end
  end
end
