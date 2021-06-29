# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module RBI
    class MergeSpec < Minitest::HooksSpec
      describe("can merge nodes without conflicts together") do
        it("merges empty trees") do
          rbi1 = RBI::Tree.new
          rbi2 = RBI::Tree.new
          res = rbi1.merge(rbi2)
          assert_equal("", res.string)
        end

        it("merges empty tree into tree") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class Foo; end
          RBI

          rbi2 = RBI::Tree.new

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class Foo; end
          RBI
        end

        it("merges tree into empty tree") do
          rbi1 = RBI::Tree.new

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class Foo; end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class Foo; end
          RBI
        end

        it("merges scopes together") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A; end
            class B; end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class C; end
            class D; end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A; end
            class B; end
            class C; end
            class D; end
          RBI
        end

        it("merges nested scopes together") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A
              class B; end
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class C
              class D; end
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A
              class B; end
            end

            class C
              class D; end
            end
          RBI
        end

        it("merges same scopes together") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A
              class B; end
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class A
              class B; end
              class C; end
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A
              class B; end
              class C; end
            end
          RBI
        end

        it("merges constants together") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A
              A = 42
            end
            B = 42
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class A
              A = 42
              B = 42
            end
            B = 42
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A
              A = 42
              B = 42
            end

            B = 42
          RBI
        end

        it("merges attributes together") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A
              attr_reader :a
              attr_writer :a
              attr_accessor :b
              attr_reader :c, :d
              attr_writer :e
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class A
              attr_reader :a
              attr_writer :a
              attr_accessor :b
              attr_reader :c, :d
              attr_writer :f
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A
              attr_reader :a
              attr_writer :a
              attr_accessor :b
              attr_reader :c, :d
              attr_writer :e
              attr_writer :f
            end
          RBI
        end

        it("merges methods together") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A
              def a; end
              def b; end
              def c(a, b:, &d); end
              def d(a); end
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class A
              def a; end
              def b; end
              def c(a, b:, &d); end
              def e(a); end
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A
              def a; end
              def b; end
              def c(a, b:, &d); end
              def d(a); end
              def e(a); end
            end
          RBI
        end

        it("merges mixins together") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A
              include A
              extend B
              mixes_in_class_methods C
              include D, E, F
              include G
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class A
              include A
              extend B
              mixes_in_class_methods C
              include D, E, F
              include H
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A
              include A
              extend B
              mixes_in_class_methods C
              include D, E, F
              include G
              include H
            end
          RBI
        end

        it("merges helpers together") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A
              abstract!
              interface!
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class A
              interface!
              sealed!
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A
              abstract!
              interface!
              sealed!
            end
          RBI
        end

        it("merges structs together") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A < T::Struct
              prop :a, Integer
              const :b, Integer
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class A < T::Struct
              const :b, Integer
              prop :c, Integer
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A < T::Struct
              prop :a, Integer
              const :b, Integer
              prop :c, Integer
            end
          RBI
        end

        it("merges enums together") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A < T::Enum
              enums do
                A = new
                B = new
              end
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class A < T::Enum
              enums do
                B = new
                C = new
              end
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A < T::Enum
              enums do
                A = new
                B = new
                C = new
              end
            end
          RBI
        end

        it("merges signatures") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A
              def m1; end

              sig { void }
              def m2; end

              sig { returns(Integer) }
              def m3; end

              attr_reader :a1

              sig { void }
              attr_writer :a2

              sig { returns(Integer) }
              attr_accessor :a3
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class A
              sig { returns(Integer) }
              def m1; end

              def m2; end

              sig { returns(Integer) }
              def m3; end

              sig { returns(Integer) }
              attr_reader :a1

              attr_writer :a2

              sig { returns(Integer) }
              attr_accessor :a3
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A
              sig { returns(Integer) }
              def m1; end

              sig { void }
              def m2; end

              sig { returns(Integer) }
              def m3; end

              sig { returns(Integer) }
              attr_reader :a1

              sig { void }
              attr_writer :a2

              sig { returns(Integer) }
              attr_accessor :a3
            end
          RBI
        end

        it("merges comments") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            # Comment A1
            class A
              # Comment a1
              attr_reader :a
              # Comment m1
              def m; end
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            # Comment A1
            # Comment A2
            # Comment A3
            class A
              # Comment a2
              attr_reader :a
              # Comment m1
              # Comment m2
              def m; end
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            # Comment A1
            # Comment A2
            # Comment A3
            class A
              # Comment a1
              # Comment a2
              attr_reader :a

              # Comment m1
              # Comment m2
              def m; end
            end
          RBI
        end

        it("merges tree comments together") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            # typed: true

            # Some comments
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            # typed: true

            # Other comments
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            # typed: true
            # Some comments
            # Other comments
          RBI
        end
      end

      describe("can detect merge conflicts") do
        it("creates conflict tree for scopes") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class Foo
              A = 10
            end

            module Bar
              B = 10

              class Baz < Foo
                C = 10
              end
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            module Foo
              A = 10
            end

            class Bar
              B = 10

              class Baz < Bar
                C = 10
              end
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            <<<<<<< left
            class Foo
            =======
            module Foo
            >>>>>>> right
              A = 10
            end

            <<<<<<< left
            module Bar
            =======
            class Bar
            >>>>>>> right
              B = 10

              <<<<<<< left
              class Baz < Foo
              =======
              class Baz < Bar
              >>>>>>> right
                C = 10
              end
            end
          RBI
        end

        it("creates conflict tree for constants") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class Foo
              A = 10
            end
            B = 10
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class Foo
              A = 42
            end
            B = 42
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class Foo
              <<<<<<< left
              A = 10
              =======
              A = 42
              >>>>>>> right
            end
            <<<<<<< left
            B = 10
            =======
            B = 42
            >>>>>>> right
          RBI
        end

        it("creates conflict tree for constants & scopes") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A; end
            module B; end
            module C; end
            class D < A; end
            module E
              module F; end
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            module A; end
            class B; end
            C = 42
            class D; end
            module E::F; end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            <<<<<<< left
            class A; end
            =======
            module A; end
            >>>>>>> right
            <<<<<<< left
            module B; end
            =======
            class B; end
            >>>>>>> right
            <<<<<<< left
            module C; end
            =======
            C = 42
            >>>>>>> right
            <<<<<<< left
            class D < A; end
            =======
            class D; end
            >>>>>>> right

            module E
              module F; end
            end
          RBI
        end

        it("creates conflict tree for attributes") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class Foo
              attr_accessor :a
              attr_accessor :b
              attr_accessor :c, :d
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class Foo
              attr_reader :a
              attr_writer :b
              attr_accessor :c
              attr_accessor :d
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class Foo
              <<<<<<< left
              attr_accessor :a
              attr_accessor :b
              attr_accessor :c, :d
              =======
              attr_reader :a
              attr_writer :b
              attr_accessor :c
              attr_accessor :d
              >>>>>>> right
            end
          RBI
        end

        it("creates conflict tree for methods") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class Foo
              def m1; end
              def m2(a); end
              def m3(a); end
              def m4(a, b, c); end
              def m5(a = 10); end
              def m6(a); end
              def m7(&a); end
              def m8(a: nil); end
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class Foo
              def m1(a); end
              def m2; end
              def m3(b); end
              def m4(c, b, a); end
              def m5(a); end
              def m6(a:); end
              def m7(a); end
              def m8(a: 10); end
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class Foo
              <<<<<<< left
              def m1; end
              def m2(a); end
              def m3(a); end
              def m4(a, b, c); end
              def m5(a = 10); end
              def m6(a); end
              def m7(&a); end
              def m8(a: nil); end
              =======
              def m1(a); end
              def m2; end
              def m3(b); end
              def m4(c, b, a); end
              def m5(a); end
              def m6(a:); end
              def m7(a); end
              def m8(a: 10); end
              >>>>>>> right
            end
          RBI
        end

        it("creates conflict tree for mixins") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A
              include A, B
              extend A, B
              mixes_in_class_methods A, B
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class A
              include B
              extend B
              mixes_in_class_methods B
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A
              <<<<<<< left
              include A, B
              extend A, B
              mixes_in_class_methods A, B
              =======
              include B
              extend B
              mixes_in_class_methods B
              >>>>>>> right
            end
          RBI
        end

        it("creates conflict tree for structs") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class A < T::Struct
              prop :a, Integer
              const :b, Integer
              prop :c, Integer
              const :d, Integer, default: 10
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class A < T::Struct
              const :a, Integer
              prop :b, Integer
              prop :c, String
              const :d, Integer, default: 42
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class A < T::Struct
              <<<<<<< left
              prop :a, Integer
              const :b, Integer
              prop :c, Integer
              const :d, Integer, default: 10
              =======
              const :a, Integer
              prop :b, Integer
              prop :c, String
              const :d, Integer, default: 42
              >>>>>>> right
            end
          RBI
        end

        it("creates conflict tree for signatures") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class Foo
              sig { returns(Integer) }
              attr_reader :a

              sig { returns(Integer) }
              def m1; end

              sig { params(a: Integer).returns(Integer) }
              def m2(a); end

              sig { returns(Integer) }
              def m3; end
            end
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            class Foo
              sig { returns(String) }
              attr_reader :a

              sig { void }
              def m1; end

              sig { params(a: String).returns(Integer) }
              def m2(a); end

              sig { abstract.returns(Integer) }
              def m3; end
            end
          RBI

          res = rbi1.merge(rbi2)
          assert_equal(<<~RBI, res.string)
            class Foo
              <<<<<<< left
              sig { returns(Integer) }
              attr_reader :a

              sig { returns(Integer) }
              def m1; end

              sig { params(a: Integer).returns(Integer) }
              def m2(a); end

              sig { returns(Integer) }
              def m3; end
              =======
              sig { returns(String) }
              attr_reader :a

              sig { void }
              def m1; end

              sig { params(a: String).returns(Integer) }
              def m2(a); end

              sig { abstract.returns(Integer) }
              def m3; end
              >>>>>>> right
            end
          RBI
        end

        it("returns the list of conflicts") do
          rbi1 = RBI::Parser.parse_string(<<~RBI)
            class Foo
              A = 10
            end
            B = 10
          RBI

          rbi2 = RBI::Parser.parse_string(<<~RBI)
            module Foo
              A = 42
            end
            B = 42
          RBI

          rewriter = Rewriters::Merge.new
          rewriter.merge(rbi1)
          conflicts = rewriter.merge(rbi2)

          assert_equal(<<~STR.strip, conflicts.join("\n"))
            Conflicting definitions for `::Foo`
            Conflicting definitions for `::Foo::A`
            Conflicting definitions for `::B`
          STR
        end
      end
    end
  end
end
