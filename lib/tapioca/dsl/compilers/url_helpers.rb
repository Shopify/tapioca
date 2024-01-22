# typed: strict
# frozen_string_literal: true

return unless defined?(Rails) && defined?(ActionDispatch::Routing)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::UrlHelpers` generates RBI files for classes that include or extend
      # [`Rails.application.routes.url_helpers`](https://api.rubyonrails.org/v5.1.7/classes/ActionDispatch/Routing/UrlFor.html#module-ActionDispatch::Routing::UrlFor-label-URL+generation+for+named+routes).
      #
      # For example, with the following setup:
      #
      # ~~~rb
      # # config/application.rb
      # class Application < Rails::Application
      #   routes.draw do
      #     resource :index
      #   end
      # end
      # ~~~
      #
      # ~~~rb
      # app/models/post.rb
      # class Post
      #   # Use `T.unsafe` so that Sorbet does not complain about a dynamic
      #   # module being included. This allows the `include` to happen properly
      #   # at runtime but Sorbet won't see the include. However, since this
      #   # compiler will generate the proper RBI files for the include,
      #   # static type checking will work as expected.
      #   T.unsafe(self).include Rails.application.routes.url_helpers
      # end
      # ~~~
      #
      # this compiler will produce the following RBI files:
      #
      # ~~~rbi
      # # generated_path_helpers_module.rbi
      # # typed: true
      # module GeneratedPathHelpersModule
      #   include ActionDispatch::Routing::PolymorphicRoutes
      #   include ActionDispatch::Routing::UrlFor
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def edit_index_path(*args); end
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def index_path(*args); end
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def new_index_path(*args); end
      # end
      # ~~~
      #
      # ~~~rbi
      # # generated_url_helpers_module.rbi
      # # typed: true
      # module GeneratedUrlHelpersModule
      #   include ActionDispatch::Routing::PolymorphicRoutes
      #   include ActionDispatch::Routing::UrlFor
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def edit_index_url(*args); end
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def index_url(*args); end
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def new_index_url(*args); end
      # end
      # ~~~
      #
      # ~~~rbi
      # # post.rbi
      # # typed: true
      # class Post
      #   include GeneratedPathHelpersModule
      #   include GeneratedUrlHelpersModule
      # end
      # ~~~
      class UrlHelpers < Compiler
        extend T::Sig

        ConstantType = type_member { { fixed: Module } }

        sig { override.void }
        def decorate
          case constant
          when GeneratedPathHelpersModule.singleton_class, GeneratedUrlHelpersModule.singleton_class
            generate_module_for(root, constant)
          else
            root.create_path(constant) do |mod|
              create_mixins_for(mod, GeneratedUrlHelpersModule)
              create_mixins_for(mod, GeneratedPathHelpersModule)
            end
          end
        end

        class << self
          extend T::Sig
          sig { override.returns(T::Enumerable[Module]) }
          def gather_constants
            return [] unless defined?(Rails.application) && Rails.application

            Object.const_set(:GeneratedUrlHelpersModule, Rails.application.routes.named_routes.url_helpers_module)
            Object.const_set(:GeneratedPathHelpersModule, Rails.application.routes.named_routes.path_helpers_module)

            constants = all_modules.select do |mod|
              next unless name_of(mod)

              includes_helper?(mod, GeneratedUrlHelpersModule) ||
                includes_helper?(mod, GeneratedPathHelpersModule) ||
                includes_helper?(mod.singleton_class, GeneratedUrlHelpersModule) ||
                includes_helper?(mod.singleton_class, GeneratedPathHelpersModule)
            end

            constants.concat(NON_DISCOVERABLE_INCLUDERS)
          end

          sig { returns(T::Array[Module]) }
          def gather_non_discoverable_includers
            [].tap do |includers|
              if defined?(ActionController::TemplateAssertions) && defined?(ActionDispatch::IntegrationTest)
                includers << ActionDispatch::IntegrationTest
              end

              if defined?(ActionView::Helpers)
                includers << ActionView::Helpers
              end
            end.freeze
          end

          sig { params(mod: Module, helper: Module).returns(T::Boolean) }
          private def includes_helper?(mod, helper)
            superclass_ancestors = []

            if Class === mod
              superclass = superclass_of(mod)
              superclass_ancestors = ancestors_of(superclass) if superclass
            end

            ancestors = Set.new.compare_by_identity.merge(ancestors_of(mod)).subtract(superclass_ancestors)
            ancestors.any? { |ancestor| helper == ancestor }
          end
        end

        NON_DISCOVERABLE_INCLUDERS = T.let(gather_non_discoverable_includers, T::Array[Module])

        private

        sig { params(root: RBI::Tree, constant: Module).void }
        def generate_module_for(root, constant)
          root.create_module(T.must(constant.name)) do |mod|
            mod.create_include("::ActionDispatch::Routing::UrlFor")
            mod.create_include("::ActionDispatch::Routing::PolymorphicRoutes")

            constant.instance_methods(false).each do |method|
              mod.create_method(
                method.to_s,
                parameters: [create_rest_param("args", type: "T.untyped")],
                return_type: "String",
              )
            end
          end
        end

        sig { params(mod: RBI::Scope, helper_module: Module).void }
        def create_mixins_for(mod, helper_module)
          include_helper = constant.ancestors.include?(helper_module) || NON_DISCOVERABLE_INCLUDERS.include?(constant)
          extend_helper = constant.singleton_class.ancestors.include?(helper_module)

          mod.create_include(T.must(helper_module.name)) if include_helper
          mod.create_extend(T.must(helper_module.name)) if extend_helper
        end
      end
    end
  end
end
