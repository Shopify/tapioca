# typed: strict
# frozen_string_literal: true

return unless defined?(ActionController::Base)

require "tapioca/dsl/helpers/helper_methods_helper"

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::ActionControllerHelpers` decorates RBI files for all
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
      # this compiler will produce an RBI file `user_controller.rbi` with the following content:
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
      #
      # A controller whose parent controller has helpers includes the parent's `HelperMethods` and only the helper
      # modules it adds, so with the following controller:
      #
      # ~~~rb
      # class AdminController < UserController
      #   helper AdminHelper
      # end
      # ~~~
      #
      # this compiler will produce an RBI file `admin_controller.rbi` with the following content:
      #
      # ~~~rbi
      # # admin_controller.rbi
      # # typed: strong
      # class AdminController
      #   module HelperMethods
      #     include ::UserController::HelperMethods
      #     include ::AdminHelper
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
      #: [ConstantType = singleton(::ActionController::Base)]
      class ActionControllerHelpers < Compiler
        include Helpers::HelperMethodsHelper

        # @override
        #: -> void
        def decorate
          helper_proxy_name = "HelperProxy"

          # Define the helpers method
          root.create_path(constant) do |controller|
            controller.create_method("helpers", return_type: helper_proxy_name)

            # Create helper method module
            create_helper_methods_module(controller, constant, base: ::ActionController::Base)

            # Create helper proxy class
            controller.create_class(helper_proxy_name, superclass_name: "::ActionView::Base") do |proxy|
              proxy.create_include("HelperMethods")
            end
          end
        end

        class << self
          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            descendants_of(::ActionController::Base).select(&:name).select do |klass|
              klass.const_defined?(:HelperMethods, false)
            end
          end
        end
      end
    end
  end
end
