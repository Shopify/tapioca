# typed: strict
# frozen_string_literal: true

require "parlour"

begin
  require "action_controller"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      # `Tapioca::Compilers::Dsl::ActionControllerHelpers` decorates RBI files for all
      # subclasses of [`ActionController::Base`](https://api.rubyonrails.org/classes/ActionController/Helpers.html).
      #
      # For example, with the following `MyHelper` module:
      #
      # ~~~rb
      # module MyHelper
      #   def greet(user)
      #     # ...
      #   end
      #
      #  def localized_time
      #     # ...
      #   end
      # end
      # ~~~
      #
      # and the following controller:
      #
      # ~~~rb
      # class UserController < ActionController::Base
      #   helper MyHelper
      #   helper { def age(user) "99" end }
      #   helper_method :current_user_name
      #
      #   def current_user_name
      #     # ...
      #   end
      # end
      # ~~~
      #
      # this generator will produce an RBI file `user_controller.rbi` with the following content:
      #
      # ~~~rbi
      # # user_controller.rbi
      # # typed: strong
      # class UserController
      #   module HelperMethods
      #     include MyHelper
      #
      #     sig { params(user: T.untyped).returns(T.untyped) }
      #     def age(user); end
      #
      #     sig { returns(T.untyped) }
      #     def current_user_name; end
      #   end
      #
      #   class HelperProxy < ::ActionView::Base
      #     include HelperMethods
      #   end
      #
      #   sig { returns(HelperProxy) }
      #   def helpers; end
      # end
      # ~~~
      class ActionControllerHelpers < Base
        extend T::Sig

        sig do
          override
            .params(root: Parlour::RbiGenerator::Namespace, constant: Module)
            .void
        end
        def decorate(root, constant)
          if constant == ApplicationHelper
            root.path(constant) do |helper|
              gather_includes(ApplicationController._helpers).each do |ancestor|
                helper.create_include(ancestor)
              end
            end

            return
          end

          helper_proxy_name = "HelperProxy"
          helper_methods_name = "HelperMethods"
          proxied_helper_methods = constant._helper_methods.map(&:to_s).map(&:to_sym)

          # Define the helpers method
          root.path(constant) do |controller|
            create_method(controller, "helpers", return_type: helper_proxy_name)

            # Create helper method module
            controller.create_module(helper_methods_name) do |helper_methods|
              helpers_module = constant._helpers

              helper_methods.create_include("ApplicationHelper")

              helpers_module.instance_methods(false).each do |method_name|
                method = if proxied_helper_methods.include?(method_name)
                  constant.instance_method(method_name)
                else
                  helpers_module.instance_method(method_name)
                end
                create_method_from_def(helper_methods, method)
              end
            end

            # Create helper proxy class
            controller.create_class(helper_proxy_name, superclass: "::ActionView::Base") do |proxy|
              proxy.create_include(helper_methods_name)
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          [ApplicationHelper] +
            ::ActionController::Base.descendants.reject(&:abstract?).select(&:name)
        end

        private

        sig { params(mod: Module).returns(T::Array[String]) }
        def gather_includes(mod)
          mod.ancestors
            .reject { |ancestor| ancestor.is_a?(Class) || ancestor == mod || ancestor.name.nil? }
            .map { |ancestor| "::#{ancestor.name}" }
            .reverse
        end
      end
    end
  end
end
