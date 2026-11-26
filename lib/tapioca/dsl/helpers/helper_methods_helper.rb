# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Helpers
      # Generates the `HelperMethods` module that `AbstractController::Helpers` defines for each controller and mailer
      # that calls `helper` or `helper_method`: an include for each helper module, and a method for each helper it
      # defines itself. Include it in a compiler.
      module HelperMethodsHelper
        include RBIHelper
        include Runtime::Reflection

        private

        # Creates `klass`'s `HelperMethods` module in `scope`. `base` is the framework class whose own module has a
        # gem RBI: `ActionController::Base` or `ActionMailer::Base`.
        #: (RBI::Scope scope, Class[top] klass, base: Class[top]) -> void
        def create_helper_methods_module(scope, klass, base:)
          # For `create_method_from_def` (Sorbet can't require a generic ancestor)
          #: self as HelperMethodsHelper & Compiler[untyped]

          helpers_module = helpers_module_of(klass)
          proxied_helper_methods = T.unsafe(klass)._helper_methods.map(&:to_s).map(&:to_sym) #: Array[Symbol]

          scope.create_module("HelperMethods") do |helper_methods|
            # If the class has no helper defined, then it just inherits the
            # base helper methods module, so we should just add that as an
            # include and stop doing more processing.
            if helpers_module == helpers_module_of(base)
              next helper_methods.create_include(T.must(qualified_name_of(helpers_module)))
            end

            # Generate an include for the parent class's helper module and
            # each helper module this class adds to it
            included_helper_modules(klass, base).each do |ancestor|
              helper_methods.create_include(ancestor)
            end

            # Generate a method definition in the helper module for each
            # helper method defined via the `helper_method` call in the class.
            helpers_module.instance_methods(false).each do |method_name|
              method = if proxied_helper_methods.include?(method_name)
                helper_method_proxy_target(klass, method_name)
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
        end

        #: (Class[top] klass, Symbol method_name) -> UnboundMethod?
        def helper_method_proxy_target(klass, method_name)
          # Lookup the proxy target method only if it is defined as a public/protected or private method.
          if klass.method_defined?(method_name) || klass.private_method_defined?(method_name)
            klass.instance_method(method_name)
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

        # The modules to include in `klass`'s `HelperMethods`. When its parent class's module is one these compilers
        # generate an RBI for, that module and the modules `klass` adds to it: the parent's RBI includes the rest.
        # Otherwise (the parent is `base`, whose gem RBI can't know the helpers that other gems add to it at runtime)
        # every module.
        #: (Class[top] klass, Class[top] base) -> Array[String]
        def included_helper_modules(klass, base)
          helpers_module = helpers_module_of(klass)
          parent_module = helpers_module_of(helpers_parent(klass))
          parent_name = qualified_name_of(parent_module)
          return gather_includes(helpers_module) if parent_module == helpers_module_of(base) || parent_name.nil?

          added = gather_includes(helpers_module) - gather_includes(parent_module) - [parent_name]
          [parent_name, *added]
        end

        # The nearest superclass of `klass` with its own `HelperMethods` module, which `klass`'s module includes. Rails
        # defines one the first time a class calls `helper` or `helper_method`, and these compilers gather every named
        # class that has one. It is found from the class chain rather than from the gathered constants, so that
        # `tapioca dsl UserController` generates the same RBI as `tapioca dsl`.
        #: (Class[top] klass) -> Class[top]
        def helpers_parent(klass)
          parent = T.must(klass.superclass)
          parent = T.must(parent.superclass) until parent.const_defined?(:HelperMethods, false)
          parent
        end

        # The helper module of a class that includes `AbstractController::Helpers`: its own, or its parent's.
        #: (Class[top] klass) -> Module[top]
        def helpers_module_of(klass)
          T.unsafe(klass)._helpers
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
