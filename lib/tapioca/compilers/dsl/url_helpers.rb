# typed: strict
# frozen_string_literal: true

require "parlour"

begin
  require "rails"
  require "action_controller"
  require "action_view"
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

        NON_DISCOVERABLE_INCLUDERS = T.let([
          ActionDispatch::IntegrationTest,
          ActionView::Helpers,
        ], T::Array[Module])

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          Object.const_set(:GeneratedUrlHelpersModule, Rails.application.routes.named_routes.url_helpers_module)
          Object.const_set(:GeneratedPathHelpersModule, Rails.application.routes.named_routes.path_helpers_module)

          module_enumerator = T.cast(ObjectSpace.each_object(Module), T::Enumerator[Module])
          constants = module_enumerator.select do |mod|
            next unless Module.instance_method(:name).bind(mod).call

            includes_helper?(mod, GeneratedUrlHelpersModule) ||
              includes_helper?(mod, GeneratedPathHelpersModule) ||
              includes_helper?(mod.singleton_class, GeneratedUrlHelpersModule) ||
              includes_helper?(mod.singleton_class, GeneratedPathHelpersModule)
          end

          constants.concat(NON_DISCOVERABLE_INCLUDERS)
        end

        private

        sig { params(root: Parlour::RbiGenerator::Namespace, constant: T.class_of(Module)).void }
        def generate_module_for(root, constant)
          root.create_module(T.must(constant.name)) do |mod|
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

        sig { params(mod: Parlour::RbiGenerator::Namespace, constant: T.class_of(Module), helper_module: Module).void }
        def create_mixins_for(mod, constant, helper_module)
          include_helper = constant.ancestors.include?(helper_module) || NON_DISCOVERABLE_INCLUDERS.include?(constant)
          extend_helper = constant.singleton_class.ancestors.include?(helper_module)

          mod.create_include(T.must(helper_module.name)) if include_helper
          mod.create_extend(T.must(helper_module.name)) if extend_helper
        end

        sig { params(mod: Module, helper: Module).returns(T::Boolean) }
        def includes_helper?(mod, helper)
          superclass_ancestors = mod.superclass&.ancestors if Class === mod
          superclass_ancestors ||= []
          (mod.ancestors - superclass_ancestors).include?(helper)
        end
      end
    end
  end
end
