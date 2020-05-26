# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Tapioca::Compilers::Dsl::SmartProperties) do
  describe("#initialize") do
    it("gathers no constants if there are no SmartProperty classes") do
      expect(subject.processable_constants).to(be_empty)
    end

    it("gathers only SmartProperty classes") do
      content = <<~RUBY
        class Post
          include ::SmartProperties
        end

        class User
          include ::SmartProperties
        end

        class Comment
        end
      RUBY

      with_contents(content) do
        expect(subject.processable_constants).to(eq(Set.new([Post, User])))
      end
    end

    it("ignores SmartProperty classes without a name") do
      content = <<~RUBY
        class Post
          include ::SmartProperties

          def self.name
            nil
          end
        end
      RUBY

      with_contents(content) do
        expect(subject.processable_constants).to(be_empty)
      end
    end
  end
end
