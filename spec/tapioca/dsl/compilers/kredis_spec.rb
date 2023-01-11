# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class KredisSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::Kredis" do
          before do
            require "tapioca/dsl/extensions/kredis"
          end

          describe "initialize" do
            it "gathers no constants if there are no classes using Kredis::Attributes" do
              assert_empty(gathered_constants)
            end

            it "gathers only classes include Kredis::Attributes" do
              add_ruby_file("shop.rb", <<~RUBY)
                class Shop
                end

                class Person
                  include Kredis::Attributes
                end
              RUBY
              assert_equal(["Person"], gathered_constants)
            end

            it "gathers Active Model models" do
              add_ruby_file("require.rb", <<~RUBY)
                require "active_model"
                ActiveModel::Model.include(Kredis::Attributes)
              RUBY

              add_ruby_file("person.rb", <<~RUBY)
                class Person
                  include ActiveModel::Model
                end
              RUBY

              assert_equal(["Person"], gathered_constants)
            end

            it "gathers non-abstract Active Record models" do
              add_ruby_file("require.rb", <<~RUBY)
                require "active_record"
                ActiveRecord::Base.include(Kredis::Attributes)
              RUBY

              add_ruby_file("application_record.rb", <<~RUBY)
                class ApplicationRecord < ActiveRecord::Base
                  self.abstract_class = true
                end
              RUBY

              add_ruby_file("person.rb", <<~RUBY)
                class Person < ApplicationRecord
                end
              RUBY

              assert_equal(["Person"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates empty RBI file if there are no attributes in the class" do
              add_ruby_file("person.rb", <<~RUBY)
                class Person
                  include Kredis::Attributes
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:Person))
            end

            it "generates method sigs for every kredis attribute" do
              add_ruby_file("person.rb", <<~RUBY)
                class Person
                  include Kredis::Attributes

                  kredis_string :my_string
                  kredis_integer :my_integer
                  kredis_decimal :my_decimal
                  kredis_float :my_float
                  kredis_datetime :my_datetime
                  kredis_json :my_json
                  kredis_counter :my_counter
                  kredis_flag :my_flag
                  kredis_enum :color, values: %w[red green], default: "green"
                  kredis_enum :shirt_size, values: %w[small medium large], default: "medium"
                  kredis_hash :my_hash
                  kredis_list :my_list
                  kredis_unique_list :my_unique_list
                  kredis_set :my_set
                  kredis_slot :my_slot
                  kredis_slots :my_slots, available: 3
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Person
                  include GeneratedKredisAttributeMethods

                  module GeneratedKredisAttributeMethods
                    sig { returns(PrivateEnumColor) }
                    def color; end

                    sig { returns(Kredis::Types::Counter) }
                    def my_counter; end

                    sig { returns(Kredis::Types::Scalar) }
                    def my_datetime; end

                    sig { returns(Kredis::Types::Scalar) }
                    def my_decimal; end

                    sig { returns(Kredis::Types::Flag) }
                    def my_flag; end

                    sig { returns(T::Boolean) }
                    def my_flag?; end

                    sig { returns(Kredis::Types::Scalar) }
                    def my_float; end

                    sig { returns(Kredis::Types::Hash) }
                    def my_hash; end

                    sig { returns(Kredis::Types::Scalar) }
                    def my_integer; end

                    sig { returns(Kredis::Types::Scalar) }
                    def my_json; end

                    sig { returns(Kredis::Types::List) }
                    def my_list; end

                    sig { returns(Kredis::Types::Set) }
                    def my_set; end

                    sig { returns(Kredis::Types::Slots) }
                    def my_slot; end

                    sig { returns(Kredis::Types::Slots) }
                    def my_slots; end

                    sig { returns(Kredis::Types::Scalar) }
                    def my_string; end

                    sig { returns(Kredis::Types::UniqueList) }
                    def my_unique_list; end

                    sig { returns(PrivateEnumShirtSize) }
                    def shirt_size; end

                    class PrivateEnumColor < Kredis::Types::Enum
                      sig { void }
                      def green!; end

                      sig { returns(T::Boolean) }
                      def green?; end

                      sig { void }
                      def red!; end

                      sig { returns(T::Boolean) }
                      def red?; end
                    end

                    class PrivateEnumShirtSize < Kredis::Types::Enum
                      sig { void }
                      def large!; end

                      sig { returns(T::Boolean) }
                      def large?; end

                      sig { void }
                      def medium!; end

                      sig { returns(T::Boolean) }
                      def medium?; end

                      sig { void }
                      def small!; end

                      sig { returns(T::Boolean) }
                      def small?; end
                    end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Person))
            end
          end
        end
      end
    end
  end
end
