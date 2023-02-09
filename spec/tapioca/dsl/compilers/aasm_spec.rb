# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class AASMSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::AASM" do
          describe "initialize" do
            it "gathers no constants if there are no classes that include AASM" do
              assert_empty(gathered_constants)
            end

            it "gathers only classes that include AASM" do
              add_ruby_file("content.rb", <<~RUBY)
                class StateMachine
                  include AASM
                  aasm { state :existing, initial: true }
                end
              RUBY

              assert_equal(["StateMachine"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates empty RBI when AASM is included but no AASM call has been made" do
              add_ruby_file("content.rb", <<~RUBY)
                class StateMachine
                  include AASM
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:StateMachine))
            end

            it "generates correct RBI file" do
              add_ruby_file("content.rb", <<~RUBY)
                class StateMachine
                  include AASM
                  extend T::Sig

                  aasm do
                    state :sleeping, initial: true
                    state :running, :cleaning

                    event :run do
                      before { before_run }
                      transitions from: :sleeping, to: :running
                    end
                  end

                  private

                  sig { void }
                  def before_run; end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class StateMachine
                  sig { returns(T::Boolean) }
                  def cleaning?; end

                  sig { returns(T::Boolean) }
                  def may_run?; end

                  sig { params(opts: T.untyped).returns(T.untyped) }
                  def run(*opts); end

                  sig { params(opts: T.untyped).returns(T.untyped) }
                  def run!(*opts); end

                  sig { params(opts: T.untyped).returns(T.untyped) }
                  def run_without_validation!(*opts); end

                  sig { returns(T::Boolean) }
                  def running?; end

                  sig { returns(T::Boolean) }
                  def sleeping?; end

                  class << self
                    sig { params(args: T.untyped, block: T.nilable(T.proc.bind(PrivateAASMMachine).void)).returns(PrivateAASMMachine) }
                    def aasm(*args, &block); end
                  end

                  class PrivateAASMMachine < AASM::Base
                    sig { params(name: T.untyped, options: T.untyped, block: T.proc.bind(PrivateAASMEvent).void).returns(T.untyped) }
                    def event(name, options = nil, &block); end

                    class PrivateAASMEvent < AASM::Core::Event
                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def after(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def after_commit(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def after_transaction(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def before(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def before_success(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def before_transaction(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def ensure(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def error(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def success(symbol = nil, &block); end
                    end
                  end

                  STATE_CLEANING = T.let(T.unsafe(nil), Symbol)
                  STATE_RUNNING = T.let(T.unsafe(nil), Symbol)
                  STATE_SLEEPING = T.let(T.unsafe(nil), Symbol)
                end
              RBI

              assert_equal(expected, rbi_for(:StateMachine))
            end

            it "generates correct RBI file with custom and default aasm names" do
              add_ruby_file("content.rb", <<~RUBY)
                class StateMachine
                  include AASM
                  extend T::Sig

                  aasm(:status) do
                    state :sleeping, initial: true
                    state :running, :cleaning

                    event :run do
                      before { before_run }
                      transitions from: :sleeping, to: :running
                    end
                  end

                  aasm do
                    state  :existing, initial: true
                  end

                  private

                  sig { void }
                  def before_run; end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class StateMachine
                  sig { returns(T::Boolean) }
                  def cleaning?; end

                  sig { returns(T::Boolean) }
                  def existing?; end

                  sig { returns(T::Boolean) }
                  def may_run?; end

                  sig { params(opts: T.untyped).returns(T.untyped) }
                  def run(*opts); end

                  sig { params(opts: T.untyped).returns(T.untyped) }
                  def run!(*opts); end

                  sig { params(opts: T.untyped).returns(T.untyped) }
                  def run_without_validation!(*opts); end

                  sig { returns(T::Boolean) }
                  def running?; end

                  sig { returns(T::Boolean) }
                  def sleeping?; end

                  class << self
                    sig { params(args: T.untyped, block: T.nilable(T.proc.bind(PrivateAASMMachine).void)).returns(PrivateAASMMachine) }
                    def aasm(*args, &block); end
                  end

                  class PrivateAASMMachine < AASM::Base
                    sig { params(name: T.untyped, options: T.untyped, block: T.proc.bind(PrivateAASMEvent).void).returns(T.untyped) }
                    def event(name, options = nil, &block); end

                    class PrivateAASMEvent < AASM::Core::Event
                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def after(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def after_commit(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def after_transaction(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def before(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def before_success(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def before_transaction(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def ensure(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def error(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def success(symbol = nil, &block); end
                    end
                  end

                  STATE_CLEANING = T.let(T.unsafe(nil), Symbol)
                  STATE_EXISTING = T.let(T.unsafe(nil), Symbol)
                  STATE_RUNNING = T.let(T.unsafe(nil), Symbol)
                  STATE_SLEEPING = T.let(T.unsafe(nil), Symbol)
                end
              RBI

              assert_equal(expected, rbi_for(:StateMachine))
            end

            it "generates correct RBI file with namespace" do
              add_ruby_file("content.rb", <<~RUBY)
                class StateMachine
                  include AASM
                  extend T::Sig

                  aasm(namespace: :foo) do
                    state :sleeping, initial: true
                    state :running, :cleaning

                    event :run do
                      before { before_run }
                      transitions from: :sleeping, to: :running
                    end
                  end

                  private

                  sig { void }
                  def before_run; end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class StateMachine
                  sig { returns(T::Boolean) }
                  def foo_cleaning?; end

                  sig { returns(T::Boolean) }
                  def foo_running?; end

                  sig { returns(T::Boolean) }
                  def foo_sleeping?; end

                  sig { returns(T::Boolean) }
                  def may_run?; end

                  sig { returns(T::Boolean) }
                  def may_run_foo?; end

                  sig { params(opts: T.untyped).returns(T.untyped) }
                  def run(*opts); end

                  sig { params(opts: T.untyped).returns(T.untyped) }
                  def run!(*opts); end

                  sig { params(opts: T.untyped).returns(T.untyped) }
                  def run_foo(*opts); end

                  sig { params(opts: T.untyped).returns(T.untyped) }
                  def run_foo!(*opts); end

                  sig { params(opts: T.untyped).returns(T.untyped) }
                  def run_without_validation!(*opts); end

                  class << self
                    sig { params(args: T.untyped, block: T.nilable(T.proc.bind(PrivateAASMMachine).void)).returns(PrivateAASMMachine) }
                    def aasm(*args, &block); end
                  end

                  class PrivateAASMMachine < AASM::Base
                    sig { params(name: T.untyped, options: T.untyped, block: T.proc.bind(PrivateAASMEvent).void).returns(T.untyped) }
                    def event(name, options = nil, &block); end

                    class PrivateAASMEvent < AASM::Core::Event
                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def after(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def after_commit(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def after_transaction(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def before(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def before_success(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def before_transaction(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def ensure(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def error(symbol = nil, &block); end

                      sig { params(symbol: T.nilable(Symbol), block: T.nilable(T.proc.bind(StateMachine).void)).returns(T.untyped) }
                      def success(symbol = nil, &block); end
                    end
                  end

                  STATE_FOO_CLEANING = T.let(T.unsafe(nil), Symbol)
                  STATE_FOO_RUNNING = T.let(T.unsafe(nil), Symbol)
                  STATE_FOO_SLEEPING = T.let(T.unsafe(nil), Symbol)
                end
              RBI

              assert_equal(expected, rbi_for(:StateMachine))
            end
          end
        end
      end
    end
  end
end
