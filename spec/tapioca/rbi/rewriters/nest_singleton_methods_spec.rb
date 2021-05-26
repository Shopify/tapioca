# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module RBI
    class NestSingletonMethodsSpec < Minitest::HooksSpec
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
    end
  end
end
