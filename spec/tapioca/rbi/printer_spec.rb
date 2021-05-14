# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module RBI
    class PrinterSpec < Minitest::HooksSpec
      describe("build rbi") do
        it("builds modules and classes") do
          rbi = RBI::Tree.new
          rbi << RBI::Module.new("Foo")
          rbi << RBI::Class.new("Bar")
          rbi << RBI::Class.new("Baz", superclass_name: "Bar")
          rbi << RBI::SingletonClass.new

          assert_equal(<<~RBI, rbi.string)
            module Foo; end
            class Bar; end
            class Baz < Bar; end
            class << self; end
          RBI
        end

        it("builds nested scopes") do
          scope1 = RBI::Module.new("Foo")
          scope2 = RBI::Class.new("Bar")
          scope3 = RBI::Class.new("Baz", superclass_name: "Bar")
          scope4 = RBI::SingletonClass.new

          rbi = RBI::Tree.new
          rbi << scope1
          scope1 << scope2
          scope2 << scope3
          scope3 << scope4

          assert_equal(<<~RBI, rbi.string)
            module Foo
              class Bar
                class Baz < Bar
                  class << self; end
                end
              end
            end
          RBI
        end

        it("builds constants") do
          rbi = RBI::Tree.new
          rbi << RBI::Const.new("Foo", "42")
          rbi << RBI::Const.new("Bar", "'foo'")
          rbi << RBI::Const.new("Baz", "Bar")

          assert_equal(<<~RBI, rbi.string)
            Foo = 42
            Bar = 'foo'
            Baz = Bar
          RBI
        end

        it("builds methods") do
          rbi = RBI::Tree.new
          rbi << RBI::Method.new("m1")
          rbi << RBI::Method.new("m2", visibility: Visibility::Public)
          rbi << RBI::Method.new("m3", visibility: Visibility::Private)
          rbi << RBI::Method.new("m4", visibility: Visibility::Protected)
          rbi << RBI::Method.new("m5", is_singleton: true)
          rbi << RBI::Method.new("m6", is_singleton: true, visibility: Visibility::Private) # TODO: avoid this?

          assert_equal(<<~RBI, rbi.string)
            def m1; end
            def m2; end
            private def m3; end
            protected def m4; end
            def self.m5; end
            private def self.m6; end
          RBI
        end

        it("builds methods with parameters") do
          method = RBI::Method.new("foo")
          method << RBI::Param.new("a")
          method << RBI::OptParam.new("b", "42")
          method << RBI::RestParam.new("c")
          method << RBI::KwParam.new("d")
          method << RBI::KwOptParam.new("e", "'bar'")
          method << RBI::KwRestParam.new("f")
          method << RBI::BlockParam.new("g")

          assert_equal(<<~RBI, method.string)
            def foo(a, b = 42, *c, d:, e: 'bar', **f, &g); end
          RBI
        end

        it("builds methods with signatures") do
          sig1 = RBI::Sig.new

          sig2 = RBI::Sig.new(return_type: "R")
          sig2 << RBI::SigParam.new("a", "A")
          sig2 << RBI::SigParam.new("b", "T.nilable(B)")
          sig2 << RBI::SigParam.new("b", "T.proc.void")

          sig3 = RBI::Sig.new(is_abstract: true)
          sig3.is_override = true
          sig3.is_overridable = true

          sig4 = RBI::Sig.new(return_type: "T.type_parameter(:V)")
          sig4.type_params << "U"
          sig4.type_params << "V"
          sig4 << RBI::SigParam.new("a", "T.type_parameter(:U)")

          method = RBI::Method.new("foo")
          method.sigs << sig1
          method.sigs << sig2
          method.sigs << sig3
          method.sigs << sig4

          assert_equal(<<~RBI, method.string)
            sig { void }
            sig { params(a: A, b: T.nilable(B), b: T.proc.void).returns(R) }
            sig { abstract.override.overridable.void }
            sig { type_parameters(:U, :V).params(a: T.type_parameter(:U)).returns(T.type_parameter(:V)) }
            def foo; end
          RBI
        end

        it("builds mixins") do
          scope = RBI::Class.new("Foo")
          scope << RBI::Include.new("A")
          scope << RBI::Extend.new("A")

          assert_equal(<<~RBI, scope.string)
            class Foo
              include A
              extend A
            end
          RBI
        end

        it("builds visibility labels") do
          tree = RBI::Tree.new
          tree << RBI::Visibility::Public
          tree << RBI::Method.new("m1")
          tree << RBI::Visibility::Protected
          tree << RBI::Method.new("m2")
          tree << RBI::Visibility::Private
          tree << RBI::Method.new("m3")

          assert_equal(<<~RBI, tree.string)
            public
            def m1; end
            protected
            def m2; end
            private
            def m3; end
          RBI
        end

        it("builds T::Struct") do
          struct = RBI::TStruct.new("Foo")
          struct << RBI::TStructConst.new("a", "A")
          struct << RBI::TStructConst.new("b", "B", default: "B.new")
          struct << RBI::TStructProp.new("c", "C")
          struct << RBI::TStructProp.new("d", "D", default: "D.new")
          struct << RBI::Method.new("foo")

          assert_equal(<<~RBI, struct.string)
            class Foo < ::T::Struct
              const :a, A
              const :b, B, default: B.new
              prop :c, C
              prop :d, D, default: D.new
              def foo; end
            end
           RBI
        end

        it("builds T::Enum") do
          rbi = RBI::TEnum.new("Foo")
          block = TEnumBlock.new(["A", "B"])
          block.names << "C"
          rbi << block
          rbi << RBI::Method.new("baz")

          assert_equal(<<~RBI, rbi.string)
            class Foo < ::T::Enum
              enums do
                A = new
                B = new
                C = new
              end
              def baz; end
            end
          RBI
        end

        it("builds Sorbet's helpers") do
          rbi = RBI::Class.new("Foo")
          rbi << RBI::Helper.new("foo")
          rbi << RBI::Helper.new("sealed")
          rbi << RBI::Helper.new("interface")
          rbi << RBI::MixesInClassMethods.new("A")

          assert_equal(<<~RBI, rbi.string)
            class Foo
              foo!
              sealed!
              interface!
              mixes_in_class_methods A
            end
          RBI
        end

        it("builds Sorbet's type members and templates") do
          rbi = RBI::Class.new("Foo")
          rbi << RBI::TypeMember.new("A", "type_member")
          rbi << RBI::TypeMember.new("B", "type_template")

          assert_equal(<<~RBI, rbi.string)
            class Foo
              A = type_member
              B = type_template
            end
          RBI
        end
      end

      describe("can nest singleton methods") do
        it("nests singleton methods in trees") do
          rbi = RBI::Tree.new
          rbi << RBI::Method.new("m1")
          rbi << RBI::Method.new("m2", is_singleton: true)
          rbi << RBI::Method.new("m3")
          rbi << RBI::Method.new("m4", is_singleton: true)

          rbi.nest_singleton_methods!

          assert_equal(<<~RBI, rbi.string)
            def m1; end
            def m3; end

            class << self
              def m2; end
              def m4; end
            end
          RBI
        end

        it("nests singleton methods in scopes") do
          rbi = RBI::Tree.new
          scope1 = RBI::Module.new("Foo")
          scope1 << RBI::Method.new("m1")
          scope1 << RBI::Method.new("m2", is_singleton: true)
          scope2 = RBI::Class.new("Bar")
          scope2 << RBI::Method.new("m3")
          scope2 << RBI::Method.new("m4", is_singleton: true)
          rbi << scope1
          rbi << scope2

          rbi.nest_singleton_methods!

          assert_equal(<<~RBI, rbi.string)
            module Foo
              def m1; end

              class << self
                def m2; end
              end
            end

            class Bar
              def m3; end

              class << self
                def m4; end
              end
            end
          RBI
        end

        it("nests singleton methods in singleton classes") do
          rbi = RBI::Tree.new
          scope1 = RBI::SingletonClass.new
          scope1 << RBI::Method.new("m1", is_singleton: true)
          scope2 = RBI::SingletonClass.new
          scope2 << RBI::Method.new("m2", is_singleton: true)
          scope1 << scope2
          rbi << scope1

          rbi.nest_singleton_methods!

          assert_equal(<<~RBI, rbi.string)
            class << self
              class << self
                class << self
                  def m2; end
                end
              end

              class << self
                def m1; end
              end
            end
          RBI
        end

        it("does not nest other nodes") do
          rbi = RBI::Tree.new
          scope1 = RBI::Module.new("Foo")
          scope1 << RBI::Const.new("C1", "42")
          scope1 << RBI::Module.new("M1")
          scope1 << RBI::Helper.new("h1")
          scope2 = RBI::Class.new("Bar")
          scope2 << RBI::Include.new("I1")
          scope2 << RBI::Extend.new("E1")
          rbi << scope1
          rbi << scope2

          rbi.nest_singleton_methods!

          assert_equal(<<~RBI, rbi.string)
            module Foo
              C1 = 42
              module M1; end
              h1!
            end

            class Bar
              include I1
              extend E1
            end
          RBI
        end
      end

      describe("can nest non public methods") do
        it("nests non public methods in trees") do
          rbi = RBI::Tree.new
          rbi << RBI::Method.new("m1")
          rbi << RBI::Method.new("m2", visibility: RBI::Visibility::Protected)
          rbi << RBI::Method.new("m3", visibility: RBI::Visibility::Private)
          rbi << RBI::Method.new("m4", visibility: RBI::Visibility::Public)

          rbi.nest_non_public_methods!

          assert_equal(<<~RBI, rbi.string)
            def m1; end
            def m4; end

            protected

            def m2; end

            private

            def m3; end
          RBI
        end

        it("nests non public methods in scopes") do
          rbi = RBI::Tree.new
          scope1 = RBI::Module.new("S1")
          scope1 << RBI::Method.new("m1")
          scope1 << RBI::Method.new("m2", visibility: RBI::Visibility::Protected)
          scope2 = RBI::Class.new("S2")
          scope2 << RBI::Method.new("m3")
          scope2 << RBI::Method.new("m4", visibility: RBI::Visibility::Private)
          scope3 = RBI::SingletonClass.new
          scope3 << RBI::Method.new("m5")
          scope3 << RBI::Method.new("m6", visibility: RBI::Visibility::Protected)
          rbi << scope1
          scope1 << scope2
          scope2 << scope3

          rbi.nest_non_public_methods!

          assert_equal(<<~RBI, rbi.string)
            module S1
              class S2
                class << self
                  def m5; end

                  protected

                  def m6; end
                end

                def m3; end

                private

                def m4; end
              end

              def m1; end

              protected

              def m2; end
            end
          RBI
        end

        it("nests non public singleton methods") do
          rbi = RBI::Tree.new
          rbi << RBI::Method.new("m1", is_singleton: true, visibility: RBI::Visibility::Protected)
          rbi << RBI::Method.new("m2", is_singleton: true, visibility: RBI::Visibility::Private)
          rbi << RBI::Method.new("m3", is_singleton: true, visibility: RBI::Visibility::Public)

          rbi.nest_non_public_methods!

          assert_equal(<<~RBI, rbi.string)
            def self.m3; end

            protected

            def self.m1; end

            private

            def self.m2; end
          RBI
        end
      end

      describe("can group nodes") do
        it("groups nodes in tree") do
          rbi = RBI::Tree.new
          rbi << RBI::Const.new("C", "42")
          rbi << RBI::Module.new("S1")
          rbi << RBI::Class.new("S2")
          rbi << RBI::Method.new("m1")
          rbi << RBI::Method.new("m2", is_singleton: true)
          rbi << RBI::Extend.new("E")
          rbi << RBI::Include.new("I")
          rbi << RBI::MixesInClassMethods.new("MICM")
          rbi << RBI::Helper.new("h")
          rbi << RBI::TStructConst.new("SC", "Type")
          rbi << RBI::TStructProp.new("SP", "Type")
          rbi << RBI::TEnum.new("TE")
          rbi << RBI::TStruct.new("TS")

          rbi.group_nodes!
          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            extend E
            include I

            h!

            mixes_in_class_methods MICM

            const :SC, Type
            prop :SP, Type

            def m1; end
            def self.m2; end

            C = 42
            module S1; end
            class S2; end
            class TE < ::T::Enum; end
            class TS < ::T::Struct; end
          RBI
        end

        it("groups nested nodes") do
          rbi = RBI::Tree.new

          scope1 = RBI::Class.new("Scope1")
          scope1 << RBI::Include.new("I1")
          scope1 << RBI::Method.new("m1")
          scope1 << RBI::Method.new("m2")

          scope2 = RBI::Class.new("Scope2")
          scope2 << RBI::Const.new("C1", "42")
          scope2 << RBI::Const.new("C2", "42")
          scope2 << RBI::Module.new("M1")

          scope3 = RBI::Class.new("Scope3")
          scope3 << RBI::Extend.new("E1")
          scope3 << RBI::Extend.new("E2")
          scope3 << RBI::MixesInClassMethods.new("MICM1")

          rbi << scope1
          scope1 << scope2
          scope2 << scope3

          rbi.group_nodes!
          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            class Scope1
              include I1

              def m1; end
              def m2; end

              class Scope2
                C1 = 42
                C2 = 42
                module M1; end

                class Scope3
                  extend E1
                  extend E2

                  mixes_in_class_methods MICM1
                end
              end
            end
          RBI
        end
      end

      describe("cant sort nodes") do
        it("sorts nodes in tree") do
          rbi = RBI::Tree.new
          rbi << RBI::Const.new("C", "42")
          rbi << RBI::Module.new("S1")
          rbi << RBI::Class.new("S2")
          rbi << RBI::Method.new("m1")
          rbi << RBI::Method.new("m2", is_singleton: true)
          rbi << RBI::Extend.new("E")
          rbi << RBI::Include.new("I")
          rbi << RBI::MixesInClassMethods.new("MICM")
          rbi << RBI::Helper.new("h")
          rbi << RBI::TStructConst.new("SC", "Type")
          rbi << RBI::TStructProp.new("SP", "Type")
          rbi << RBI::TEnum.new("TE")
          rbi << RBI::TStruct.new("TS")

          rbi.group_nodes!
          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            extend E
            include I

            h!

            mixes_in_class_methods MICM

            const :SC, Type
            prop :SP, Type

            def m1; end
            def self.m2; end

            C = 42
            module S1; end
            class S2; end
            class TE < ::T::Enum; end
            class TS < ::T::Struct; end
          RBI
        end

        it("does not sort mixins") do
          rbi = RBI::Tree.new
          rbi << RBI::Include.new("I2")
          rbi << RBI::Extend.new("E2")
          rbi << RBI::MixesInClassMethods.new("M2")
          rbi << RBI::Include.new("I1")
          rbi << RBI::Extend.new("E1")
          rbi << RBI::MixesInClassMethods.new("M1")

          rbi.group_nodes!
          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            include I2
            extend E2
            include I1
            extend E1

            mixes_in_class_methods M2
            mixes_in_class_methods M1
         RBI
        end

        it("does not sort type members") do
          rbi = RBI::Tree.new
          rbi << RBI::TypeMember.new("T4", "type_member")
          rbi << RBI::TypeMember.new("T3", "type_template")
          rbi << RBI::TypeMember.new("T2", "type_member")
          rbi << RBI::TypeMember.new("T1", "type_template")

          rbi.group_nodes!
          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            T4 = type_member
            T3 = type_template
            T2 = type_member
            T1 = type_template
         RBI
        end

        it("sorts nodes in scope") do
          rbi = RBI::Tree.new
          scope = RBI::Module.new("Scope")
          scope << RBI::Const.new("C", "42")
          scope << RBI::Module.new("S1")
          scope << RBI::Class.new("S2")
          scope << RBI::Method.new("m1")
          scope << RBI::Method.new("m2", is_singleton: true)
          scope << RBI::Include.new("I")
          scope << RBI::Extend.new("E")
          scope << RBI::MixesInClassMethods.new("MICM")
          scope << RBI::Helper.new("h")
          scope << RBI::TStructProp.new("SP", "Type")
          scope << RBI::TStructConst.new("SC", "Type")
          scope << RBI::TEnum.new("TE")
          scope << RBI::TStruct.new("TS")
          scope << RBI::TypeMember.new("TM2", "type_template")
          scope << RBI::TypeMember.new("TM1", "type_member")
          rbi << scope

          rbi.group_nodes!
          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            module Scope
              include I
              extend E

              h!

              TM2 = type_template
              TM1 = type_member

              mixes_in_class_methods MICM

              const :SC, Type
              prop :SP, Type

              def m1; end
              def self.m2; end

              C = 42
              module S1; end
              class S2; end
              class TE < ::T::Enum; end
              class TS < ::T::Struct; end
            end
          RBI
        end

        it("sorts groups in tree") do
          rbi = RBI::Tree.new
          rbi << RBI::Const.new("C2", "42")
          rbi << RBI::Module.new("S2")
          rbi << RBI::Method.new("m2")
          rbi << RBI::Include.new("I2")
          rbi << RBI::Extend.new("E2")
          rbi << RBI::MixesInClassMethods.new("MICM2")
          rbi << RBI::Helper.new("h2")
          rbi << RBI::TStructProp.new("SP2", "Type")
          rbi << RBI::TStructConst.new("SC2", "Type")
          rbi << RBI::TEnum.new("TE2")
          rbi << RBI::TStruct.new("TS2")
          rbi << RBI::Const.new("C1", "42")
          rbi << RBI::Module.new("S1")
          rbi << RBI::Method.new("m1")
          rbi << RBI::Include.new("I1")
          rbi << RBI::Extend.new("E1")
          rbi << RBI::MixesInClassMethods.new("MICM1")
          rbi << RBI::Helper.new("h1")
          rbi << RBI::TStructProp.new("SP1", "Type")
          rbi << RBI::TStructConst.new("SC1", "Type")
          rbi << RBI::TEnum.new("TE1")
          rbi << RBI::TStruct.new("TS1")
          rbi << RBI::TypeMember.new("TM2", "type_template")
          rbi << RBI::TypeMember.new("TM1", "type_member")

          rbi.group_nodes!
          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            include I2
            extend E2
            include I1
            extend E1

            h1!
            h2!

            TM2 = type_template
            TM1 = type_member

            mixes_in_class_methods MICM2
            mixes_in_class_methods MICM1

            const :SC1, Type
            const :SC2, Type
            prop :SP1, Type
            prop :SP2, Type

            def m1; end
            def m2; end

            C1 = 42
            C2 = 42
            module S1; end
            module S2; end
            class TE1 < ::T::Enum; end
            class TE2 < ::T::Enum; end
            class TS1 < ::T::Struct; end
            class TS2 < ::T::Struct; end
          RBI
        end

        it("sorts nested groups") do
          rbi = RBI::Tree.new

          sscope = RBI::Class.new("Scope2.1")
          sscope << RBI::Const.new("C2", "42")
          sscope << RBI::Module.new("S2")
          sscope << RBI::Method.new("m2")
          sscope << RBI::Include.new("I2")
          sscope << RBI::Extend.new("E2")
          sscope << RBI::MixesInClassMethods.new("MICM2")
          sscope << RBI::Helper.new("h2")
          sscope << RBI::TStructProp.new("SP2", "Type")
          sscope << RBI::TStructConst.new("SC2", "Type")
          sscope << RBI::TEnum.new("TE2")
          sscope << RBI::TStruct.new("TS2")
          sscope << RBI::Const.new("C1", "42")
          sscope << RBI::Module.new("S1")
          sscope << RBI::Method.new("m1")
          sscope << RBI::Include.new("I1")
          sscope << RBI::Extend.new("E1")
          sscope << RBI::MixesInClassMethods.new("MICM1")
          sscope << RBI::Helper.new("h1")
          sscope << RBI::TStructProp.new("SP1", "Type")
          sscope << RBI::TStructConst.new("SC1", "Type")
          sscope << RBI::TEnum.new("TE1")
          sscope << RBI::TStruct.new("TS1")
          sscope << RBI::TypeMember.new("TM2", "type_template")
          sscope << RBI::TypeMember.new("TM1", "type_member")

          scope = RBI::Class.new("Scope2")
          scope << sscope
          scope << RBI::Const.new("C2", "42")
          scope << RBI::Module.new("S2")
          scope << RBI::Method.new("m2")
          scope << RBI::Include.new("I2")
          scope << RBI::Extend.new("E2")
          scope << RBI::MixesInClassMethods.new("MICM2")
          scope << RBI::Helper.new("h2")
          scope << RBI::TStructProp.new("SP2", "Type")
          scope << RBI::TStructConst.new("SC2", "Type")
          scope << RBI::TEnum.new("TE2")
          scope << RBI::TStruct.new("TS2")
          scope << RBI::Const.new("C1", "42")
          scope << RBI::Module.new("S1")
          scope << RBI::Method.new("m1")
          scope << RBI::Include.new("I1")
          scope << RBI::Extend.new("E1")
          scope << RBI::MixesInClassMethods.new("MICM1")
          scope << RBI::Helper.new("h1")
          scope << RBI::TStructProp.new("SP1", "Type")
          scope << RBI::TStructConst.new("SC1", "Type")
          scope << RBI::TEnum.new("TE1")
          scope << RBI::TStruct.new("TS1")
          scope << RBI::TypeMember.new("TM2", "type_template")
          scope << RBI::TypeMember.new("TM1", "type_member")
          rbi << scope

          scope = RBI::Class.new("Scope1")
          scope << RBI::Const.new("C2", "42")
          scope << RBI::Module.new("S2")
          scope << RBI::Method.new("m2")
          scope << RBI::Include.new("I2")
          scope << RBI::Extend.new("E2")
          scope << RBI::MixesInClassMethods.new("MICM2")
          scope << RBI::Helper.new("h2")
          scope << RBI::TStructProp.new("SP2", "Type")
          scope << RBI::TStructConst.new("SC2", "Type")
          scope << RBI::TEnum.new("TE2")
          scope << RBI::TStruct.new("TS2")
          scope << RBI::Const.new("C1", "42")
          scope << RBI::Module.new("S1")
          scope << RBI::Method.new("m1")
          scope << RBI::Include.new("I1")
          scope << RBI::Extend.new("E1")
          scope << RBI::MixesInClassMethods.new("MICM1")
          scope << RBI::Helper.new("h1")
          scope << RBI::TStructProp.new("SP1", "Type")
          scope << RBI::TStructConst.new("SC1", "Type")
          scope << RBI::TEnum.new("TE1")
          scope << RBI::TStruct.new("TS1")
          scope << RBI::TypeMember.new("TM2", "type_template")
          scope << RBI::TypeMember.new("TM1", "type_member")
          rbi << scope

          rbi.group_nodes!
          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            class Scope1
              include I2
              extend E2
              include I1
              extend E1

              h1!
              h2!

              TM2 = type_template
              TM1 = type_member

              mixes_in_class_methods MICM2
              mixes_in_class_methods MICM1

              const :SC1, Type
              const :SC2, Type
              prop :SP1, Type
              prop :SP2, Type

              def m1; end
              def m2; end

              C1 = 42
              C2 = 42
              module S1; end
              module S2; end
              class TE1 < ::T::Enum; end
              class TE2 < ::T::Enum; end
              class TS1 < ::T::Struct; end
              class TS2 < ::T::Struct; end
            end

            class Scope2
              include I2
              extend E2
              include I1
              extend E1

              h1!
              h2!

              TM2 = type_template
              TM1 = type_member

              mixes_in_class_methods MICM2
              mixes_in_class_methods MICM1

              const :SC1, Type
              const :SC2, Type
              prop :SP1, Type
              prop :SP2, Type

              def m1; end
              def m2; end

              C1 = 42
              C2 = 42
              module S1; end
              module S2; end

              class Scope2.1
                include I2
                extend E2
                include I1
                extend E1

                h1!
                h2!

                TM2 = type_template
                TM1 = type_member

                mixes_in_class_methods MICM2
                mixes_in_class_methods MICM1

                const :SC1, Type
                const :SC2, Type
                prop :SP1, Type
                prop :SP2, Type

                def m1; end
                def m2; end

                C1 = 42
                C2 = 42
                module S1; end
                module S2; end
                class TE1 < ::T::Enum; end
                class TE2 < ::T::Enum; end
                class TS1 < ::T::Struct; end
                class TS2 < ::T::Struct; end
              end

              class TE1 < ::T::Enum; end
              class TE2 < ::T::Enum; end
              class TS1 < ::T::Struct; end
              class TS2 < ::T::Struct; end
            end
          RBI
        end
      end

      describe("print rbi") do
        it("print new lines between scopes") do
          rbi = RBI::Tree.new
          scope = RBI::Class.new("Bar")
          scope << RBI::Include.new("ModuleA")
          rbi << scope
          rbi << RBI::Module.new("ModuleA")

          rbi.group_nodes!
          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            class Bar
              include ModuleA
            end

            module ModuleA; end
          RBI
        end

        it("print new lines between methods with sigs") do
          rbi = RBI::Tree.new
          rbi << RBI::Method.new("m1")
          rbi << RBI::Method.new("m2")

          m3 = RBI::Method.new("m3")
          m3.sigs << RBI::Sig.new
          rbi << m3

          rbi << RBI::Method.new("m4")

          m5 = RBI::Method.new("m5")
          m5.sigs << RBI::Sig.new
          m5.sigs << RBI::Sig.new
          rbi << m5

          m6 = RBI::Method.new("m6")
          m6.sigs << RBI::Sig.new
          rbi << m6

          rbi << RBI::Method.new("m7")
          rbi << RBI::Method.new("m8")

          rbi.group_nodes!
          rbi.sort_nodes!

          assert_equal(<<~RBI, rbi.string)
            def m1; end
            def m2; end

            sig { void }
            def m3; end

            def m4; end

            sig { void }
            sig { void }
            def m5; end

            sig { void }
            def m6; end

            def m7; end
            def m8; end
          RBI
        end
      end
    end
  end
end
