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

  describe("#decorate") do
    def rbi_for(content)
      with_content(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, UserController)
        parlour.rbi
      end
    end

    #TODO: Add more tests and reorder as necessary

    #TODO: Combining the helper module and controller in the same file should be fine. Don't split


    it("does not generate helper module when there are no helper methods") do
    end

    it("generates helper proxy class when there are no helper methods") do # TODO: Idk if this happens
    end

    it("generates helper module and helper proxy class when there are helper methods") do
    end

    it("does not generate helper methods when there are no helper methods specified") do
    end

  end
end
