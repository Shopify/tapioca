# typed: false
# frozen_string_literal: true

require "spec_helper"
require "tapioca/compilers/dsl/action_controller_helpers"

RSpec.describe(Tapioca::Compilers::Dsl::ActionControllerHelpers) do
  describe("#initialize") do
    it("gathers no constants if there are no  classes") do
      expect(subject.processable_constants).to(be_empty)
    end

    it("gathers only ActionController subclasses") do
      content = <<~RUBY
        class UserController < ActionController::Base
        end

        class User
        end
      RUBY

      with_content(content) do
        expect(subject.processable_constants).to(eq(Set.new([UserController])))
      end
    end

    it("does not gather helper modules as their own processable constant") do
      content = <<~RUBY
        module UserHelper
        end

        class UserController < ActionController::Base
          include UserHelper
        end
      RUBY

      with_content(content) do
        expect(subject.processable_constants).to(eq(Set.new([UserController])))
      end
    end

    it("gathers subclasses of ActionController subclasses") do
      content = <<~RUBY
        class UserController < ActionController::Base
        end

        class HandController < UserController
        end
      RUBY

      with_content(content) do
        expect(subject.processable_constants).to(eq(Set.new([UserController, HandController])))
      end
    end

    it("ignores abstract subclasses of ActionController") do
      content = <<~RUBY
        class UserController < ActionController::Base
        end

        class HomeController < ActionController::Base
          abstract!
        end
      RUBY

      with_content(content) do
        expect(subject.processable_constants).to(eq(Set.new([UserController])))
      end
    end
  end
end
