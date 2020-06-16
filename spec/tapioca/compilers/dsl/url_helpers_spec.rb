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
        module MyModule
            include Rails.application.routes.named_routes.path_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["MyModule"])
    end

    it("gathers constants that extend path_helpers_module") do
      content += <<~RUBY
        module MyModule
            extend Rails.application.routes.named_routes.path_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["MyModule"])
    end

    it("gathers constants that include url_helpers_module") do
      content += <<~RUBY
        module MyModule
            include Rails.application.routes.named_routes.url_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["MyModule"])
    end

    it("gathers constants that extend url_helpers_module") do
      content += <<~RUBY
        module MyModule
            extend Rails.application.routes.named_routes.url_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["MyModule"])
    end

    it("gathers constants that include both path_helpers_module and url_helpers_module") do
      content += <<~RUBY
        module MyModule
            include Rails.application.routes.named_routes.path_helpers_module
            include Rails.application.routes.named_routes.url_helpers_module
        end
      RUBY

      assert_equal(constants_from(content), ["MyModule"])
    end
  end

  describe("#decorate") do
    def rbi_for(content)
      with_content(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Test)
        parlour.rbi
      end
    end

    it("TODO") do
      content = <<~RUBY
        class Application < Rails::Application
        end

        class Test
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Test
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("TODO") do
      content = <<~RUBY
        class Application < Rails::Application
          routes.draw do
            resource :test
          end
        end

        class Test
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Test
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end
  end
end
