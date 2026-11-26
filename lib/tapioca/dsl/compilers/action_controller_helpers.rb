# typed: strict
# frozen_string_literal: true

return unless defined?(ActionController::Base)

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
        # @override
        #: -> void
        def decorate
          helpers_module = constant._helpers
          proxied_helper_methods = constant._helper_methods.map(&:to_s).map(&:to_sym)

          helper_proxy_name = "HelperProxy"
          helper_methods_name = "HelperMethods"

          # Define the helpers method
          root.create_path(constant) do |controller|
            controller.create_method("helpers", return_type: helper_proxy_name)

            # Create helper method module
            controller.create_module(helper_methods_name) do |helper_methods|
              # If the controller has no helper defined, then it just inherits
              # the Action Controller base helper methods module, so we should
              # just add that as an include and stop doing more processing.
              if helpers_module.name == "ActionController::Base::HelperMethods"
                next helper_methods.create_include(T.must(qualified_name_of(helpers_module)))
              end

              # Generate an include for the parent controller's helper module
              # and each helper module this controller adds to it
              included_helper_modules(helpers_module).each do |ancestor|
                helper_methods.create_include(ancestor)
              end

              # Generate a method definition in the helper module for each
              # helper method defined via the `helper_method` call in the controller.
              helpers_module.instance_methods(false).each do |method_name|
                method = if proxied_helper_methods.include?(method_name)
                  helper_method_proxy_target(method_name)
                else
                  helpers_module.instance_method(method_name)
                end

                if method
                  create_method_from_def(helper_methods, method)
                else
                  create_unknown_proxy_method(helper_methods, method_name)
                end
              end
            end

            # Create helper proxy class
            controller.create_class(helper_proxy_name, superclass_name: "::ActionView::Base") do |proxy|
              proxy.create_include(helper_methods_name)
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

        private

        #: (Symbol method_name) -> UnboundMethod?
        def helper_method_proxy_target(method_name)
          # Lookup the proxy target method only if it is defined as a public/protected or private method.
          if constant.method_defined?(method_name) || constant.private_method_defined?(method_name)
            constant.instance_method(method_name)
          end
        end

        #: (RBI::Scope helper_methods, Symbol method_name) -> void
        def create_unknown_proxy_method(helper_methods, method_name)
          helper_methods.create_method(
            method_name.to_s,
            parameters: [
              create_rest_param("args", type: "T.untyped"),
              create_kw_rest_param("kwargs", type: "T.untyped"),
              create_block_param("blk", type: "T.untyped"),
            ],
            return_type: "T.untyped",
          )
        end

        # The modules to include in this controller's `HelperMethods`. When its parent controller's module is one
        # this compiler generates an RBI for, that module and the modules this controller adds to it: the parent's
        # RBI includes the rest. Otherwise (the parent is `ActionController::Base`, whose RBI can't know the helpers
        # that other gems add to it at runtime) every module.
        #: (Module[top] helpers_module) -> Array[String]
        def included_helper_modules(helpers_module)
          parent_module = helpers_parent._helpers
          parent_name = qualified_name_of(parent_module)
          if parent_module == ::ActionController::Base._helpers || parent_name.nil?
            return gather_includes(helpers_module)
          end

          added = gather_includes(helpers_module) - gather_includes(parent_module) - [parent_name]
          [parent_name, *added]
        end

        # The nearest superclass with its own `HelperMethods` module, which this controller's module includes. Rails
        # defines one the first time a class calls `helper` or `helper_method`, and this compiler gathers every named
        # class that has one. It is found from the class chain rather than from the gathered constants, so that
        # `tapioca dsl UserController` generates the same RBI as `tapioca dsl`.
        #: -> singleton(::ActionController::Base)
        def helpers_parent
          klass = T.cast(constant.superclass, T.class_of(::ActionController::Base))
          until klass.const_defined?(:HelperMethods, false)
            klass = T.cast(klass.superclass, T.class_of(::ActionController::Base))
          end
          klass
        end

        #: (Module[top] mod) -> Array[String]
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
