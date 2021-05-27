# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module RBI
    class NestNonPublicMethodsSpec < Minitest::HooksSpec
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
    end
  end
end
