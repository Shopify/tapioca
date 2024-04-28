# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class UrlHelpersSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::UrlHelper" do
          sig { void }
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
              sig { void }
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
              sig { void }
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
          end
        end
      end
    end
  end
end
