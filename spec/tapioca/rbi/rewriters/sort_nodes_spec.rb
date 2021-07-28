# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module RBI
    class SortNodesSpec < Minitest::HooksSpec
      describe("can sort nodes") do
        it("sort nodes in tree") do
          rbi = RBI::Tree.new
          rbi << RBI::Const.new("C", "42")
          rbi << RBI::Module.new("S1")
          rbi << RBI::Class.new("S2")
          rbi << RBI::Method.new("m2", is_singleton: true)
          rbi << RBI::Method.new("m3")
          rbi << RBI::Method.new("m1")
          rbi << RBI::Extend.new("E")
          rbi << RBI::Include.new("I")
          rbi << RBI::MixesInClassMethods.new("MICM")
          rbi << RBI::Helper.new("h")
          rbi << RBI::TStructConst.new("SC", "Type")
          rbi << RBI::TStructProp.new("SP", "Type")
          rbi << RBI::TEnum.new("TE")
          rbi << RBI::TStruct.new("TS")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            C = 42
            module S1; end
            class S2; end
            def self.m2; end
            def m3; end
            def m1; end
            extend E
            include I
            mixes_in_class_methods MICM
            h!
            const :SC, Type
            prop :SP, Type
            class TE < ::T::Enum; end
            class TS < ::T::Struct; end
          RBI
        end

        it("sort nodes without mixins in tree") do
          rbi = RBI::Tree.new
          rbi << RBI::Const.new("C", "42")
          rbi << RBI::Module.new("S1")
          rbi << RBI::Class.new("S2")
          rbi << RBI::Method.new("m2", is_singleton: true)
          rbi << RBI::Method.new("m3")
          rbi << RBI::Method.new("m1")
          rbi << RBI::Helper.new("h")
          rbi << RBI::TStructConst.new("SC", "Type")
          rbi << RBI::TStructProp.new("SP", "Type")
          rbi << RBI::TEnum.new("TE")
          rbi << RBI::TStruct.new("TS")

          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            h!
            const :SC, Type
            prop :SP, Type
            def m1; end
            def m3; end
            C = 42
            module S1; end
            class S2; end
            class TE < ::T::Enum; end
            class TS < ::T::Struct; end
            def self.m2; end
          RBI
        end
      end
    end
  end
end
