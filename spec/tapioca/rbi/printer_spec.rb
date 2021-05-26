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

      describe("can build RBI nodes with comments") do
        it("builds nodes with comments") do
          comments_single = [RBI::Comment.new("This is a single line comment")]

          comments_multi = [
            RBI::Comment.new("This is a"),
            RBI::Comment.new("Multiline Comment"),
          ]

          rbi = RBI::Tree.new
          rbi << RBI::Module.new("Foo", comments: comments_single)
          rbi << RBI::Class.new("Bar", comments: comments_multi)
          rbi << RBI::SingletonClass.new(comments: comments_single)
          rbi << RBI::Const.new("Foo", "42", comments: comments_multi)
          rbi << RBI::Include.new("A", comments: comments_single)
          rbi << RBI::Extend.new("A", comments: comments_multi)

          struct = RBI::TStruct.new("Foo", comments: comments_single)
          struct << RBI::TStructConst.new("a", "A", comments: comments_multi)
          struct << RBI::TStructProp.new("c", "C", comments: comments_single)
          rbi << struct

          enum = RBI::TEnum.new("Foo", comments: comments_multi)
          enum << TEnumBlock.new(["A", "B"], comments: comments_single)
          rbi << enum

          rbi << RBI::Helper.new("foo", comments: comments_multi)
          rbi << RBI::MixesInClassMethods.new("A", comments: comments_single)
          rbi << RBI::TypeMember.new("A", "type_member", comments: comments_multi)
          rbi << RBI::TypeMember.new("B", "type_template", comments: comments_single)

          assert_equal(<<~RBI, rbi.string)
            # This is a single line comment
            module Foo; end

            # This is a
            # Multiline Comment
            class Bar; end

            # This is a single line comment
            class << self; end

            # This is a
            # Multiline Comment
            Foo = 42

            # This is a single line comment
            include A

            # This is a
            # Multiline Comment
            extend A

            # This is a single line comment
            class Foo < ::T::Struct
              # This is a
              # Multiline Comment
              const :a, A

              # This is a single line comment
              prop :c, C
            end

            # This is a
            # Multiline Comment
            class Foo < ::T::Enum
              # This is a single line comment
              enums do
                A = new
                B = new
              end
            end

            # This is a
            # Multiline Comment
            foo!

            # This is a single line comment
            mixes_in_class_methods A

            # This is a
            # Multiline Comment
            A = type_member

            # This is a single line comment
            B = type_template
          RBI
        end

        it("builds methods with signatures and comments") do
          comments_single = [RBI::Comment.new("This is a single line comment")]

          comments_multi = [
            RBI::Comment.new("This is a"),
            RBI::Comment.new("Multiline Comment"),
          ]

          rbi = RBI::Tree.new
          rbi << RBI::Method.new("foo", comments: comments_multi)

          method = RBI::Method.new("foo", comments: comments_single)
          method.sigs << RBI::Sig.new
          rbi << method

          sig1 = RBI::Sig.new
          sig2 = RBI::Sig.new(return_type: "R")
          sig2 << RBI::SigParam.new("a", "A")
          sig2 << RBI::SigParam.new("b", "T.nilable(B)")
          sig2 << RBI::SigParam.new("b", "T.proc.void")

          method = RBI::Method.new("bar", comments: comments_multi)
          method.sigs << sig1
          method.sigs << sig2
          rbi << method

          assert_equal(<<~RBI, rbi.string)
            # This is a
            # Multiline Comment
            def foo; end

            # This is a single line comment
            sig { void }
            def foo; end

            # This is a
            # Multiline Comment
            sig { void }
            sig { params(a: A, b: T.nilable(B), b: T.proc.void).returns(R) }
            def bar; end
          RBI
        end

        it("builds tree header comments") do
          rbi = RBI::Tree.new(comments: [
            RBI::Comment.new("typed: true"),
            RBI::Comment.new("frozen_string_literal: false"),
          ])
          rbi << RBI::Module.new("Foo", comments: [RBI::Comment.new("Foo comment")])

          assert_equal(<<~RBI, rbi.string)
            # typed: true
            # frozen_string_literal: false

            # Foo comment
            module Foo; end
          RBI
        end

        it("prints params inline comments") do
          comments = [RBI::Comment.new("comment")]

          method = RBI::Method.new("foo", comments: comments)
          method << RBI::Param.new("a", comments: comments)
          method << RBI::OptParam.new("b", "42", comments: comments)
          method << RBI::RestParam.new("c", comments: comments)
          method << RBI::KwParam.new("d", comments: comments)
          method << RBI::KwOptParam.new("e", "'bar'", comments: comments)
          method << RBI::KwRestParam.new("f", comments: comments)
          method << RBI::BlockParam.new("g", comments: comments)

          assert_equal(<<~RBI, method.string)
            # comment
            def foo(
              a, # comment
              b = 42, # comment
              *c, # comment
              d:, # comment
              e: 'bar', # comment
              **f, # comment
              &g # comment
            ); end
          RBI
        end

        it("prints params multiline comments") do
          comments = [
            RBI::Comment.new("comment 1"),
            RBI::Comment.new("comment 2"),
          ]

          method = RBI::Method.new("foo", comments: comments)
          method << RBI::Param.new("a", comments: comments)
          method << RBI::OptParam.new("b", "42", comments: comments)
          method << RBI::RestParam.new("c", comments: comments)
          method << RBI::KwParam.new("d", comments: comments)
          method << RBI::KwOptParam.new("e", "'bar'", comments: comments)
          method << RBI::KwRestParam.new("f", comments: comments)
          method << RBI::BlockParam.new("g", comments: comments)

          assert_equal(<<~RBI, method.string)
            # comment 1
            # comment 2
            def foo(
              a, # comment 1
                 # comment 2
              b = 42, # comment 1
                      # comment 2
              *c, # comment 1
                  # comment 2
              d:, # comment 1
                  # comment 2
              e: 'bar', # comment 1
                        # comment 2
              **f, # comment 1
                   # comment 2
              &g # comment 1
                 # comment 2
            ); end
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

      describe("supports options") do
        it("shows nodes locations") do
          loc = RBI::Loc.new(file: "file.rbi", begin_line: 1, end_line: 2, begin_column: 3, end_column: 4)

          rbi = RBI::Tree.new(loc: loc)
          rbi << RBI::Module.new("S1", loc: loc)
          rbi << RBI::Class.new("S2", loc: loc)
          rbi << RBI::SingletonClass.new(loc: loc)
          rbi << RBI::TEnum.new("TE", loc: loc)
          rbi << RBI::TStruct.new("TS", loc: loc)
          rbi << RBI::Const.new("C", "42", loc: loc)
          rbi << RBI::Extend.new("E", loc: loc)
          rbi << RBI::Include.new("I", loc: loc)
          rbi << RBI::MixesInClassMethods.new("MICM", loc: loc)
          rbi << RBI::Helper.new("abstract", loc: loc)
          rbi << RBI::TStructConst.new("SC", "Type", loc: loc)
          rbi << RBI::TStructProp.new("SP", "Type", loc: loc)
          rbi << RBI::Method.new("m1", loc: loc)

          assert_equal(<<~RBI, rbi.string(print_locs: true))
            # file.rbi:1:3-2:4
            module S1; end
            # file.rbi:1:3-2:4
            class S2; end
            # file.rbi:1:3-2:4
            class << self; end
            # file.rbi:1:3-2:4
            class TE < ::T::Enum; end
            # file.rbi:1:3-2:4
            class TS < ::T::Struct; end
            # file.rbi:1:3-2:4
            C = 42
            # file.rbi:1:3-2:4
            extend E
            # file.rbi:1:3-2:4
            include I
            # file.rbi:1:3-2:4
            mixes_in_class_methods MICM
            # file.rbi:1:3-2:4
            abstract!
            # file.rbi:1:3-2:4
            const :SC, Type
            # file.rbi:1:3-2:4
            prop :SP, Type
            # file.rbi:1:3-2:4
            def m1; end
          RBI
        end

        it("shows sigs locations") do
          loc = RBI::Loc.new(file: "file.rbi", begin_line: 1, end_line: 2, begin_column: 3, end_column: 4)

          sig1 = RBI::Sig.new(loc: loc)
          sig2 = RBI::Sig.new(loc: loc)

          rbi = RBI::Tree.new(loc: loc)
          rbi << RBI::Method.new("m1", sigs: [sig1, sig2], loc: loc)

          assert_equal(<<~RBI, rbi.string(print_locs: true))
            # file.rbi:1:3-2:4
            sig { void }
            # file.rbi:1:3-2:4
            sig { void }
            # file.rbi:1:3-2:4
            def m1; end
          RBI
        end
      end
    end
  end
end
