# typed: strict
# frozen_string_literal: true

return unless defined?(Rails) && defined?(ActionDispatch::Routing)

module Tapioca
  module Dsl
    module Compilers
      # `Tapioca::Dsl::Compilers::UrlHelpers` generates RBI files for classes that include or extend
      # [`Rails.application.routes.url_helpers`](https://api.rubyonrails.org/classes/ActionDispatch/Routing/UrlFor.html#module-ActionDispatch::Routing::UrlFor-label-URL+generation+for+named+routes).
      #
      # The compiler registers generated constants to represent the Rails route helper modules:
      #
      # 1. `GeneratedPathHelpersModule` holds the main application's path helpers, such as `post_path`.
      #
      # 2. `GeneratedUrlHelpersModule` holds the main application's URL helpers, such as `post_url`.
      #
      # 3. `GeneratedMountedHelpers` is a synthetic module for mounted application and engine helpers, such as
      # `main_app` and `articles`. Rails exposes these helpers through an anonymous dynamic module, so the compiler creates
      # a named RBI module that can be included or extended by classes that receive mounted helpers at runtime. It is
      # only generated for applications that mount an engine that defines its own routes.
      #
      # For mounted engines, the compiler also registers engine-scoped `GeneratedPathHelpersModule` and
      # `GeneratedUrlHelpersModule` constants. Mounted engine helper methods return a synthetic
      # `GeneratedRoutesProxy` subclass that includes those engine-scoped helper modules.
      #
      # For example, with the following setup:
      #
      # ~~~rb
      # # config/application.rb
      # class Application < Rails::Application
      #   routes.draw do
      #     resource :index
      #
      #     mount Blog::Engine, at: "/blog", as: "articles"
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
      #   def articles_path(*args); end
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
      #   def articles_url(*args); end
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
      #
      # ~~~rb
      # # blog/config/routes.rb
      # Blog::Engine.routes.draw do
      #   resources :posts
      # end
      # ~~~
      #
      # ~~~rbi
      # # blog/engine/generated_path_helpers_module.rbi
      # # typed: true
      # module Blog::Engine::GeneratedPathHelpersModule
      #   include ActionDispatch::Routing::PolymorphicRoutes
      #   include ActionDispatch::Routing::UrlFor
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def edit_post_path(*args); end
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def new_post_path(*args); end
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def post_path(*args); end
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def posts_path(*args); end
      # end
      # ~~~
      #
      # ~~~rbi
      # # blog/engine/generated_url_helpers_module.rbi
      # # typed: true
      # module Blog::Engine::GeneratedUrlHelpersModule
      #   include ActionDispatch::Routing::PolymorphicRoutes
      #   include ActionDispatch::Routing::UrlFor
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def edit_post_url(*args); end
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def new_post_url(*args); end
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def post_url(*args); end
      #
      #   sig { params(args: T.untyped).returns(String) }
      #   def posts_url(*args); end
      # end
      # ~~~
      #
      # ~~~rbi
      # # generated_mounted_helpers.rbi
      # # typed: true
      # module GeneratedMountedHelpers
      #   sig { returns(Blog::Engine::GeneratedRoutesProxy) }
      #   def articles; end
      #
      #   sig { returns(GeneratedRoutesProxy) }
      #   def main_app; end
      # end
      # ~~~
      #
      # ~~~rbi
      # # generated_routes_proxy.rbi
      # # typed: true
      # class GeneratedRoutesProxy < ::ActionDispatch::Routing::RoutesProxy
      #   include GeneratedPathHelpersModule
      #   include GeneratedUrlHelpersModule
      # end
      # ~~~
      #
      # ~~~rbi
      # # blog/engine/generated_routes_proxy.rbi
      # # typed: true
      # class Blog::Engine::GeneratedRoutesProxy < ::ActionDispatch::Routing::RoutesProxy
      #   include Blog::Engine::GeneratedPathHelpersModule
      #   include Blog::Engine::GeneratedUrlHelpersModule
      # end
      # ~~~
      #
      #: [ConstantType = Module[top]]
      class UrlHelpers < Compiler
        # @override
        #: -> void
        def decorate
          case constant
          when GeneratedPathHelpersModule.singleton_class, GeneratedUrlHelpersModule.singleton_class
            generate_module_for(root, constant)
          else
            # `GeneratedMountedHelpers` is only defined when an engine is mounted (see `gather_constants`).
            if defined?(::GeneratedMountedHelpers) && GeneratedMountedHelpers.singleton_class === constant
              generate_mounted_helpers_module(root)
            elsif engine_helper_module?(constant)
              generate_module_for(root, constant)
            else
              generate_url_helper_includer
            end
          end
        end

        # Maps each engine's mount name to its class, e.g. `{ blog: Blog::Engine }`.
        # Populated by `gather_constants` and read when generating the mounted helpers module.
        @engine_mount_names = {} #: Hash[Symbol, singleton(::Rails::Engine)]

        class << self
          #: Hash[Symbol, singleton(::Rails::Engine)]
          attr_reader :engine_mount_names

          # @override
          #: -> Enumerable[Module[top]]
          def gather_constants
            return [] unless defined?(Rails.application) && Rails.application

            # Load routes if they haven't been loaded yet (see https://github.com/rails/rails/pull/51614).
            routes_reloader = Rails.application.routes_reloader
            routes_reloader.execute_unless_loaded if routes_reloader&.respond_to?(:execute_unless_loaded)

            url_helpers_module = Rails.application.routes.named_routes.url_helpers_module
            path_helpers_module = Rails.application.routes.named_routes.path_helpers_module

            Object.const_set(:GeneratedUrlHelpersModule, url_helpers_module)
            Object.const_set(:GeneratedPathHelpersModule, path_helpers_module)

            @engine_mount_names = mounted_engine_names
            engine_helper_modules = register_engine_route_helpers

            # Only synthesize the mounted helpers module when at least one mounted engine
            # contributes its own route helpers. A mount of a routeless engine (or an app with
            # no mounts) would leave nothing but `main_app`, which we don't generate on its own.
            # This predicate mirrors `proxied_engines` in `generate_mounted_helpers_module`.
            mounts_engine_with_helpers = @engine_mount_names.values.any? do |engine_class|
              name_of(engine_class) && engine_class.const_defined?(:GeneratedPathHelpersModule, false)
            end

            if mounts_engine_with_helpers
              Object.const_set(:GeneratedMountedHelpers, Module.new)
            end

            constants = all_modules.select do |mod|
              next unless name_of(mod)

              # Fast-path to quickly disqualify most cases
              has_helpers = url_helpers_module > mod ||
                path_helpers_module > mod ||
                url_helpers_module > mod.singleton_class ||
                path_helpers_module > mod.singleton_class

              has_helpers ||= engine_helper_modules.any? do |engine_mod|
                engine_mod > mod || engine_mod > mod.singleton_class
              end

              next false unless has_helpers

              includes_helper?(mod, url_helpers_module) ||
                includes_helper?(mod, path_helpers_module) ||
                includes_helper?(mod.singleton_class, url_helpers_module) ||
                includes_helper?(mod.singleton_class, path_helpers_module) ||
                engine_helper_modules.any? { |engine_mod| includes_helper?(mod, engine_mod) || includes_helper?(mod.singleton_class, engine_mod) }
            end

            constants
              .concat(NON_DISCOVERABLE_INCLUDERS)
              .push(GeneratedUrlHelpersModule, GeneratedPathHelpersModule)
              .concat(engine_helper_modules)

            constants.push(GeneratedMountedHelpers) if defined?(GeneratedMountedHelpers)

            constants
          end

          private

          #: -> Array[Module[top]]
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

          # Maps each mounted engine's mount name to its class (e.g. `{ articles: Blog::Engine }`).
          # Reads the same route table that `bin/rails routes` inspects: a mounted engine appears
          # as a route whose endpoint is the engine (`app.engine?`), with the mount name (or `as:`
          # alias) as the route name.
          #: -> Hash[Symbol, singleton(::Rails::Engine)]
          def mounted_engine_names
            Rails.application.routes.routes.each_with_object({}) do |route, mapping|
              app = route.app
              next unless app.respond_to?(:engine?) && app.engine?

              name = route.name
              next unless name

              mapping[name.to_sym] = app.rack_app
            end
          end

          # Registers engine-scoped `GeneratedPathHelpersModule`/`GeneratedUrlHelpersModule`
          # constants on each engine with routes, and returns those helper modules.
          #: -> Array[Module[top]]
          def register_engine_route_helpers
            engine_helper_modules = [] #: Array[Module[top]]

            Rails.application.railties.grep(::Rails::Engine).each do |engine_instance|
              engine_class = engine_instance.class
              next if engine_class == Rails.application.class

              engine_path_helpers = engine_instance.routes.named_routes.path_helpers_module
              engine_url_helpers = engine_instance.routes.named_routes.url_helpers_module

              # Skip engines with no routes
              next if engine_path_helpers.instance_methods(false).empty? &&
                engine_url_helpers.instance_methods(false).empty?

              unless engine_class.const_defined?(:GeneratedPathHelpersModule, false)
                engine_class.const_set(:GeneratedPathHelpersModule, engine_path_helpers)
              end

              unless engine_class.const_defined?(:GeneratedUrlHelpersModule, false)
                engine_class.const_set(:GeneratedUrlHelpersModule, engine_url_helpers)
              end

              engine_helper_modules << engine_class.const_get(:GeneratedPathHelpersModule)
              engine_helper_modules << engine_class.const_get(:GeneratedUrlHelpersModule)
            end

            engine_helper_modules
          end

          # Returns `true` if `mod` "directly" includes `helper`.
          # For classes, this method will return false if the `helper` is included only by a superclass
          #: (Module[top] mod, Module[top] helper) -> bool
          def includes_helper?(mod, helper)
            ancestors = ancestors_of(mod)

            own_ancestors = if Class === mod && (superclass = superclass_of(mod))
              # These ancestors are unique to `mod`, and exclude those in common with `superclass`.
              ancestors.take(ancestors.count - ancestors_of(superclass).size)
            else
              ancestors
            end

            own_ancestors.include?(helper)
          end
        end

        NON_DISCOVERABLE_INCLUDERS = gather_non_discoverable_includers #: Array[Module[top]]

        private

        #: (RBI::Tree root, Module[top] constant) -> void
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

        #: (RBI::Tree root) -> void
        def generate_mounted_helpers_module(root)
          # Mount name => engine name, for mounted engines that actually expose helper modules.
          # Routeless engines (no `GeneratedPathHelpersModule`) and anonymous engines get no proxy.
          # (If *every* mounted engine is routeless, `gather_constants` doesn't generate this module.)
          proxied_engines = self.class.engine_mount_names.filter_map do |mount_name, engine_class|
            engine_name = name_of(engine_class)
            next unless engine_name
            next unless engine_class.const_defined?(:GeneratedPathHelpersModule, false)

            [mount_name, engine_name]
          end

          root.create_module("GeneratedMountedHelpers") do |mod|
            mod.create_method(
              "main_app",
              return_type: "GeneratedRoutesProxy",
            )

            proxied_engines.each do |mount_name, engine_name|
              mod.create_method(
                mount_name.to_s,
                return_type: "#{engine_name}::GeneratedRoutesProxy",
              )
            end
          end

          # The application's own RoutesProxy subclass, returned by `main_app`. Mirrors the
          # engine proxies below so that `main_app.post_path` & co. type-check.
          root.create_class("GeneratedRoutesProxy", superclass_name: "::ActionDispatch::Routing::RoutesProxy") do |klass|
            klass.create_include("GeneratedPathHelpersModule")
            klass.create_include("GeneratedUrlHelpersModule")
          end

          # One RoutesProxy subclass per engine, `uniq` since an engine can be mounted under
          # several names but needs only a single proxy class.
          proxied_engines.map { |_mount_name, engine_name| engine_name }.uniq.each do |engine_name|
            proxy_class_name = "#{engine_name}::GeneratedRoutesProxy"
            path_helpers_name = "#{engine_name}::GeneratedPathHelpersModule"
            url_helpers_name = "#{engine_name}::GeneratedUrlHelpersModule"

            root.create_class(proxy_class_name, superclass_name: "::ActionDispatch::Routing::RoutesProxy") do |klass|
              klass.create_include(path_helpers_name)
              klass.create_include(url_helpers_name)
            end
          end
        end

        #: (Module[top] mod) -> bool
        def engine_helper_module?(mod)
          Rails.application.railties.grep(::Rails::Engine).any? do |engine_instance|
            engine_class = engine_instance.class
            next false if engine_class == Rails.application.class
            next false unless engine_class.const_defined?(:GeneratedPathHelpersModule, false)

            mod == engine_class.const_get(:GeneratedPathHelpersModule) ||
              mod == engine_class.const_get(:GeneratedUrlHelpersModule)
          end
        end

        #: -> void
        def generate_url_helper_includer
          root.create_path(constant) do |mod|
            create_mixins_for(mod, GeneratedUrlHelpersModule)
            create_mixins_for(mod, GeneratedPathHelpersModule)

            # GeneratedMountedHelpers is only synthesized when an engine is mounted (see
            # `gather_constants`). It is a fresh `Module.new` used purely for naming, so we
            # check against the real `mounted_helpers` module for ancestor detection. Only
            # controllers/framework classes actually have `mounted_helpers` in their ancestor
            # chain; plain url_helpers includers do not.
            if defined?(::GeneratedMountedHelpers)
              mounted_helpers = Rails.application.routes.mounted_helpers
              include_mounted = constant.ancestors.include?(mounted_helpers) ||
                NON_DISCOVERABLE_INCLUDERS.include?(constant)
              extend_mounted = constant.singleton_class.ancestors.include?(mounted_helpers)

              mod.create_include("GeneratedMountedHelpers") if include_mounted
              mod.create_extend("GeneratedMountedHelpers") if extend_mounted
            end

            create_engine_helper_mixins(mod)
          end
        end

        #: (RBI::Scope mod) -> void
        def create_engine_helper_mixins(mod)
          Rails.application.railties.grep(::Rails::Engine).each do |engine_instance|
            engine_class = engine_instance.class
            next if engine_class == Rails.application.class
            next unless engine_class.const_defined?(:GeneratedPathHelpersModule, false)

            create_engine_helper_mixin(mod, engine_class.const_get(:GeneratedUrlHelpersModule))
            create_engine_helper_mixin(mod, engine_class.const_get(:GeneratedPathHelpersModule))
          end
        end

        #: (RBI::Scope mod, Module[top] helper_module) -> void
        def create_engine_helper_mixin(mod, helper_module)
          # Engine helpers must be added only when actually present; the
          # NON_DISCOVERABLE_INCLUDERS fallback is only valid for main app helpers.
          if constant.ancestors.include?(helper_module)
            mod.create_include(T.must(helper_module.name))
          end

          if constant.singleton_class.ancestors.include?(helper_module)
            mod.create_extend(T.must(helper_module.name))
          end
        end

        #: (RBI::Scope mod, Module[top] helper_module) -> void
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
