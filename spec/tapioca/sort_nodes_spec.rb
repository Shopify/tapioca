# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module RBI
    class SortNodesSpec < Minitest::HooksSpec
      describe("can sort nodes") do
        it("sorts constants") do
          rbi = RBI::Tree.new
          rbi << RBI::Const.new("C", "42")
          rbi << RBI::Const.new("B", "42")
          rbi << RBI::Const.new("A", "42")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            A = 42
            B = 42
            C = 42
          RBI
        end

        it("sorts modules") do
          rbi = RBI::Tree.new
          rbi << RBI::Module.new("C")
          rbi << RBI::Module.new("B")
          rbi << RBI::Module.new("A")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            module A; end
            module B; end
            module C; end
          RBI
        end

        it("sorts classes") do
          rbi = RBI::Tree.new
          rbi << RBI::Class.new("C")
          rbi << RBI::Class.new("B")
          rbi << RBI::Class.new("A")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            class A; end
            class B; end
            class C; end
          RBI
        end

        it("sorts constants and keeps original order in case of conflicts") do
          rbi = RBI::Tree.new
          rbi << RBI::Class.new("B")
          rbi << RBI::Module.new("B")
          rbi << RBI::Const.new("B", "42")
          rbi << RBI::Const.new("A", "42")
          rbi << RBI::Module.new("A")
          rbi << RBI::Class.new("A")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            A = 42
            module A; end
            class A; end
            class B; end
            module B; end
            B = 42
          RBI
        end

        it("sorts methods") do
          rbi = RBI::Tree.new
          rbi << RBI::Method.new("m4")
          rbi << RBI::Method.new("m3", is_singleton: true)
          rbi << RBI::Method.new("m2", is_singleton: true)
          rbi << RBI::Method.new("m1")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            def m1; end
            def m4; end
            def self.m2; end
            def self.m3; end
          RBI
        end

        it("does not sort mixins") do
          rbi = RBI::Tree.new
          rbi << RBI::MixesInClassMethods.new("E")
          rbi << RBI::Extend.new("D")
          rbi << RBI::Include.new("C")
          rbi << RBI::Extend.new("B")
          rbi << RBI::Include.new("A")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            extend D
            include C
            extend B
            include A
            mixes_in_class_methods E
          RBI
        end

        it("sorts helpers") do
          rbi = RBI::Tree.new
          rbi << RBI::Helper.new("c")
          rbi << RBI::Helper.new("b")
          rbi << RBI::Helper.new("a")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            a!
            b!
            c!
          RBI
        end

        it("sorts struct properties") do
          rbi = RBI::Tree.new
          rbi << RBI::TStructConst.new("d", "T")
          rbi << RBI::TStructProp.new("c", "T")
          rbi << RBI::TStructConst.new("b", "T")
          rbi << RBI::TStructProp.new("a", "T")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            prop :a, T
            const :b, T
            prop :c, T
            const :d, T
          RBI
        end

        it("sorts structs") do
          rbi = RBI::Tree.new
          rbi << RBI::TStruct.new("D")
          rbi << RBI::TStruct.new("C")
          rbi << RBI::TStruct.new("B")
          rbi << RBI::TStruct.new("A")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            class A < ::T::Struct; end
            class B < ::T::Struct; end
            class C < ::T::Struct; end
            class D < ::T::Struct; end
          RBI
        end

        it("sorts enums") do
          rbi = RBI::Tree.new
          rbi << RBI::TEnum.new("D")
          rbi << RBI::TEnum.new("C")
          rbi << RBI::TEnum.new("B")
          rbi << RBI::TEnum.new("A")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            class A < ::T::Enum; end
            class B < ::T::Enum; end
            class C < ::T::Enum; end
            class D < ::T::Enum; end
          RBI
        end

        it("does nothing if all nodes are already sorted") do
          rbi = RBI::Tree.new
          rbi << RBI::Extend.new("M4")
          rbi << RBI::Include.new("M3")
          rbi << RBI::Extend.new("M2")
          rbi << RBI::Include.new("M1")
          rbi << RBI::Helper.new("h")
          rbi << RBI::MixesInClassMethods.new("MICM")
          rbi << RBI::TStructProp.new("SP1", "T")
          rbi << RBI::TStructConst.new("SP2", "T")
          rbi << RBI::TStructProp.new("SP3", "T")
          rbi << RBI::TStructConst.new("SP4", "T")
          rbi << RBI::Method.new("m1")
          rbi << RBI::Method.new("m2")
          rbi << RBI::Method.new("m3", is_singleton: true)
          rbi << RBI::Const.new("A", "42")
          rbi << RBI::Module.new("B")
          rbi << RBI::TEnum.new("C")
          rbi << RBI::TStruct.new("D")
          rbi << RBI::Class.new("E")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            extend M4
            include M3
            extend M2
            include M1
            h!
            mixes_in_class_methods MICM
            prop :SP1, T
            const :SP2, T
            prop :SP3, T
            const :SP4, T
            def m1; end
            def m2; end
            def self.m3; end
            A = 42
            module B; end
            class C < ::T::Enum; end
            class D < ::T::Struct; end
            class E; end
          RBI
        end

        it("sorts all nodes in tree") do
          rbi = RBI::Tree.new
          rbi << RBI::Const.new("A", "42")
          rbi << RBI::Extend.new("M4")
          rbi << RBI::Method.new("m1")
          rbi << RBI::MixesInClassMethods.new("MICM")
          rbi << RBI::Module.new("B")
          rbi << RBI::Include.new("M3")
          rbi << RBI::TStructConst.new("SP2", "T")
          rbi << RBI::Method.new("m2")
          rbi << RBI::TStruct.new("D")
          rbi << RBI::TEnum.new("C")
          rbi << RBI::Extend.new("M2")
          rbi << RBI::TStructConst.new("SP4", "T")
          rbi << RBI::Include.new("M1")
          rbi << RBI::Helper.new("h")
          rbi << RBI::Class.new("E")
          rbi << RBI::TStructProp.new("SP1", "T")
          rbi << RBI::Method.new("m3", is_singleton: true)
          rbi << RBI::TStructProp.new("SP3", "T")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            extend M4
            include M3
            extend M2
            include M1
            h!
            mixes_in_class_methods MICM
            prop :SP1, T
            const :SP2, T
            prop :SP3, T
            const :SP4, T
            def m1; end
            def m2; end
            def self.m3; end
            A = 42
            module B; end
            class C < ::T::Enum; end
            class D < ::T::Struct; end
            class E; end
          RBI
        end
      end
    end
  end
end
