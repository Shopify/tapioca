# typed: strict
# frozen_string_literal: true

begin
  require "action_view/test_case"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::ActionViewTestHelpers` decorates RBI files for all
      # subclasses of `ActionView::TestCase` with the helpers that are included dynamically.
      #
      # For example, considering the `UsersHelper` module:
      #
      # ~~~rb
      # module UsersHelper
      #   def current_user_name
      #     # ...
      #   end
      # end
      # ~~~
      #
      # and its respective test:
      #
      # ~~~rb
      # class UsersHelperTest < ActionView::TestCase
      #   test "current_user_name works" do
      #     assert_equal("John", current_user_name)
      #   end
      # end
      # ~~~
      #
      # this generator will produce an RBI file `users_helper_test.rbi` with the following content:
      #
      # ~~~rbi
      # # users_helper_test.rbi
      # # typed: strong
      # class UsersHelperTest
      #   include HelperMethods
      #
      #   module HelperMethods
      #     include ::UsersHelper
      #   end
      # end
      # ~~~
      class ActionViewTestHelpers < Base
        extend T::Sig

        sig do
          override
            .params(root: RBI::Tree, constant: T.class_of(ActionView::TestCase))
            .void
        end
        def decorate(root, constant)
          # The helpers are dynamically included in the class when the test is instantiated. The argument for
          # initializing the method is just the test name. All of the helper modules are included in the module inside
          # _helpers, so we can filter the ancestors based on their names and find all helpers
          fake_test = constant.new("fake")
          helpers_included = fake_test._helpers.ancestors.select { |mod| mod.name&.end_with?("Helper") }
          helper_methods_name = "HelperMethods"

          root.create_path(constant) do |klass|
            klass.create_include(helper_methods_name)

            klass.create_module(helper_methods_name) do |helper_methods|
              helpers_included.each do |helper|
                helper_methods.create_include(T.must(qualified_name_of(helper)))
              end
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          descendants_of(ActionView::TestCase)
        end
      end
    end
  end
end
