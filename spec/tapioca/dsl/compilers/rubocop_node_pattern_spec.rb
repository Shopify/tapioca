# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class RubocopNodePatternSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::RubocopNodePattern" do
          #: -> void
          def before_setup
            require "rubocop"
          end

          describe "initialize" do
            it "gathers RuboCop::Cop::Base subclasses" do
              add_ruby_file("cop.rb", <<~RUBY)
                class TestCop < RuboCop::Cop::Base
                  def_node_matcher :using_bang?, <<~PATTERN
                    (send nil? :bang)
                  PATTERN
                end
              RUBY

              assert_includes(gathered_constants, "TestCop")
            end

            it "gathers subclasses that define only regular methods" do
              add_ruby_file("cop.rb", <<~RUBY)
                class PlainCop < RuboCop::Cop::Base
                  def on_send(node)
                  end
                end
              RUBY

              assert_includes(gathered_constants, "PlainCop")
            end
          end

          describe "decorate" do
            it "generates RBI for def_node_matcher with zero captures" do
              add_ruby_file("cop.rb", <<~RUBY)
                class MatcherCop < RuboCop::Cop::Base
                  def_node_matcher :bang_method?, <<~PATTERN
                    (send nil? :bang)
                  PATTERN
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class MatcherCop
                  sig { params(param0: ::RuboCop::AST::Node).returns(T::Boolean) }
                  def bang_method?(param0 = T.unsafe(nil)); end
                end
              RBI

              assert_equal(expected, rbi_for(:MatcherCop))
            end

            it "generates RBI for def_node_matcher with captures" do
              add_ruby_file("cop.rb", <<~RUBY)
                class CaptureCop < RuboCop::Cop::Base
                  def_node_matcher :captured_name, <<~PATTERN
                    (send nil? $_)
                  PATTERN
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class CaptureCop
                  sig { params(param0: ::RuboCop::AST::Node).returns(T.untyped) }
                  def captured_name(param0 = T.unsafe(nil)); end
                end
              RBI

              assert_equal(expected, rbi_for(:CaptureCop))
            end

            it "generates RBI for def_node_search predicate method" do
              add_ruby_file("cop.rb", <<~RUBY)
                class SearchCop < RuboCop::Cop::Base
                  def_node_search :has_lvar?, <<~PATTERN
                    (lvar _)
                  PATTERN
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class SearchCop
                  sig { params(param0: ::RuboCop::AST::Node).returns(T::Boolean) }
                  def has_lvar?(param0); end
                end
              RBI

              assert_equal(expected, rbi_for(:SearchCop))
            end

            it "generates RBI for def_node_search enumerator method" do
              add_ruby_file("cop.rb", <<~RUBY)
                class EnumSearchCop < RuboCop::Cop::Base
                  def_node_search :find_lvars, <<~PATTERN
                    (lvar $_)
                  PATTERN
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class EnumSearchCop
                  sig { params(param0: ::RuboCop::AST::Node, block: T.nilable(T.proc.params(node: ::RuboCop::AST::Node).void)).returns(T::Enumerator[::RuboCop::AST::Node]) }
                  def find_lvars(param0, &block); end
                end
              RBI

              assert_equal(expected, rbi_for(:EnumSearchCop))
            end

            it "handles extra pattern arguments" do
              add_ruby_file("cop.rb", <<~RUBY)
                class ExtraArgsCop < RuboCop::Cop::Base
                  def_node_matcher :method_call?, <<~PATTERN
                    (send nil? %1)
                  PATTERN
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class ExtraArgsCop
                  sig { params(param0: ::RuboCop::AST::Node, param1: T.untyped).returns(T::Boolean) }
                  def method_call?(param0 = T.unsafe(nil), param1); end
                end
              RBI

              assert_equal(expected, rbi_for(:ExtraArgsCop))
            end

            it "generates empty RBI for cop with no macro methods" do
              add_ruby_file("cop.rb", <<~RUBY)
                class EmptyCop < RuboCop::Cop::Base
                  def on_send(node)
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:EmptyCop))
            end
          end
        end
      end
    end
  end
end
