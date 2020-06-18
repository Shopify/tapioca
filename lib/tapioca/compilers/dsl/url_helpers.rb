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
          case constant
          when GeneratedPathHelpersModule.singleton_class, GeneratedUrlHelpersModule.singleton_class
            generate_module_for(root, constant)
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

        sig { params(root: Parlour::RbiGenerator::Namespace, constant: T.class_of(Module)).void }
        def generate_module_for(root, constant)
          root.create_module(constant.name) do |mod|
            mod.create_include("ActionDispatch::Routing::UrlFor")
            mod.create_include("ActionDispatch::Routing::PolymorphicRoutes")

            constant.instance_methods(false).each do |method|
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
          superclass_ancestors = mod.superclass&.ancestors if Class === mod
          superclass_ancestors ||= []
          (mod.ancestors - superclass_ancestors).include?(helper)
        end
      end
    end
  end
end
