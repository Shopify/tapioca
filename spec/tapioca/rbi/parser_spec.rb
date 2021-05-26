# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module RBI
    class ParserSpec < Minitest::HooksSpec
      describe("can parse rbi") do
        it("parses scopes") do
          rbi = <<~RBI
            module Foo; end
            class Bar; end
            class Bar::Baz < Bar; end
            class ::Foo::Bar::Baz < ::Foo::Bar; end
            class << self; end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end

        it("parses nested scopes") do
          rbi = <<~RBI
            module Foo
              class Bar
                class Baz < Bar
                  class << self; end
                end
              end
            end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end

        it("builds constants") do
          rbi = <<~RBI
            Foo = 42
            Bar = "foo"
            Baz = Bar
            A = nil
            B = :s
            C = T.nilable(String)
            D = A::B::C
            A::B::C = Foo
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end

        it("builds attributes") do
          rbi = <<~RBI
            attr_reader :a
            attr_writer :a, :b
            attr_accessor :a, :b, :c

            sig { returns(String) }
            attr_reader :a

            sig { returns(T.nilable(String)) }
            attr_accessor :a, :b, :c
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end

        it("builds methods") do
          rbi = <<~RBI
            def m1; end
            def self.m2; end
            def m3(a, b = 42, *c, d:, e: "bar", **f, &g); end

            sig { void }
            sig { returns(String) }
            sig { params(a: T.untyped, b: T::Array[String]).returns(T::Hash[String, Integer]) }
            sig { abstract.params(a: Integer).void }
            sig { returns(T::Array[String]).checked(:never) }
            sig { override.params(printer: Spoom::LSP::SymbolPrinter).void }
            sig { returns(T.nilable(String)) }
            sig { params(requested_generators: T::Array[String]).returns(T.proc.params(klass: Class).returns(T::Boolean)) }
            sig { type_parameters(:U).params(step: Integer, _blk: T.proc.returns(T.type_parameter(:U))).returns(T.type_parameter(:U)) }
            sig { type_parameters(:A, :B).params(a: T::Array[T.type_parameter(:A)], fa: T.proc.params(item: T.type_parameter(:A)).returns(T.untyped), b: T::Array[T.type_parameter(:B)], fb: T.proc.params(item: T.type_parameter(:B)).returns(T.untyped)).returns(T::Array[[T.type_parameter(:A), T.type_parameter(:B)]]) }
            sig { returns({ item_id: String, tax_code: String, name: String, rate: BigDecimal, rate_type: String, amount: BigDecimal, subdivision: String, jurisdiction: String, exempt: T::Boolean, reasons: T::Array[String] }) }
            def m4; end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end

        it("builds mixins") do
          rbi = <<~RBI
            class Foo
              include A
              extend A
            end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end

        it("builds visibility labels") do
          rbi = <<~RBI
            public
            def m1; end
            protected
            def m2; end
            private
            def m3; end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end

        it("builds T::Struct") do
          rbi = <<~RBI
            class Foo < ::T::Struct
              const :a, A
              const :b, B, default: B.new
              prop :c, C
              prop :d, D, default: D.new
              def foo; end
            end
           RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end

        it("builds T::Enum") do
          rbi = <<~RBI
            class Foo < ::T::Enum
              enums do
                A = new
                B = new
                C = new
              end
              def baz; end
            end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end

        it("builds Sorbet's helpers") do
          rbi = <<~RBI
            class Foo
              abstract!
              sealed!
              interface!
              mixes_in_class_methods A
            end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end

        it("builds Sorbet's type members and templates") do
          rbi = <<~RBI
            class Foo
              A = type_member
              B = type_member(:in)
              C = type_member(:out)
              D = type_member(lower: A)
              E = type_member(upper: A)
              F = type_member(:in, fixed: A)
              G = type_template
              H = type_template(:in)
              I = type_template(:out, lower: A)
            end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end
      end

      describe("can parse rbi with locations") do
        it("parses consts") do
          rbi = <<~RBI
            module Foo; end
            class Bar; end
            class Baz < Bar; end
            class << self; end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string(print_locs: true))
            # -:1:0-1:15
            module Foo; end
            # -:2:0-2:14
            class Bar; end
            # -:3:0-3:20
            class Baz < Bar; end
            # -:4:0-4:18
            class << self; end
          RBI
        end

        it("parses nested scopes") do
          rbi = <<~RBI
            module Foo
              class Bar
                class Baz < Bar
                  class << self; end
                end
              end
            end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string(print_locs: true))
            # -:1:0-7:3
            module Foo
              # -:2:2-6:5
              class Bar
                # -:3:4-5:7
                class Baz < Bar
                  # -:4:6-4:24
                  class << self; end
                end
              end
            end
          RBI
        end

        it("builds constants") do
          rbi = <<~RBI
            Foo = 42
            Bar = "foo"
            Baz = Bar
            A::B::C = Foo
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string(print_locs: true))
            # -:1:0-1:8
            Foo = 42
            # -:2:0-2:11
            Bar = "foo"
            # -:3:0-3:9
            Baz = Bar
            # -:4:0-4:13
            A::B::C = Foo
          RBI
        end

        it("builds attributes") do
          rbi = <<~RBI
            attr_reader :a
            attr_writer :a, :b
            attr_accessor :a, :b, :c

            sig { returns(String) }
            attr_reader :a

            sig { returns(T.nilable(String)) }
            attr_accessor :a, :b, :c
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string(print_locs: true))
            # -:1:0-1:14
            attr_reader :a
            # -:2:0-2:18
            attr_writer :a, :b
            # -:3:0-3:24
            attr_accessor :a, :b, :c

            # -:5:0-5:23
            sig { returns(String) }
            # -:6:0-6:14
            attr_reader :a

            # -:8:0-8:34
            sig { returns(T.nilable(String)) }
            # -:9:0-9:24
            attr_accessor :a, :b, :c
          RBI
        end

        it("builds methods") do
          rbi = <<~RBI
            def m1; end
            def self.m2; end
            def m3(a, b = 42, *c, d:, e: "bar", **f, &g); end

            sig { void }
            sig { params(a: A, b: T.nilable(B), b: T.proc.void).returns(R) }
            sig { abstract.override.overridable.void }
            sig { type_parameters(:U, :V).params(a: T.type_parameter(:U)).returns(T.type_parameter(:V)).checked(:never) }
            def m4; end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string(print_locs: true))
            # -:1:0-1:11
            def m1; end
            # -:2:0-2:16
            def self.m2; end
            # -:3:0-3:49
            def m3(a, b = 42, *c, d:, e: "bar", **f, &g); end

            # -:5:0-5:12
            sig { void }
            # -:6:0-6:64
            sig { params(a: A, b: T.nilable(B), b: T.proc.void).returns(R) }
            # -:7:0-7:42
            sig { abstract.override.overridable.void }
            # -:8:0-8:109
            sig { type_parameters(:U, :V).params(a: T.type_parameter(:U)).returns(T.type_parameter(:V)).checked(:never) }
            # -:9:0-9:11
            def m4; end
          RBI
        end

        it("builds mixins") do
          rbi = <<~RBI
            class Foo
              include A
              extend A
            end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string(print_locs: true))
            # -:1:0-4:3
            class Foo
              # -:2:2-2:11
              include A
              # -:3:2-3:10
              extend A
            end
          RBI
        end

        it("builds visibility labels") do
          rbi = <<~RBI
            public
            def m1; end
            protected
            def m2; end
            private
            def m3; end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string(print_locs: true))
            # -:1:0-1:6
            public
            # -:2:0-2:11
            def m1; end
            # -:3:0-3:9
            protected
            # -:4:0-4:11
            def m2; end
            # -:5:0-5:7
            private
            # -:6:0-6:11
            def m3; end
          RBI
        end

        it("builds T::Struct") do
          rbi = <<~RBI
            class Foo < ::T::Struct
              const :a, A
              const :b, B, default: B.new
              prop :c, C
              prop :d, D, default: D.new
              def foo; end
            end
           RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string(print_locs: true))
            # -:1:0-7:3
            class Foo < ::T::Struct
              # -:2:2-2:13
              const :a, A
              # -:3:2-3:29
              const :b, B, default: B.new
              # -:4:2-4:12
              prop :c, C
              # -:5:2-5:28
              prop :d, D, default: D.new
              # -:6:2-6:14
              def foo; end
            end
          RBI
        end

        it("builds T::Enum") do
          rbi = <<~RBI
            class Foo < ::T::Enum
              enums do
                A = new
                B = new
                C = new
              end
              def baz; end
            end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string(print_locs: true))
            # -:1:0-8:3
            class Foo < ::T::Enum
              # -:2:2-6:5
              enums do
                A = new
                B = new
                C = new
              end
              # -:7:2-7:14
              def baz; end
            end
          RBI
        end

        it("builds Sorbet's helpers") do
          rbi = <<~RBI
            class Foo
              abstract!
              sealed!
              interface!
              mixes_in_class_methods A
            end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string(print_locs: true))
            # -:1:0-6:3
            class Foo
              # -:2:2-2:11
              abstract!
              # -:3:2-3:9
              sealed!
              # -:4:2-4:12
              interface!
              # -:5:2-5:26
              mixes_in_class_methods A
            end
          RBI
        end

        it("builds Sorbet's type members and templates") do
          rbi = <<~RBI
            class Foo
              A = type_member
              B = type_template
            end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string(print_locs: true))
            # -:1:0-4:3
            class Foo
              # -:2:2-2:17
              A = type_member
              # -:3:2-3:19
              B = type_template
            end
          RBI
        end
      end

      describe("can parse rbi with comments") do
        it("parses comments in empty files") do
          rbi = <<~RBI
            # typed: false
            # frozen_string_literal: true

            # Some header
            # comments
            # on multiple lines
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string)
            # typed: false
            # frozen_string_literal: true
            # Some header
            # comments
            # on multiple lines
          RBI
        end

        it("parses header comments") do
          rbi = <<~RBI
            # A comment
            module A
              # B comment
              class B
                # c comment
                def c; end

                # d comment
                attr_reader :a

                # E comment
                E = _
              end
            end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end

        it("parses multiline comments") do
          rbi = <<~RBI
            # Foo 1
            # Foo 2
            # Foo 3
            module Foo
              # Bar 1
              # Bar 2
              # Bar 3
              class Bar; end
            end
          RBI

          out = RBI::Parser.parse_string(rbi)
          assert_equal(rbi, out.string)
        end

        it("parses trailing comments and moves them in header") do
          rbi = <<~RBI
            # A comment 1
            # A comment 2
            module A
              # B comment
              class B; end
              # A comment 3
            end
          RBI
          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string)
            # A comment 1
            # A comment 2
            # A comment 3
            module A
              # B comment
              class B; end
            end
          RBI
        end

        it("parses comments and discards orphans") do
          rbi = <<~RBI
            module A; end
            # Orphan comment
          RBI
          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string)
            module A; end
          RBI
        end

        it("parses params comments") do
          rbi = <<~RBI
            def bar; end
            def foo(
              a, # `a` comment
                 # `b` comment 1
              b, # `b` comment 2
              c:, # `c` comment
                  # `d` comment 1
              d:, # `d` comment 2
              e: _
            ); end
          RBI
          out = RBI::Parser.parse_string(rbi)
          assert_equal(<<~RBI, out.string)
            def bar; end

            def foo(
              a, # `a` comment
              b, # `b` comment 1
                 # `b` comment 2
              c:, # `c` comment
              d:, # `d` comment 1
                  # `d` comment 2
              e: _
            ); end
          RBI
        end
      end
    end
  end
end
