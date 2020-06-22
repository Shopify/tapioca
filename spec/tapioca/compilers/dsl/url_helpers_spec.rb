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

    it("does not gather constants when url_helpers is not included") do
      content += <<~RUBY
        class MyClass
        end
      RUBY

      assert_equal([
        "ActionDispatch::IntegrationTest",
        "GeneratedPathHelpersModule",
        "GeneratedUrlHelpersModule",
      ], constants_from(content))
    end

    it("gathers constants that include url_helpers") do
      content += <<~RUBY
        class MyClass
          include Rails.application.routes.url_helpers
        end
      RUBY

      assert_equal([
        "ActionDispatch::IntegrationTest",
        "GeneratedPathHelpersModule",
        "GeneratedUrlHelpersModule",
        "MyClass",
      ], constants_from(content))
    end

    it("gathers constants that extend url_helpers") do
      content += <<~RUBY
        class MyClass
          extend Rails.application.routes.url_helpers
        end
      RUBY

      assert_equal([
        "ActionDispatch::IntegrationTest",
        "GeneratedPathHelpersModule",
        "GeneratedUrlHelpersModule",
        "MyClass",
      ], constants_from(content))
    end

    it("gathers constants that have a singleton class that includes url_helpers") do
      content += <<~RUBY
        class MyClass
          class << self
            include Rails.application.routes.url_helpers
          end
        end
      RUBY

      assert_equal([
        "ActionDispatch::IntegrationTest",
        "GeneratedPathHelpersModule",
        "GeneratedUrlHelpersModule",
        "MyClass",
      ], constants_from(content))
    end

    it("does not gather constants when its superclass includes url_helpers") do
      content += <<~RUBY
        class SuperClass
          include Rails.application.routes.url_helpers
        end

        class MyClass < SuperClass
        end
      RUBY

      assert_equal([
        "ActionDispatch::IntegrationTest",
        "GeneratedPathHelpersModule",
        "GeneratedUrlHelpersModule",
        "SuperClass",
      ], constants_from(content))
    end

    it("gathers constants when its superclass extends url_helpers") do
      content += <<~RUBY
        class SuperClass
          extend Rails.application.routes.url_helpers
        end

        class MyClass < SuperClass
        end
      RUBY

      assert_equal([
        "ActionDispatch::IntegrationTest",
        "GeneratedPathHelpersModule",
        "GeneratedUrlHelpersModule",
        "SuperClass",
      ], constants_from(content))
    end

    it("does not gather constants when the constant and its superclass includes url_helpers") do
      content += <<~RUBY
        class SuperClass
          include Rails.application.routes.url_helpers
        end

        class MyClass < SuperClass
          include Rails.application.routes.url_helpers
        end
      RUBY

      assert_equal([
        "ActionDispatch::IntegrationTest",
        "GeneratedPathHelpersModule",
        "GeneratedUrlHelpersModule",
        "SuperClass",
      ], constants_from(content))
    end
  end

  describe("#decorate") do
    def rbi_for(content, constant)
      with_content(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Object.const_get(constant))
        parlour.rbi
      end
    end

    content = <<~RUBY
      class Application < Rails::Application
      end
    RUBY

    it("generates RBI when there are no helper methods") do
      expected = <<~RUBY
        # typed: strong
        module GeneratedUrlHelpersModule
          include ActionDispatch::Routing::PolymorphicRoutes
          include ActionDispatch::Routing::UrlFor
        end
      RUBY

      assert_equal(expected, rbi_for(content, :GeneratedUrlHelpersModule))
    end

    it("generates RBI for GeneratedPathHelpersModule with helper methods") do
      content = <<~RUBY
        class Application < Rails::Application
          routes.draw do
            resource :index
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
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
      RUBY

      assert_equal(expected, rbi_for(content, :GeneratedPathHelpersModule))
    end

    it("generates RBI for GeneratedUrlHelpersModule with helper methods") do
      content = <<~RUBY
        class Application < Rails::Application
          routes.draw do
            resource :index
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
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
      RUBY

      assert_equal(expected, rbi_for(content, :GeneratedUrlHelpersModule))
    end

    it("generates RBI for constant that includes url_helpers") do
      content += <<~RUBY
        class MyClass
          include Rails.application.routes.url_helpers
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class MyClass
          include GeneratedPathHelpersModule
          include GeneratedUrlHelpersModule
        end
      RUBY

      assert_equal(expected, rbi_for(content, :MyClass))
    end

    it("generates RBI for constant that extends url_helpers") do
      content += <<~RUBY
        class MyClass
          extend Rails.application.routes.url_helpers
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class MyClass
          extend GeneratedPathHelpersModule
          extend GeneratedUrlHelpersModule
        end
      RUBY

      assert_equal(expected, rbi_for(content, :MyClass))
    end

    it("generates RBI for constant that includes and extends url_helpers") do
      content += <<~RUBY
        class MyClass
          include Rails.application.routes.url_helpers
          extend Rails.application.routes.url_helpers
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class MyClass
          include GeneratedPathHelpersModule
          include GeneratedUrlHelpersModule
          extend GeneratedPathHelpersModule
          extend GeneratedUrlHelpersModule
        end
      RUBY

      assert_equal(expected, rbi_for(content, :MyClass))
    end

    it("generates RBI for constant that has a singleton class which includes url_helpers") do
      content += <<~RUBY
        class MyClass
          class << self
            include Rails.application.routes.url_helpers
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class MyClass
          extend GeneratedPathHelpersModule
          extend GeneratedUrlHelpersModule
        end
      RUBY

      assert_equal(expected, rbi_for(content, :MyClass))
    end

    it("generates RBI when constant itself and its singleton class includes url_helpers") do
      content += <<~RUBY
        class MyClass
          include Rails.application.routes.url_helpers
          class << self
            include Rails.application.routes.url_helpers
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class MyClass
          include GeneratedPathHelpersModule
          include GeneratedUrlHelpersModule
          extend GeneratedPathHelpersModule
          extend GeneratedUrlHelpersModule
        end
      RUBY

      assert_equal(expected, rbi_for(content, :MyClass))
    end
  end
end
