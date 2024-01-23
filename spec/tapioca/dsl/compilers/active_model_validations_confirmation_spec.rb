# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveModelValidationsConfirmationSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveModelValidationsConfirmationSpec" do
          sig { void }
          def before_setup
            require "active_model"
          end

          describe "initialize" do
            it "gathers no constants if there are no classes using ActiveModel::Validations" do
              assert_empty(gathered_constants)
            end

            it "gathers only classes including ActiveModel::Attributes" do
              add_ruby_file("shop.rb", <<~RUBY)
                require "active_record"

                class Shop
                end

                class ShopWithValidations
                  include ActiveModel::Validations
                end

                class ShopWithActiveRecord < ActiveRecord::Base
                end
              RUBY
              assert_equal(["ActiveRecord::Base", "ShopWithActiveRecord", "ShopWithValidations"], gathered_constants)
            end
          end

          describe "decorate" do
            it "does not generate a file when there's no confirm validations" do
              add_ruby_file("shop.rb", <<~RUBY)
                class Shop
                  include ActiveModel::Validations

                  validates :name, presence: true
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:Shop))
            end

            it "generates a method for each confirm validation" do
              add_ruby_file("shop.rb", <<~RUBY)
                class Shop
                  include ActiveModel::Validations

                  validates :name, confirmation: true

                  validates_confirmation_of :password
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Shop
                  sig { returns(T.untyped) }
                  def name_confirmation; end

                  sig { params(name_confirmation: T.untyped).returns(T.untyped) }
                  def name_confirmation=(name_confirmation); end

                  sig { returns(T.untyped) }
                  def password_confirmation; end

                  sig { params(password_confirmation: T.untyped).returns(T.untyped) }
                  def password_confirmation=(password_confirmation); end
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
