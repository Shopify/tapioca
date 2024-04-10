# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ViewComponentSlotablesSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ViewComponentSlotables" do
          sig { void }
          def before_setup
            require "rails"
            require "view_component"
            require "view_component/slotable"
          end

          describe "initialize" do
            it "gathers no constants if there are no classes using ViewComponent::Slotable" do
              assert_empty(gathered_constants)
            end

            it "gathers classes that include ViewComponent::Slotable" do
              add_ruby_file("component.rb", <<~RUBY)
                class Shop
                end

                class ShopWithInclude
                  include ViewComponent::Slotable
                end

                class ShopComponent < ViewComponent::Base
                end
              RUBY
              assert_equal(["ShopComponent", "ShopWithInclude"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates empty RBI file if there are no slots in the class" do
              add_ruby_file("shop.rb", <<~RUBY)
                class Shop
                  include ViewComponent::Slotable
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Shop; end
              RBI

              assert_equal(expected, rbi_for(:Shop))
            end

            it "generates method sigs for every view component slot" do
              add_ruby_file("shop.rb", <<~RUBY)
                class Shop
                  include ViewComponent::Slotable

                  renders_one :parent
                  renders_many :children
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Shop
                  include ViewComponentSlotablesMethodsModule

                  module ViewComponentSlotablesMethodsModule
                    sig { returns(T::Enumerable[T.untyped]) }
                    def children; end

                    sig { returns(T::Boolean) }
                    def children?; end

                    sig { returns(T.untyped) }
                    def parent; end

                    sig { returns(T::Boolean) }
                    def parent?; end

                    sig { params(args: T.untyped, block: T.untyped).void }
                    def with_children(*args, &block); end

                    sig { params(content: T.untyped).void }
                    def with_children_content(content); end

                    sig { params(args: T.untyped, block: T.untyped).void }
                    def with_parent(*args, &block); end

                    sig { params(content: T.untyped).void }
                    def with_parent_content(content); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Shop))
            end

            it "generates method sigs with param types when type set on slot" do
              add_ruby_file("shop.rb", <<~RUBY)
                class Shop
                  include ViewComponent::Slotable

                  class ParentType < ViewComponent::Base; end

                  renders_one :parent, ParentType
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Shop
                  include ViewComponentSlotablesMethodsModule

                  module ViewComponentSlotablesMethodsModule
                    sig { returns(Shop::ParentType) }
                    def parent; end

                    sig { returns(T::Boolean) }
                    def parent?; end

                    sig { params(args: T.untyped, block: T.untyped).void }
                    def with_parent(*args, &block); end

                    sig { params(content: T.untyped).void }
                    def with_parent_content(content); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Shop))
            end

            it "generates method sigs with param types when type is a proc" do
              add_ruby_file("shop.rb", <<~RUBY)
                class Shop
                  include ViewComponent::Slotable

                  class OtherComponent < ViewComponent::Base; end

                  renders_one :other_component, ->(name:, scheme:, classes:, **options) do
                    OtherComponent.new(name: name, scheme: scheme, classes: classes, **options)
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Shop
                  include ViewComponentSlotablesMethodsModule

                  module ViewComponentSlotablesMethodsModule
                    sig { returns(T.untyped) }
                    def other_component; end

                    sig { returns(T::Boolean) }
                    def other_component?; end

                    sig { params(args: T.untyped, block: T.untyped).void }
                    def with_other_component(*args, &block); end

                    sig { params(content: T.untyped).void }
                    def with_other_component_content(content); end
                  end
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
