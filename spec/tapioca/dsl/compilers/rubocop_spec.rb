# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class RuboCopSpec < ::DslSpec
        class << self
          extend T::Sig

          sig { override.returns(String) }
          def target_class_file
            # Against convention, RuboCop uses "rubocop" in its file names, so we do too.
            super.gsub("rubo_cop", "rubocop")
          end
        end

        describe "Tapioca::Dsl::Compilers::RuboCop" do
          sig { void }
          def before_setup
            require "rubocop"
            require "rubocop-sorbet"
            require "tapioca/dsl/extensions/rubocop"
            super
          end

          describe "initialize" do
            it "gathered constants exclude irrelevant classes" do
              gathered_constants = gather_constants do
                add_ruby_file("content.rb", <<~RUBY)
                  class Unrelated
                  end
                RUBY
              end
              assert_empty(gathered_constants)
            end

            it "gathers constants extending RuboCop::AST::NodePattern::Macros in gems" do
              # Sample of miscellaneous constants that should be found from Rubocop and plugins
              missing_constants = [
                "RuboCop::Cop::Bundler::GemVersion",
                "RuboCop::Cop::Cop",
                "RuboCop::Cop::Gemspec::DependencyVersion",
                "RuboCop::Cop::Lint::Void",
                "RuboCop::Cop::Metrics::ClassLength",
                "RuboCop::Cop::Migration::DepartmentName",
                "RuboCop::Cop::Naming::MethodName",
                "RuboCop::Cop::Security::CompoundHash",
                "RuboCop::Cop::Sorbet::ValidSigil",
                "RuboCop::Cop::Style::YodaCondition",
              ] - gathered_constants

              assert_empty(missing_constants, "expected constants to be gathered")
            end

            it "gathers constants extending RuboCop::AST::NodePattern::Macros in the host app" do
              gathered_constants = gather_constants do
                add_ruby_file("content.rb", <<~RUBY)
                  class MyCop < ::RuboCop::Cop::Base
                  end

                  class MyLegacyCop < ::RuboCop::Cop::Cop
                  end

                  module MyMacroModule
                    extend ::RuboCop::AST::NodePattern::Macros
                  end

                  module ::RuboCop
                    module Cop
                      module MyApp
                        class MyNamespacedCop < Base
                        end
                      end
                    end
                  end
                RUBY
              end

              assert_equal(
                ["MyCop", "MyLegacyCop", "MyMacroModule", "RuboCop::Cop::MyApp::MyNamespacedCop"],
                gathered_constants,
              )
            end
          end

          describe "decorate" do
            it "generates empty RBI when no DSL used" do
              add_ruby_file("content.rb", <<~RUBY)
                class MyCop < ::RuboCop::Cop::Base
                  def on_send(node);end
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:MyCop))
            end

            it "generates correct RBI file" do
              add_ruby_file("content.rb", <<~RUBY)
                class MyCop < ::RuboCop::Cop::Base
                  def_node_matcher :some_matcher, "(...)"
                  def_node_matcher :some_matcher_with_params, "(%1 %two ...)"
                  def_node_matcher :some_matcher_with_params_and_defaults, "(%1 %two ...)", two: :default
                  def_node_matcher :some_predicate_matcher?, "(...)"
                  def_node_search :some_search, "(...)"
                  def_node_search :some_search_with_params, "(%1 %two ...)"
                  def_node_search :some_search_with_params_and_defaults, "(%1 %two ...)", two: :default

                  def on_send(node);end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class MyCop
                  sig { params(param0: T.untyped).returns(T.untyped) }
                  def some_matcher(param0 = T.unsafe(nil)); end

                  sig { params(param0: T.untyped, param1: T.untyped, two: T.untyped).returns(T.untyped) }
                  def some_matcher_with_params(param0 = T.unsafe(nil), param1, two:); end

                  sig { params(args: T.untyped, values: T.untyped).returns(T.untyped) }
                  def some_matcher_with_params_and_defaults(*args, **values); end

                  sig { params(param0: T.untyped).returns(T.untyped) }
                  def some_predicate_matcher?(param0 = T.unsafe(nil)); end

                  sig { params(param0: T.untyped).returns(T.untyped) }
                  def some_search(param0); end

                  sig { params(param0: T.untyped, param1: T.untyped, two: T.untyped).returns(T.untyped) }
                  def some_search_with_params(param0, param1, two:); end

                  sig { params(args: T.untyped, values: T.untyped).returns(T.untyped) }
                  def some_search_with_params_and_defaults(*args, **values); end

                  sig { params(param0: T.untyped, param1: T.untyped, two: T.untyped).returns(T.untyped) }
                  def without_defaults_some_matcher_with_params_and_defaults(param0 = T.unsafe(nil), param1, two:); end

                  sig { params(param0: T.untyped, param1: T.untyped, two: T.untyped).returns(T.untyped) }
                  def without_defaults_some_search_with_params_and_defaults(param0, param1, two:); end
                end
              RBI

              assert_equal(expected, rbi_for(:MyCop))
            end
          end

          private

          # Gathers constants introduced in the given block excluding constants that already existed prior to the block.
          sig { params(block: T.proc.void).returns(T::Array[String]) }
          def gather_constants(&block)
            existing_constants = T.let(
              Runtime::Reflection
                .extenders_of(::RuboCop::AST::NodePattern::Macros)
                .filter_map { |constant| Runtime::Reflection.name_of(constant) },
              T::Array[String],
            )
            yield
            gathered_constants - existing_constants
          end
        end
      end
    end
  end
end
