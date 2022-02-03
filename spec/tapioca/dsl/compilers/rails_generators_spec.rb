# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class RailsGeneratorsSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::RailsGenerators" do
          describe "initialize" do
            it "gathers no constants if there are no Rails generator classes" do
              assert_empty(gathered_constants)
            end

            it "gathers only Rails generators" do
              add_ruby_file("content.rb", <<~RUBY)
                class UnnamedGenerator < Rails::Generators::Base
                end

                class NamedGenerator < Rails::Generators::NamedBase
                end

                class AppGenerator < Rails::Generators::AppBase
                end

                class SomethingElse
                end

                module Entirely
                end
              RUBY

              assert_equal(["AppGenerator", "NamedGenerator", "UnnamedGenerator"], gathered_constants)
            end

            it "does not gather XPath" do
              add_ruby_file("xpath.rb", <<~RUBY)
                require "xpath"
              RUBY

              assert_empty(gathered_constants)
            end

            it "ignores generator classes without a name" do
              add_ruby_file("content.rb", <<~RUBY)
                unnamed = Class.new(::Rails::Generators::Base)
                named = Class.new(::Rails::Generators::NamedBase)
                app = Class.new(::Rails::Generators::AppBase)
              RUBY

              assert_empty(gathered_constants)
            end
          end

          describe "decorate" do
            it "generates empty RBI file if there are no extra arguments or options" do
              add_ruby_file("contents.rb", <<~RUBY)
                class EmptyGenerator < ::Rails::Generators::Base
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:EmptyGenerator))
            end

            it "generates an RBI file for arguments" do
              add_ruby_file("contents.rb", <<~RUBY)
                class ArgumentGenerator < ::Rails::Generators::Base
                  argument :string, type: :string
                  argument :hash, type: :hash
                  argument :array, type: :array
                  argument :numeric, type: :numeric
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class ArgumentGenerator
                  sig { returns(T::Array[::String]) }
                  def array; end

                  sig { returns(T::Hash[::String, ::String]) }
                  def hash; end

                  sig { returns(::Numeric) }
                  def numeric; end

                  sig { returns(::String) }
                  def string; end
                end
              RBI

              assert_equal(expected, rbi_for(:ArgumentGenerator))
            end

            it "generates an RBI file for class options" do
              add_ruby_file("contents.rb", <<~RUBY)
                class OptionGenerator < ::Rails::Generators::Base
                  class_option :string, type: :string
                  class_option :hash, type: :hash
                  class_option :array, type: :array
                  class_option :numeric, type: :numeric
                  class_option :bool, type: :boolean
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class OptionGenerator
                  sig { returns(T.nilable(T::Array[::String])) }
                  def array; end

                  sig { returns(T.nilable(T::Boolean)) }
                  def bool; end

                  sig { returns(T.nilable(T::Hash[::String, ::String])) }
                  def hash; end

                  sig { returns(T.nilable(::Numeric)) }
                  def numeric; end

                  sig { returns(T.nilable(::String)) }
                  def string; end
                end
              RBI

              assert_equal(expected, rbi_for(:OptionGenerator))
            end

            it "generates an RBI file for required and optional-with-defaults class options" do
              add_ruby_file("contents.rb", <<~RUBY)
                class OptionsWithDefaultsGenerator < ::Rails::Generators::Base
                  class_option :string, type: :string, required: true
                  class_option :array, type: :array, required: false, default: []
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class OptionsWithDefaultsGenerator
                  sig { returns(T::Array[::String]) }
                  def array; end

                  sig { returns(::String) }
                  def string; end
                end
              RBI

              assert_equal(expected, rbi_for(:OptionsWithDefaultsGenerator))
            end

            it "generates an RBI file for overriding built-in options" do
              add_ruby_file("contents.rb", <<~RUBY)
                class OverrideGenerator < ::Rails::Generators::Base
                  class_option :force, type: :numeric
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class OverrideGenerator
                  sig { returns(T.nilable(::Numeric)) }
                  def force; end
                end
              RBI

              assert_equal(expected, rbi_for(:OverrideGenerator))
            end

            it "generates an RBI file for non-Rails parent class arguments and options" do
              add_ruby_file("contents.rb", <<~RUBY)
                class ParentGenerator < ::Rails::Generators::NamedBase
                  argument :str, type: :string
                  class_option :number, type: :numeric
                end

                class ChildGenerator < ParentGenerator
                  argument :child_arg, type: :string
                  class_option :child_opt, type: :string
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class ChildGenerator
                  sig { returns(::String) }
                  def child_arg; end

                  sig { returns(T.nilable(::String)) }
                  def child_opt; end

                  sig { returns(T.nilable(::Numeric)) }
                  def number; end

                  sig { returns(::String) }
                  def str; end
                end
              RBI

              assert_equal(expected, rbi_for(:ChildGenerator))
            end
          end
        end
      end
    end
  end
end
