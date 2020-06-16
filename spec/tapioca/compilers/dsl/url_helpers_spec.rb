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

      assert_equal(constants_from(content), ["ActionDispatch::IntegrationTest", "GeneratedPathHelpersModule", "GeneratedUrlHelpersModule", "MyClass"])
    end

    it("gathers constants that extend path_helpers_module") do
      content += <<~RUBY
        class MyClass
          extend Rails.application.routes.named_routes.path_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["ActionDispatch::IntegrationTest", "GeneratedPathHelpersModule", "GeneratedUrlHelpersModule", "MyClass"])
    end

    it("gathers constants that include url_helpers_module") do
      content += <<~RUBY
        class MyClass
          include Rails.application.routes.named_routes.url_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["ActionDispatch::IntegrationTest", "GeneratedPathHelpersModule", "GeneratedUrlHelpersModule", "MyClass"])
    end

    it("gathers constants that extend url_helpers_module") do
      content += <<~RUBY
        class MyClass
          extend Rails.application.routes.named_routes.url_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["ActionDispatch::IntegrationTest", "GeneratedPathHelpersModule", "GeneratedUrlHelpersModule", "MyClass"])
    end

    it("gathers constants that include both path_helpers_module and url_helpers_module") do
      content += <<~RUBY
        class MyClass
          include Rails.application.routes.named_routes.path_helpers_module
          include Rails.application.routes.named_routes.url_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["ActionDispatch::IntegrationTest", "GeneratedPathHelpersModule", "GeneratedUrlHelpersModule", "MyClass"])
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

    it("generates RBI for constant that includes path_helpers_module") do
      content += <<~RUBY
        class MyClass
          include Rails.application.routes.named_routes.path_helpers_module
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class MyClass
          include GeneratedPathHelpersModule
        end
      RUBY

      assert_equal(rbi_for(content, :MyClass), expected)
    end

    it("generates RBI for constant that includes url_helpers_module") do
      content += <<~RUBY
        class MyClass
          include Rails.application.routes.named_routes.url_helpers_module
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class MyClass
          include GeneratedUrlHelpersModule
        end
      RUBY

      assert_equal(rbi_for(content, :MyClass), expected)
    end

    it("generates RBI for constant that has a superclass which includes path_helpers_module") do
      content += <<~RUBY
        class MySuperClass
          include Rails.application.routes.named_routes.path_helpers_module
        end

        class MyClass < MySuperClass
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class MyClass
          include GeneratedPathHelpersModule
          extend GeneratedPathHelpersModule
        end
      RUBY

      assert_equal(rbi_for(content, :MyClass), expected)
    end

    it("generates RBI for constant that has a superclass which extends path_helpers_module") do
      content += <<~RUBY
        class MySuperClass
          include Rails.application.routes.named_routes.url_helpers_module
        end

        class MyClass < MySuperClass
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class MyClass
          include GeneratedUrlHelpersModule
          extend GeneratedUrlHelpersModule
        end
      RUBY

      assert_equal(rbi_for(content, :MyClass), expected)
    end

    # TODO: Confirm both include and extend is OK in the generation above
    # TODO: Test generation of the 2 modules by passing those constant names
  end
end

        # class Application < Rails::Application
        #   routes.draw do
        #     resource :index
        #   end
        # end
        # # typed: strong
        # class ActionDispatch::IntegrationTest
        #   include GenerateUrlHelpersModule
        #   include GeneratedPathHelpersModule
        # end

        # module GeneratedPathHelpersModule
        #   include ActionDispatch::Routing::PolymorphicRoutes
        #   include ActionDispatch::Routing::UrlFor

        #   sig { params(args: T.untyped).returns(String) }
        #   def edit_index_path(*args); end

        #   sig { params(args: T.untyped).returns(String) }
        #   def index_path(*args); end

        #   sig { params(args: T.untyped).returns(String) }
        #   def new_index_path(*args); end
        # end

        # module GeneratedUrlHelpersModule
        #   include ActionDispatch::Routing::PolymorphicRoutes
        #   include ActionDispatch::Routing::UrlFor

        #   sig { params(args: T.untyped).returns(String) }
        #   def edit_index_url(*args); end

        #   sig { params(args: T.untyped).returns(String) }
        #   def index_url(*args); end

        #   sig { params(args: T.untyped).returns(String) }
        #   def new_index_url(*args); end
        # end

        # class MyClass
        #   extend GeneratedPathHelpersModule
        #   extend GeneratedUrlHelpersModule
        # end
