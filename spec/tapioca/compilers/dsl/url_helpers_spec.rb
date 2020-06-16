# typed: false
# frozen_string_literal: true

require "spec_helper"

describe("Tapioca::Compilers::Dsl::UrlHelpers") do
  before(:each) do
    require "tapioca/compilers/dsl/url_helpers"
  end

  subject do
    Tapioca::Compilers::Dsl::UrlHelpers.new
  end

  describe("#initialize") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    content = <<~RUBY
      class Application < Rails::Application
      end
    RUBY

    it("gathers constants that include path_helpers_module") do
      content += <<~RUBY
        class MyClass
          include Rails.application.routes.named_routes.path_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["MyClass"])
    end

    it("gathers constants that extend path_helpers_module") do
      content += <<~RUBY
        class MyClass
          extend Rails.application.routes.named_routes.path_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["MyClass"])
    end

    it("gathers constants that include url_helpers_module") do
      content += <<~RUBY
        class MyClass
          include Rails.application.routes.named_routes.url_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["MyClass"])
    end

    it("gathers constants that extend url_helpers_module") do
      content += <<~RUBY
        class MyClass
          extend Rails.application.routes.named_routes.url_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["MyClass"])
    end

    it("gathers constants that include both path_helpers_module and url_helpers_module") do
      content += <<~RUBY
        class MyClass
          include Rails.application.routes.named_routes.path_helpers_module
          include Rails.application.routes.named_routes.url_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["MyClass"])
    end
  end

  describe("#decorate") do
    def rbi_for(content)
      with_content(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, MyClass)
        parlour.rbi
      end
    end

    it("generates empty RBI if there are no routes") do
      content = <<~RUBY
        class Application < Rails::Application
          # routes.draw do
          #   resource :test
          # end
        end

        class MyClass
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class ActionDispatch::IntegrationTest
        end

        class MyClass
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI when a route is specified") do
      content = <<~RUBY
        class Application < Rails::Application
          routes.draw do
            resource :index
          end
        end

        class MyClass
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class ActionDispatch::IntegrationTest
          include GenerateUrlHelpersModule
          include GeneratedPathHelpersModule
        end

        module GeneratedPathHelpersModule
          include ActionDispatch::Routing::PolymorphicRoutes
          include ActionDispatch::Routing::UrlFor

          sig { params(args: T.untyped).returns(String) }
          def edit_index_path(*args); end

          sig { params(args: T.untyped).returns(String) }
          def index_path(*args); end

          sig { params(args: T.untyped).returns(String) }
          def new_index_path(*args); end
        end

        module GeneratedUrlHelpersModule
          include ActionDispatch::Routing::PolymorphicRoutes
          include ActionDispatch::Routing::UrlFor

          sig { params(args: T.untyped).returns(String) }
          def edit_index_url(*args); end

          sig { params(args: T.untyped).returns(String) }
          def index_url(*args); end

          sig { params(args: T.untyped).returns(String) }
          def new_index_url(*args); end
        end

        class MyClass
          extend GeneratedPathHelpersModule
          extend GeneratedUrlHelpersModule
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end
  end
end
