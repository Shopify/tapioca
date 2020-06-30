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
      # subclasses of `::ActionController::Base`
      # to add helper methods (see https://api.rubyonrails.org/classes/ActionController/Helpers.html).
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
      #
      # this generator will produce an RBI file `user_controller.rbi` with the following content:
      #
      # ~~~rbi
      # # user_controller.rbi
      # # typed: strong
      # class UserController
      #   sig { returns(UserController::HelperProxy) }
      #   def helpers; end
      # end
      #
      # module UserController::HelperMethods
      #    include MyHelper
      #
      #    sig { params(user: T.untyped).returns(T.untyped) }
      #    def age(user); end
      #
      #    sig { returns(T.untyped) }
      #    def current_user_name; end
      #  end
      #
      # class UserController::HelperProxy < ::ActionView::Base
      #   include UserController::HelperMethods
      # end
      # ~~~
      class ActionControllerHelpers < Base
        extend T::Sig

        sig do
          override
            .params(root: Parlour::RbiGenerator::Namespace, constant: T.class_of(::ActionController::Base))
            .void
        end
        def decorate(root, constant)
          helper_proxy_name = "#{constant}::HelperProxy"
          helper_methods_name = "#{constant}::HelperMethods"
          proxied_helper_methods = constant._helper_methods.map(&:to_s).map(&:to_sym)

          # Create helper method module
          root.create_module(helper_methods_name) do |helper_methods|
            helpers_module = constant._helpers

            gather_includes(helpers_module).each do |ancestor|
              helper_methods.create_include(ancestor)
            end

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
          root.create_class(helper_proxy_name, superclass: "::ActionView::Base") do |proxy|
            proxy.create_include(helper_methods_name)
          end

          # Define the helpers method
          root.path(constant) do |controller|
            create_method(controller, 'helpers', return_type: helper_proxy_name)
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          ::ActionController::Base.descendants.reject(&:abstract?)
        end

        private

        sig { params(mod: Module).returns(T::Array[String]) }
        def gather_includes(mod)
          mod.ancestors
            .reject { |ancestor| ancestor.is_a?(Class) || ancestor == mod || ancestor.name.nil? }
            .map { |ancestor| T.must(ancestor.name) }
            .reverse
        end
      end
    end
  end
end
