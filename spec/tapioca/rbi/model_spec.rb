# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module RBI
    class ModelSpec < Minitest::HooksSpec
      describe("contains RBI nodes") do
        it("shows nodes fully qualified names") do
          mod = RBI::Module.new("Foo")
          assert_equal("::Foo", mod.fully_qualified_name)

          cls1 = RBI::Class.new("Bar")
          mod << cls1
          assert_equal("::Foo::Bar", cls1.fully_qualified_name)

          cls2 = RBI::Class.new("::Bar")
          mod << cls2
          assert_equal("::Bar", cls2.fully_qualified_name)

          singleton_class = RBI::SingletonClass.new
          cls1 << singleton_class
          assert_equal("::Foo::Bar::<self>", singleton_class.fully_qualified_name)

          const = RBI::Const.new("Foo", "42")
          assert_equal("::Foo", const.fully_qualified_name)

          mod << const
          assert_equal("::Foo::Foo", const.fully_qualified_name)

          const2 = RBI::Const.new("Foo::Bar", "42")
          assert_equal("::Foo::Bar", const2.fully_qualified_name)

          mod << const2
          assert_equal("::Foo::Foo::Bar", const2.fully_qualified_name)

          const3 = RBI::Const.new("::Foo::Bar", "42")
          assert_equal("::Foo::Bar", const3.fully_qualified_name)

          mod << const3
          assert_equal("::Foo::Bar", const3.fully_qualified_name)

          m1 = RBI::Method.new("m1")
          assert_equal("#m1", m1.fully_qualified_name)

          mod << m1
          assert_equal("::Foo#m1", m1.fully_qualified_name)

          m2 = RBI::Method.new("m2", is_singleton: true)
          assert_equal("::m2", m2.fully_qualified_name)

          mod << m2
          assert_equal("::Foo::m2", m2.fully_qualified_name)

          a1 = RBI::AttrReader.new(:m1)
          assert_equal(["#m1"], a1.fully_qualified_names)

          a2 = RBI::AttrWriter.new(:m2, :m3)
          mod << a2
          assert_equal(["::Foo#m2=", "::Foo#m3="], a2.fully_qualified_names)

          a3 = RBI::AttrAccessor.new(:m4, :m5)
          mod << a3
          assert_equal(["::Foo#m4", "::Foo#m4=", "::Foo#m5", "::Foo#m5="], a3.fully_qualified_names)

          struct = RBI::TStruct.new("Struct")
          mod << struct
          assert_equal("::Foo::Struct", struct.fully_qualified_name)

          sc = RBI::TStructConst.new("a", "A")
          struct << sc
          assert_equal(["::Foo::Struct#a"], sc.fully_qualified_names)

          sp = RBI::TStructProp.new("b", "B")
          struct << sp
          assert_equal(["::Foo::Struct#b", "::Foo::Struct#b="], sp.fully_qualified_names)

          enum = RBI::TEnum.new("Enum")
          mod << enum
          assert_equal("::Foo::Enum", enum.fully_qualified_name)

          type = RBI::TypeMember.new("T", "type_template")
          mod << type
          assert_equal("::Foo::T", type.fully_qualified_name)
        end
      end
    end
  end
end
