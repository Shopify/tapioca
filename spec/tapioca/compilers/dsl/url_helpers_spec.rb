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
    it("gathers ActionDispatch::Routing::RouteSet::NamedRouteCollection") do
      assert_equal(subject.processable_constants, Set.new([ActionDispatch::Routing::RouteSet::NamedRouteCollection]))
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
