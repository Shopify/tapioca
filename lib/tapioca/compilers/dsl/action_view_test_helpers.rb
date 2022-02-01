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
          # The helpers are dynamically included in the helpers module when `include_helper_modules!` is called.
          constant.send(:include_helper_modules!)
          helpers_module = constant._helpers

          helper_methods_name = "HelperMethods"

          root.create_path(constant) do |klass|
            klass.create_module(helper_methods_name) do |helper_methods|
              # Find all the included helper modules and generate an include
              # for each of those helper modules
              gather_includes(helpers_module).each do |helper_module_name|
                helper_methods.create_include(helper_module_name)
              end

              # Generate a method definition in the helper module for each
              # helper method defined via the `helper_method` call in the test case.
              helpers_module.instance_methods(false).each do |method_name|
                helper_methods.create_method(
                  method_name.to_s,
                  parameters: [
                    create_rest_param("args", type: "T.untyped"),
                    create_kw_rest_param("kwargs", type: "T.untyped"),
                    create_block_param("blk", type: "T.untyped"),
                  ],
                  return_type: "T.untyped"
                )
              end
            end

            klass.create_include(helper_methods_name)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          descendants_of(ActionView::TestCase)
        end

        private

        sig { params(mod: Module).returns(T::Array[String]) }
        def gather_includes(mod)
          mod.ancestors
            .reject { |ancestor| ancestor.is_a?(Class) || ancestor == mod || name_of(ancestor).nil? }
            .map { |ancestor| T.must(qualified_name_of(ancestor)) }
            .reverse
        end
      end
    end
  end
end
