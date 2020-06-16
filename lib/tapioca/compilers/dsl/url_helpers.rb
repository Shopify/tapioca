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

          # root.create_class("ActionController::Base") do |klass|
          #   klass.create_include("GeneratedPathHelpersModule")
          #   klass.create_include("GeneratedUrlHelpersModule")
          # end

          # root.create_class("ActionController::API") do |klass|
          #   klass.create_include("GeneratedPathHelpersModule")
          #   klass.create_include("GeneratedUrlHelpersModule")
          # end

          root.create_class("ActionDispatch::IntegrationTest") do |klass|
            klass.create_include("GeneratedPathHelpersModule")
            klass.create_include("GeneratedUrlHelpersModule")
          end

          # root.create_class("ActionMailer::Base") do |mod|
          #   # In Action Mailer, the path helpers are not supported
          #   mod.create_include("GeneratedUrlHelpersModule")
          # end

          # root.create_module("ActionView::Helpers") do |mod|
          #   mod.create_include("GeneratedPathHelpersModule")
          #   mod.create_include("GeneratedUrlHelpersModule")
          # end

          root.path(constant) do |mod|
            mod.create_extend("GeneratedPathHelpersModule")
            mod.create_extend("GeneratedUrlHelpersModule")
          end
        end

        sig { override.returns(T::Enumerable[Module]) }
        def gather_constants
          generated_url_helpers_module = Rails.application.routes.named_routes.url_helpers_module
          generated_path_helpers_module = Rails.application.routes.named_routes.path_helpers_module

          ObjectSpace.each_object(Module).select do |mod|
            (mod.ancestors.include?(generated_url_helpers_module) &&
             !mod.try(:superclass)&.ancestors&.include?(generated_url_helpers_module)) ||
            (mod.singleton_class.ancestors.include?(generated_url_helpers_module) &&
             !mod.singleton_class.try(:superclass)&.ancestors&.include?(generated_url_helpers_module)) ||
            (mod.ancestors.include?(generated_path_helpers_module) &&
             !mod.try(:superclass)&.ancestors&.include?(generated_path_helpers_module)) ||
            (mod.singleton_class.ancestors.include?(generated_path_helpers_module) &&
             !mod.singleton_class.try(:superclass)&.ancestors&.include?(generated_path_helpers_module))
          end.select(&:name)
        end
      end
    end
  end
end
