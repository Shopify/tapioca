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
      # `Tapioca::Compilers::Dsl::UrlHelpers` generates RBI files for classes that include or extend
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
      #   # generator will generate the proper RBI files for the include,
      #   # static type checking will work as expected.
      #   T.unsafe(self).include Rails.application.routes.url_helpers
      # end
      # ~~~
      #
      # this generator will produce the following RBI files:
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
