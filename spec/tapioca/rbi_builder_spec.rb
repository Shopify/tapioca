# typed: strict
# frozen_string_literal: true

require "spec_helper"

module RBI
  class BuilderSpec < Minitest::HooksSpec
    describe "Tapioca::RBI" do
      it "builds RBI nodes" do
        rbi = RBI::Tree.new
        rbi.create_class("A")
        rbi.create_module("B")
        rbi.create_constant("C", value: "42")
        rbi.create_include("D")
        rbi.create_extend("E")
        rbi.create_mixes_in_class_methods("F")
        rbi.create_type_variable("G", type: "type_member")
        rbi.create_type_variable("H", type: "type_template", variance: :in, fixed: "Foo")
        rbi.create_method("foo")

        assert_equal(<<~RBI, rbi.string)
          class A; end
          module B; end
          C = 42
          include D
          extend E
          mixes_in_class_methods F
          G = type_member
          H = type_template(:in) { { fixed: Foo } }

          sig { returns(T.untyped) }
          def foo; end
        RBI
      end

      it "builds nodes paths" do
        rbi = RBI::Tree.new
        rbi.create_path(RBI)

        assert_equal(<<~RBI, rbi.string)
          module RBI; end
        RBI
      end

      it "does not build same scope twice" do
        rbi = RBI::Tree.new
        rbi.create_class("A")
        rbi.create_class("A")

        rbi.create_module("B")
        rbi.create_module("B")

        rbi.create_constant("C", value: "42")
        rbi.create_constant("C", value: "11")

        rbi.create_class("X")
        rbi.create_module("X")
        rbi.create_constant("X", value: "42")

        assert_equal(<<~RBI, rbi.string)
          class A; end
          module B; end
          C = 42
          class X; end
        RBI
      end

      it "does not build the same path twice" do
        rbi = RBI::Tree.new
        rbi.create_path(RBI)
        rbi.create_path(RBI)

        assert_equal(<<~RBI, rbi.string)
          module RBI; end
        RBI
      end

      it "does not build the same scope twice but applies blocks" do
        rbi = RBI::Tree.new

        rbi.create_module("A") do |mod|
          mod.create_module("Foo")
        end

        rbi.create_module("A") do |mod|
          mod.create_module("Bar")
        end

        rbi.create_module("A") do |mod|
          mod.create_module("Bar")
        end

        assert_equal(<<~RBI, rbi.string)
          module A
            module Foo; end
            module Bar; end
          end
        RBI
      end

      it "does not build the same path twice but applies blocks" do
        rbi = RBI::Tree.new

        rbi.create_path(RBI) do |mod|
          mod.create_module("Foo")
        end

        rbi.create_path(RBI) do |mod|
          mod.create_module("Bar")
        end

        rbi.create_path(RBI) do |mod|
          mod.create_module("Bar")
        end

        assert_equal(<<~RBI, rbi.string)
          module RBI
            module Foo; end
            module Bar; end
          end
        RBI
      end
    end
  end
end
