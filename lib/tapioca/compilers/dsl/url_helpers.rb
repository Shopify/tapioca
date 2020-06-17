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

        sig { override.params(root: Parlour::RbiGenerator::Namespace, _: T.untyped).void }
        def decorate(root, constant)
          named_routes = Rails.application.routes.named_routes
          path_helper_methods = named_routes.path_helpers_module.instance_methods(false)
          url_helper_methods = named_routes.url_helpers_module.instance_methods(false)

          if constant == GeneratedPathHelpersModule
            root.create_module("GeneratedPathHelpersModule") do |mod|
              mod.create_include("ActionDispatch::Routing::UrlFor")
              mod.create_include("ActionDispatch::Routing::PolymorphicRoutes")

              path_helper_methods.each do |method|
                mod.create_method(
                  method.to_s,
                  parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
                  return_type: "String"
                )
              end
            end
          elsif constant == GeneratedUrlHelpersModule
            root.create_module("GeneratedUrlHelpersModule") do |mod|
              mod.create_include("ActionDispatch::Routing::UrlFor")
              mod.create_include("ActionDispatch::Routing::PolymorphicRoutes")

              url_helper_methods.each do |method|
                mod.create_method(
                  method.to_s,
                  parameters: [Parlour::RbiGenerator::Parameter.new("*args", type: "T.untyped")],
                  return_type: "String"
                )
              end
            end
          else
            root.path(constant) do |mod|
              mod.create_include("GeneratedUrlHelpersModule") if
                constant.ancestors.include?(GeneratedUrlHelpersModule)
              mod.create_include("GeneratedPathHelpersModule") if
                constant.ancestors.include?(GeneratedPathHelpersModule)
              mod.create_extend("GeneratedUrlHelpersModule") if
                constant.singleton_class.ancestors.include?(GeneratedUrlHelpersModule)
              mod.create_extend("GeneratedPathHelpersModule") if
                constant.singleton_class.ancestors.include?(GeneratedPathHelpersModule)
            end
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          Object.const_set(:GeneratedUrlHelpersModule, Rails.application.routes.named_routes.url_helpers_module)
          Object.const_set(:GeneratedPathHelpersModule, Rails.application.routes.named_routes.path_helpers_module)
          ObjectSpace.each_object(Module).select do |mod|
            (mod.ancestors.include?(GeneratedUrlHelpersModule) &&
             !mod.try(:superclass)&.ancestors&.include?(GeneratedUrlHelpersModule)) ||
            (mod.singleton_class.ancestors.include?(GeneratedUrlHelpersModule) &&
             !mod.singleton_class.try(:superclass)&.ancestors&.include?(GeneratedPathHelpersModule)) ||
            (mod.ancestors.include?(GeneratedPathHelpersModule) &&
             !mod.try(:superclass)&.ancestors&.include?(GeneratedPathHelpersModule)) ||
            (mod.singleton_class.ancestors.include?(GeneratedPathHelpersModule) &&
             !mod.singleton_class.try(:superclass)&.ancestors&.include?(GeneratedPathHelpersModule))
          end.select(&:name) << "ActionDispatch::IntegrationTest"
        end
      end
    end
  end
end
