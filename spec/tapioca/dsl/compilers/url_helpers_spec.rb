# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class UrlHelpersSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::UrlHelper" do
          #: -> void
          def before_setup
            require "rails"
          end

          describe "initialize" do
            it "does not gather constants when url_helpers is not included" do
              add_ruby_file("content.rb", <<~RUBY)
                class Application < Rails::Application
                end

                class MyClass
                end
              RUBY

              assert_equal(
                [
                  "GeneratedPathHelpersModule",
                  "GeneratedUrlHelpersModule",
                ],
                gathered_constants,
              )
            end

            it "gathers constants that include url_helpers" do
              add_ruby_file("content.rb", <<~RUBY)
                class Application < Rails::Application
                end

                class MyClass
                  include Rails.application.routes.url_helpers
                end
              RUBY

              assert_equal(
                [
                  "GeneratedPathHelpersModule",
                  "GeneratedUrlHelpersModule",
                  "MyClass",
                ],
                gathered_constants,
              )
            end

            it "gathers constants that extend url_helpers" do
              add_ruby_file("content.rb", <<~RUBY)
                class Application < Rails::Application
                end

                class MyClass
                  extend Rails.application.routes.url_helpers
                end
              RUBY

              assert_equal(
                [
                  "GeneratedPathHelpersModule",
                  "GeneratedUrlHelpersModule",
                  "MyClass",
                ],
                gathered_constants,
              )
            end

            it "gathers constants that have a singleton class that includes url_helpers" do
              add_ruby_file("content.rb", <<~RUBY)
                class Application < Rails::Application
                end

                class MyClass
                  class << self
                    include Rails.application.routes.url_helpers
                  end
                end
              RUBY

              assert_equal(
                [
                  "GeneratedPathHelpersModule",
                  "GeneratedUrlHelpersModule",
                  "MyClass",
                ],
                gathered_constants,
              )
            end

            it "does not gather constants when its superclass includes url_helpers" do
              add_ruby_file("content.rb", <<~RUBY)
                class Application < Rails::Application
                end

                class SuperClass
                  include Rails.application.routes.url_helpers
                end

                class MyClass < SuperClass
                end
              RUBY

              assert_equal(
                [
                  "GeneratedPathHelpersModule",
                  "GeneratedUrlHelpersModule",
                  "SuperClass",
                ],
                gathered_constants,
              )
            end

            it "gathers constants when its superclass extends url_helpers" do
              add_ruby_file("content.rb", <<~RUBY)
                class Application < Rails::Application
                end

                class SuperClass
                  extend Rails.application.routes.url_helpers
                end

                class MyClass < SuperClass
                end
              RUBY

              assert_equal(
                [
                  "GeneratedPathHelpersModule",
                  "GeneratedUrlHelpersModule",
                  "SuperClass",
                ],
                gathered_constants,
              )
            end

            it "does not gather constants when the constant and its superclass includes url_helpers" do
              add_ruby_file("content.rb", <<~RUBY)
                class Application < Rails::Application
                end

                class SuperClass
                  include Rails.application.routes.url_helpers
                end

                class MyClass < SuperClass
                  include Rails.application.routes.url_helpers
                end
              RUBY

              assert_equal(
                [
                  "GeneratedPathHelpersModule",
                  "GeneratedUrlHelpersModule",
                  "SuperClass",
                ],
                gathered_constants,
              )
            end

            it "does not gather XPath" do
              add_ruby_file("xpath.rb", <<~RUBY)
                require "xpath"

                class Application < Rails::Application
                end
              RUBY

              assert_equal(
                [
                  "GeneratedPathHelpersModule",
                  "GeneratedUrlHelpersModule",
                ],
                gathered_constants,
              )
            end

            it "gathers constants even when `hash` is overridden" do
              add_ruby_file("bad_module.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module BadModule
                  extend self

                  def hash(a, b)
                  end
                end

                class Bar
                  extend BadModule
                end

                class Foo < Bar
                  extend BadModule
                end
              RUBY

              assert_equal(
                [
                  "GeneratedPathHelpersModule",
                  "GeneratedUrlHelpersModule",
                ],
                gathered_constants,
              )
            end

            it "gathers engine helper module constants when an engine is mounted" do
              add_ruby_file("engine.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                Application.routes.draw do
                  mount Blog::Engine => "/blog"
                end
              RUBY

              constants = gathered_constants

              assert_includes(constants, "Blog::Engine::GeneratedPathHelpersModule")
              assert_includes(constants, "Blog::Engine::GeneratedUrlHelpersModule")
              assert_includes(constants, "GeneratedMountedHelpers")
              assert_includes(constants, "GeneratedPathHelpersModule")
              assert_includes(constants, "GeneratedUrlHelpersModule")
            end

            it "gathers constants for two mounted engines with distinct routes" do
              add_ruby_file("engines.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                module Shop
                  class Engine < ::Rails::Engine
                    isolate_namespace Shop
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                Shop::Engine.routes.draw do
                  resources :products
                end

                Application.routes.draw do
                  mount Blog::Engine => "/blog"
                  mount Shop::Engine => "/shop"
                end
              RUBY

              constants = gathered_constants

              assert_includes(constants, "Blog::Engine::GeneratedPathHelpersModule")
              assert_includes(constants, "Blog::Engine::GeneratedUrlHelpersModule")
              assert_includes(constants, "Shop::Engine::GeneratedPathHelpersModule")
              assert_includes(constants, "Shop::Engine::GeneratedUrlHelpersModule")
              assert_includes(constants, "GeneratedMountedHelpers")
            end

            it "skips engines with no routes" do
              add_ruby_file("engine.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Empty
                  class Engine < ::Rails::Engine
                    isolate_namespace Empty
                  end
                end

                Application.routes.draw do
                  mount Empty::Engine => "/empty"
                end
              RUBY

              constants = gathered_constants

              refute_includes(constants, "Empty::Engine::GeneratedPathHelpersModule")
              refute_includes(constants, "Empty::Engine::GeneratedUrlHelpersModule")
              # A mount of a routeless engine contributes no helpers, so there's nothing to
              # generate beyond `main_app` and GeneratedMountedHelpers is not synthesized.
              refute_includes(constants, "GeneratedMountedHelpers")
            end

            it "gathers constants that include engine-specific url_helpers" do
              add_ruby_file("engine.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                Application.routes.draw do
                  mount Blog::Engine => "/blog"
                end

                class MyHelper
                  include Blog::Engine.routes.url_helpers
                end
              RUBY

              assert_includes(gathered_constants, "MyHelper")
            end
          end

          describe "decorate" do
            it "generates RBI when there are no helper methods" do
              add_ruby_file("routes.rb", <<~RUBY)
                class Application < Rails::Application
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                module GeneratedUrlHelpersModule
                  include ::ActionDispatch::Routing::UrlFor
                  include ::ActionDispatch::Routing::PolymorphicRoutes
                end
              RBI

              assert_equal(expected, rbi_for(:GeneratedUrlHelpersModule))
            end

            it "generates RBI for GeneratedPathHelpersModule with helper methods" do
              add_ruby_file("routes.rb", <<~RUBY)
                class Application < Rails::Application
                  routes.draw do
                    resource :index
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                module GeneratedPathHelpersModule
                  include ::ActionDispatch::Routing::UrlFor
                  include ::ActionDispatch::Routing::PolymorphicRoutes

                  sig { params(args: T.untyped).returns(String) }
                  def edit_index_path(*args); end

                  sig { params(args: T.untyped).returns(String) }
                  def index_path(*args); end

                  sig { params(args: T.untyped).returns(String) }
                  def new_index_path(*args); end
                end
              RBI

              assert_equal(expected, rbi_for(:GeneratedPathHelpersModule))
            end

            it "generates RBI for GeneratedUrlHelpersModule with helper methods" do
              add_ruby_file("routes.rb", <<~RUBY)
                class Application < Rails::Application
                  routes.draw do
                    resource :index
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                module GeneratedUrlHelpersModule
                  include ::ActionDispatch::Routing::UrlFor
                  include ::ActionDispatch::Routing::PolymorphicRoutes

                  sig { params(args: T.untyped).returns(String) }
                  def edit_index_url(*args); end

                  sig { params(args: T.untyped).returns(String) }
                  def index_url(*args); end

                  sig { params(args: T.untyped).returns(String) }
                  def new_index_url(*args); end
                end
              RBI

              assert_equal(expected, rbi_for(:GeneratedUrlHelpersModule))
            end

            describe "when Action Controller is loaded" do
              #: -> void
              def before_setup
                require "rails"
                require "action_controller"
              end

              it "generates RBI for ActionDispatch::IntegrationTest" do
                add_ruby_file("routes.rb", <<~RUBY)
                  class Application < Rails::Application
                  end
                RUBY

                expected = <<~RBI
                  # typed: strong

                  class ActionDispatch::IntegrationTest
                    include GeneratedUrlHelpersModule
                    include GeneratedPathHelpersModule
                  end
                RBI

                assert_equal(expected, rbi_for("ActionDispatch::IntegrationTest"))
              end
            end

            describe "when Action View is loaded" do
              #: -> void
              def before_setup
                require "rails"
                require "action_view"
              end

              it "generates RBI for ActionView::Helpers" do
                add_ruby_file("routes.rb", <<~RUBY)
                  require "action_view"

                  class Application < Rails::Application
                  end
                RUBY

                expected = <<~RBI
                  # typed: strong

                  module ActionView::Helpers
                    include GeneratedUrlHelpersModule
                    include GeneratedPathHelpersModule
                  end
                RBI

                assert_equal(expected, rbi_for("ActionView::Helpers"))
              end
            end

            it "generates RBI for constant that includes url_helpers" do
              add_ruby_file("routes.rb", <<~RUBY)
                class Application < Rails::Application
                end
              RUBY

              add_ruby_file("my_class.rb", <<~RUBY)
                class MyClass
                  include Rails.application.routes.url_helpers
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class MyClass
                  include GeneratedUrlHelpersModule
                  include GeneratedPathHelpersModule
                end
              RBI

              assert_equal(expected, rbi_for(:MyClass))
            end

            it "generates RBI for constant that extends url_helpers" do
              add_ruby_file("routes.rb", <<~RUBY)
                class Application < Rails::Application
                end
              RUBY

              add_ruby_file("my_class.rb", <<~RUBY)
                class MyClass
                  extend Rails.application.routes.url_helpers
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class MyClass
                  extend GeneratedUrlHelpersModule
                  extend GeneratedPathHelpersModule
                end
              RBI

              assert_equal(expected, rbi_for(:MyClass))
            end

            it "generates RBI for constant that includes and extends url_helpers" do
              add_ruby_file("routes.rb", <<~RUBY)
                class Application < Rails::Application
                end
              RUBY

              add_ruby_file("my_class.rb", <<~RUBY)
                class MyClass
                  include Rails.application.routes.url_helpers
                  extend Rails.application.routes.url_helpers
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class MyClass
                  include GeneratedUrlHelpersModule
                  extend GeneratedUrlHelpersModule
                  include GeneratedPathHelpersModule
                  extend GeneratedPathHelpersModule
                end
              RBI

              assert_equal(expected, rbi_for(:MyClass))
            end

            it "generates RBI for constant that has a singleton class which includes url_helpers" do
              add_ruby_file("routes.rb", <<~RUBY)
                class Application < Rails::Application
                end
              RUBY

              add_ruby_file("my_class.rb", <<~RUBY)
                class MyClass
                  class << self
                    include Rails.application.routes.url_helpers
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class MyClass
                  extend GeneratedUrlHelpersModule
                  extend GeneratedPathHelpersModule
                end
              RBI

              assert_equal(expected, rbi_for(:MyClass))
            end

            it "generates RBI when constant itself and its singleton class includes url_helpers" do
              add_ruby_file("routes.rb", <<~RUBY)
                class Application < Rails::Application
                end
              RUBY

              add_ruby_file("my_class.rb", <<~RUBY)
                class MyClass
                  include Rails.application.routes.url_helpers
                  class << self
                    include Rails.application.routes.url_helpers
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class MyClass
                  include GeneratedUrlHelpersModule
                  extend GeneratedUrlHelpersModule
                  include GeneratedPathHelpersModule
                  extend GeneratedPathHelpersModule
                end
              RBI

              assert_equal(expected, rbi_for(:MyClass))
            end

            it "generates RBI for engine GeneratedPathHelpersModule with helper methods" do
              add_ruby_file("engine.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                Application.routes.draw do
                  mount Blog::Engine => "/blog"
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                module Blog::Engine::GeneratedPathHelpersModule
                  include ::ActionDispatch::Routing::UrlFor
                  include ::ActionDispatch::Routing::PolymorphicRoutes

                  sig { params(args: T.untyped).returns(String) }
                  def edit_post_path(*args); end

                  sig { params(args: T.untyped).returns(String) }
                  def new_post_path(*args); end

                  sig { params(args: T.untyped).returns(String) }
                  def post_path(*args); end

                  sig { params(args: T.untyped).returns(String) }
                  def posts_path(*args); end
                end
              RBI

              assert_equal(expected, rbi_for("Blog::Engine::GeneratedPathHelpersModule"))
            end

            it "generates RBI for engine GeneratedUrlHelpersModule with helper methods" do
              add_ruby_file("engine.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                Application.routes.draw do
                  mount Blog::Engine => "/blog"
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                module Blog::Engine::GeneratedUrlHelpersModule
                  include ::ActionDispatch::Routing::UrlFor
                  include ::ActionDispatch::Routing::PolymorphicRoutes

                  sig { params(args: T.untyped).returns(String) }
                  def edit_post_url(*args); end

                  sig { params(args: T.untyped).returns(String) }
                  def new_post_url(*args); end

                  sig { params(args: T.untyped).returns(String) }
                  def post_url(*args); end

                  sig { params(args: T.untyped).returns(String) }
                  def posts_url(*args); end
                end
              RBI

              assert_equal(expected, rbi_for("Blog::Engine::GeneratedUrlHelpersModule"))
            end

            it "generates distinct RBI for two mounted engines" do
              add_ruby_file("engines.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                module Shop
                  class Engine < ::Rails::Engine
                    isolate_namespace Shop
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                Shop::Engine.routes.draw do
                  resources :products
                end

                Application.routes.draw do
                  mount Blog::Engine => "/blog"
                  mount Shop::Engine => "/shop"
                end
              RUBY

              blog_rbi = rbi_for("Blog::Engine::GeneratedPathHelpersModule")
              shop_rbi = rbi_for("Shop::Engine::GeneratedPathHelpersModule")

              assert_includes(blog_rbi, "def posts_path")
              refute_includes(blog_rbi, "def products_path")

              assert_includes(shop_rbi, "def products_path")
              refute_includes(shop_rbi, "def posts_path")
            end

            it "generates RBI for GeneratedMountedHelpers with main_app and engine proxy" do
              add_ruby_file("engine.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                Application.routes.draw do
                  mount Blog::Engine => "/blog"
                end
              RUBY

              rbi = rbi_for(:GeneratedMountedHelpers)

              assert_includes(rbi, "def main_app")
              assert_includes(rbi, "returns(GeneratedRoutesProxy)")
              assert_includes(rbi, "class GeneratedRoutesProxy < ::ActionDispatch::Routing::RoutesProxy")
              assert_includes(rbi, "include GeneratedPathHelpersModule")
              assert_includes(rbi, "include GeneratedUrlHelpersModule")
              assert_includes(rbi, "def blog")
              assert_includes(rbi, "returns(Blog::Engine::GeneratedRoutesProxy)")
              assert_includes(rbi, "class Blog::Engine::GeneratedRoutesProxy < ::ActionDispatch::Routing::RoutesProxy")
              assert_includes(rbi, "include Blog::Engine::GeneratedPathHelpersModule")
              assert_includes(rbi, "include Blog::Engine::GeneratedUrlHelpersModule")
            end

            it "uses the mount alias for GeneratedMountedHelpers proxy methods" do
              add_ruby_file("engine.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                Application.routes.draw do
                  mount Blog::Engine, at: "/blog", as: "articles"
                end
              RUBY

              rbi = rbi_for(:GeneratedMountedHelpers)

              assert_includes(rbi, "def articles")
              assert_includes(rbi, "returns(Blog::Engine::GeneratedRoutesProxy)")
              refute_includes(rbi, "def blog")
            end

            it "generates RBI for two mounted engines with distinct RoutesProxy classes" do
              add_ruby_file("engines.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                module Shop
                  class Engine < ::Rails::Engine
                    isolate_namespace Shop
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                Shop::Engine.routes.draw do
                  resources :products
                end

                Application.routes.draw do
                  mount Blog::Engine => "/blog"
                  mount Shop::Engine => "/shop"
                end
              RUBY

              rbi = rbi_for(:GeneratedMountedHelpers)

              # Both engines have proxy methods
              assert_includes(rbi, "def blog")
              assert_includes(rbi, "returns(Blog::Engine::GeneratedRoutesProxy)")
              assert_includes(rbi, "def shop")
              assert_includes(rbi, "returns(Shop::Engine::GeneratedRoutesProxy)")

              # Both engines have distinct RoutesProxy classes
              assert_includes(rbi, "class Blog::Engine::GeneratedRoutesProxy < ::ActionDispatch::Routing::RoutesProxy")
              assert_includes(rbi, "include Blog::Engine::GeneratedPathHelpersModule")
              assert_includes(rbi, "include Blog::Engine::GeneratedUrlHelpersModule")

              assert_includes(rbi, "class Shop::Engine::GeneratedRoutesProxy < ::ActionDispatch::Routing::RoutesProxy")
              assert_includes(rbi, "include Shop::Engine::GeneratedPathHelpersModule")
              assert_includes(rbi, "include Shop::Engine::GeneratedUrlHelpersModule")
            end

            it "generates RBI for constant that includes url_helpers with GeneratedMountedHelpers" do
              add_ruby_file("engine.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                Application.routes.draw do
                  mount Blog::Engine => "/blog"
                end

                class MyClass
                  include Rails.application.routes.url_helpers
                end
              RUBY

              rbi = rbi_for(:MyClass)

              assert_includes(rbi, "include GeneratedUrlHelpersModule")
              assert_includes(rbi, "include GeneratedPathHelpersModule")
              # Plain classes including url_helpers do NOT get GeneratedMountedHelpers
              # (only controllers/framework classes have mounted_helpers in ancestors)
              refute_includes(rbi, "GeneratedMountedHelpers")
            end

            it "generates RBI for constant that includes engine-specific url_helpers" do
              add_ruby_file("engine.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                Application.routes.draw do
                  mount Blog::Engine => "/blog"
                end

                class MyHelper
                  include Blog::Engine.routes.url_helpers
                end
              RUBY

              rbi = rbi_for(:MyHelper)

              assert_includes(rbi, "include Blog::Engine::GeneratedUrlHelpersModule")
              assert_includes(rbi, "include Blog::Engine::GeneratedPathHelpersModule")
            end

            it "generates RBI with extend for constant that extends url_helpers with engines mounted" do
              add_ruby_file("engine.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                Application.routes.draw do
                  mount Blog::Engine => "/blog"
                end

                class MyClass
                  extend Rails.application.routes.url_helpers
                end
              RUBY

              rbi = rbi_for(:MyClass)

              assert_includes(rbi, "extend GeneratedUrlHelpersModule")
              assert_includes(rbi, "extend GeneratedPathHelpersModule")
              # Plain classes extending url_helpers do NOT get GeneratedMountedHelpers
              refute_includes(rbi, "GeneratedMountedHelpers")
            end

            describe "when Action Controller is loaded with mounted engines" do
              #: -> void
              def before_setup
                require "rails"
                require "action_controller"
              end

              it "generates RBI for ActionDispatch::IntegrationTest with GeneratedMountedHelpers when engines are mounted" do
                add_ruby_file("engine.rb", <<~RUBY)
                  class Application < Rails::Application
                  end

                  module Blog
                    class Engine < ::Rails::Engine
                      isolate_namespace Blog
                    end
                  end

                  Blog::Engine.routes.draw do
                    resources :posts
                  end

                  Application.routes.draw do
                    mount Blog::Engine => "/blog"
                  end
                RUBY

                rbi = rbi_for("ActionDispatch::IntegrationTest")

                assert_includes(rbi, "include GeneratedUrlHelpersModule")
                assert_includes(rbi, "include GeneratedPathHelpersModule")
                assert_includes(rbi, "include GeneratedMountedHelpers")
              end
            end

            it "generates identical RBI for includer class when no engines are mounted" do
              add_ruby_file("routes.rb", <<~RUBY)
                class Application < Rails::Application
                  routes.draw do
                    resource :index
                  end
                end

                class MyClass
                  include Rails.application.routes.url_helpers
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class MyClass
                  include GeneratedUrlHelpersModule
                  include GeneratedPathHelpersModule
                end
              RBI

              assert_equal(expected, rbi_for(:MyClass))
            end

            it "generates RBI for GeneratedMountedHelpers when one engine has routes and one has none" do
              add_ruby_file("engines.rb", <<~RUBY)
                class Application < Rails::Application
                end

                module Blog
                  class Engine < ::Rails::Engine
                    isolate_namespace Blog
                  end
                end

                module Empty
                  class Engine < ::Rails::Engine
                    isolate_namespace Empty
                  end
                end

                Blog::Engine.routes.draw do
                  resources :posts
                end

                # Empty::Engine has no routes drawn

                Application.routes.draw do
                  mount Blog::Engine => "/blog"
                  mount Empty::Engine => "/empty"
                end
              RUBY

              rbi = rbi_for(:GeneratedMountedHelpers)

              # Blog engine should be present
              assert_includes(rbi, "def blog")
              assert_includes(rbi, "Blog::Engine::GeneratedRoutesProxy")

              # Empty engine should NOT have a typed proxy (it was skipped in discovery)
              refute_includes(rbi, "Empty::Engine::GeneratedRoutesProxy")
            end
          end
        end
      end
    end
  end
end
