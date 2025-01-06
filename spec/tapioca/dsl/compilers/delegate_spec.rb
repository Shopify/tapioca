# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class DelegateSpec < ::DslSpec
        describe "Tapoca::Dsl::Compilers::Delegate" do
          sig { void }
          def before_setup
            require "tapioca/dsl/extensions/delegate"
            require "active_support/core_ext/module/delegation"
          end

          describe "initialize" do
            it "gathers any module that includes a call to `delegate`" do
              add_ruby_file("content.rb", <<~RUBY)
                class Delegate
                  delegate :method, to: :target
                end
              RUBY

              assert_equal(["Delegate"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates correct RBI for a simple delegation" do
              add_ruby_file("content.rb", <<~RUBY)
                class Target
                  extend T::Sig

                  sig { params(int: Integer).returns(Integer) }
                  def param_method(int) = int

                  sig { returns(String) }
                  attr_reader :string_method

                  sig { void }
                  def void_method; end
                end

                class Delegate
                  extend T::Sig

                  sig { returns(Target) }
                  attr_reader :target

                  delegate :param_method, :string_method, :void_method, to: :target
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Delegate
                  sig { params(int: ::Integer).returns(::Integer) }
                  def param_method(int); end

                  sig { returns(::String) }
                  def string_method; end

                  sig { void }
                  def void_method; end
                end
              RBI

              assert_equal(expected, rbi_for(:Delegate))
            end

            it "generates correct RBI for multiple delegations" do
              add_ruby_file("content.rb", <<~RUBY)
                class Target
                  extend T::Sig

                  sig { returns(String) }
                  attr_reader :string_method
                end

                class Target2
                  extend T::Sig
                  sig { returns(Integer) }
                  attr_reader :int_method
                end

                class Delegate
                  extend T::Sig

                  sig { returns(Target) }
                  attr_reader :target

                  sig { returns(Target2) }
                  attr_reader :target2

                  delegate :string_method, to: :target
                  delegate :int_method, to: :target2
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Delegate
                  sig { returns(::Integer) }
                  def int_method; end

                  sig { returns(::String) }
                  def string_method; end
                end
              RBI

              assert_equal(expected, rbi_for(:Delegate))
            end

            it "places private delegates in the private section" do
              add_ruby_file("content.rb", <<~RUBY)
                class Target
                  extend T::Sig

                  sig { returns(String) }
                  def string_method; end
                end

                class Delegate
                  extend T::Sig
                  sig { returns(Target) }
                  attr_reader :target

                  delegate :string_method, to: :target, private: true
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Delegate
                  private

                  sig { returns(::String) }
                  def string_method; end
                end
              RBI

              assert_equal(expected, rbi_for(:Delegate))
            end

            it "generates correct RBI for a delegation with prefix" do
              add_ruby_file("content.rb", <<~RUBY)
                class Target
                  extend T::Sig

                  sig { returns(String) }
                  def string_method; end
                end

                class Delegate
                  extend T::Sig
                  sig { returns(Target) }
                  attr_reader :target

                  delegate :string_method, to: :target, prefix: "target"
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Delegate
                  sig { returns(::String) }
                  def target_string_method; end
                end
              RBI

              assert_equal(expected, rbi_for(:Delegate))
            end

            it "generates correct RBI for delegation with allow_nil" do
              add_ruby_file("content.rb", <<~RUBY)
                class Target
                  extend T::Sig

                  sig { returns(String) }
                  def string_method; end
                end

                class Delegate
                  extend T::Sig
                  sig { returns(T.nilable(Target)) }
                  attr_reader :target

                  delegate :string_method, to: :target, allow_nil: true
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Delegate
                  sig { returns(T.nilable(::String)) }
                  def string_method; end
                end
              RBI

              assert_equal(expected, rbi_for(:Delegate))
            end

            it "does not generate RBI for delegations to non-statically typed objects" do
              add_ruby_file("content.rb", <<~RUBY)
                class Delegate
                  extend T::Sig

                  @@string = T.let("world", String)

                  CONSTANT = T.let(1, Integer)

                  delegate :string_method, to: :@target
                  delegate :size, to: :@@string
                  delegate :succ, to: :CONSTANT

                  def initialize
                    @target = Target.new
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Delegate; end
              RBI

              assert_equal(expected, rbi_for(:Delegate))
            end

            it "generates correct RBI for delegations to it's own class" do
              add_ruby_file("content.rb", <<~RUBY)
                class Delegate
                  extend T::Sig

                  class << self
                    extend T::Sig

                    sig { returns(String) }
                    def string_method; end
                  end

                  delegate :string_method, to: :class
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Delegate
                  sig { returns(::String) }
                  def string_method; end
                end
              RBI

              assert_equal(expected, rbi_for(:Delegate))
            end

            it "generates correct RBI for delegations to singleton methods of other classes" do
              add_ruby_file("content.rb", <<~RUBY)
                class Target
                  extend T::Sig

                  sig { returns(String) }
                  def self.string_method; end
                end

                class Delegate
                  extend T::Sig

                  delegate :string_method, to: :Target
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Delegate
                  sig { returns(::String) }
                  def string_method; end
                end
              RBI

              assert_equal(expected, rbi_for(:Delegate))
            end

            it "generates untyped delegates if the type of the target is untyped" do
              add_ruby_file("content.rb", <<~RUBY)
                class Target
                  def param_method(int) = int
                  def string_method; end
                end

                class Delegate
                  extend T::Sig

                  sig { returns(Target) }
                  attr_reader :target

                  delegate :string_method, :param_method, to: :target
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Delegate
                  sig { params(int: T.untyped).returns(T.untyped) }
                  def param_method(int); end

                  sig { returns(T.untyped) }
                  def string_method; end
                end
              RBI

              assert_equal(expected, rbi_for(:Delegate))
            end
          end
        end
      end
    end
  end
end
