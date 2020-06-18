# typed: true
# frozen_string_literal: true

require "parlour"

begin
  require "rails"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      class UrlHelpers < Base
        extend T::Sig

        sig { override.params(root: Parlour::RbiGenerator::Namespace, constant: T.class_of(Module)).void }
        def decorate(root, constant)
          path_helper_methods = GeneratedPathHelpersModule.instance_methods(false)
          url_helper_methods = GeneratedUrlHelpersModule.instance_methods(false)

          if constant == GeneratedPathHelpersModule
            generate_module_for(root, GeneratedPathHelpersModule, path_helper_methods)
          elsif constant == GeneratedUrlHelpersModule
            generate_module_for(root, GeneratedUrlHelpersModule, url_helper_methods)
          else
            root.path(constant) do |mod|
              create_mixins_for(mod, constant, GeneratedUrlHelpersModule)
              create_mixins_for(mod, constant, GeneratedPathHelpersModule)
            end
          end
        end

        sig { override.returns(T::Enumerable[T.untyped]) }
        def gather_constants
          Object.const_set(:GeneratedUrlHelpersModule, Rails.application.routes.named_routes.url_helpers_module)
          Object.const_set(:GeneratedPathHelpersModule, Rails.application.routes.named_routes.path_helpers_module)
          constants = ObjectSpace.each_object(Module).select do |mod|
            mod = T.let(mod, T.class_of(Module))
            includes_helper?(mod, GeneratedUrlHelpersModule) ||
              includes_helper?(mod, GeneratedPathHelpersModule) ||
              includes_helper?(mod.singleton_class, GeneratedUrlHelpersModule) ||
              includes_helper?(mod.singleton_class, GeneratedPathHelpersModule)
          end.select(&:name)

          constants << "ActionDispatch::IntegrationTest"
        end

        private

        def generate_module_for(root, constant, helper_methods)
          return if helper_methods.empty?
          root.create_module(constant.name) do |mod|
            mod.create_include("ActionDispatch::Routing::UrlFor")
            mod.create_include("ActionDispatch::Routing::PolymorphicRoutes")

            helper_methods.each do |method|
              mod.create_method(
                method.to_s,
                parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
                return_type: "String"
              )
            end
          end
        end

        def create_mixins_for(mod, constant, helper_module)
          mod.create_include(helper_module.name) if constant.ancestors.include?(helper_module)
          mod.create_extend(helper_module.name) if constant.singleton_class.ancestors.include?(helper_module)
        end

        def includes_helper?(mod, helper)
          superclass_ancestors = []
          superclass_ancestors << mod.try(:superclass)&.ancestors if mod === Class
          (mod.ancestors - superclass_ancestors).include?(helper)
        end
      end
    end
  end
end
