# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActionViewTestHelpersSpec < DslSpec
  describe("#initialize") do
    after(:each) do
      T.unsafe(self).assert_no_generated_errors
    end

    it("doesn't gather anything if there are no ActionView::TestCase tests") do
      assert_empty(gathered_constants)
    end

    it("gathers ActionView::TestCase tests") do
      add_ruby_file("users_helper_test.rb", <<~RUBY)
        class UsersHelperTest < ActionView::TestCase
        end
      RUBY

      assert_equal(["UsersHelperTest"], gathered_constants)
    end
  end

  describe("#decorate") do
    after(:each) do
      T.unsafe(self).assert_no_generated_errors
    end

    it("generates a module with all dynamic helper inclusions") do
      add_ruby_file("users_helper.rb", <<~RUBY)
        module UsersHelper
          def current_user_name
            "John"
          end
        end
      RUBY

      add_ruby_file("users_helper_test.rb", <<~RUBY)
        class UsersHelperTest < ActionView::TestCase
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class UsersHelperTest
          include HelperMethods

          module HelperMethods
            include ::UsersHelper
          end
        end
      RBI

      assert_equal(expected, rbi_for(:UsersHelperTest))
    end
  end
end
