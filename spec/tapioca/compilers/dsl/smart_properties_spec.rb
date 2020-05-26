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

  describe("#decorate") do
    it("generates empty RBI file if there are no smart properties") do
      content = <<~RUBY
        class Post
          include SmartProperties
        end
      RUBY

      with_contents(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Post)
        expect(parlour.rbi).to(eq("# typed: strong\n\n"))
      end
    end

    it("generates RBI file if there are smart properties") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property :title, accepts: String
          property! :description, accepts: String
          property :published, accepts: [true, false], reader: :published?
          property :enabled, accepts: [true, false], default: false
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(::String) }
          def description; end

          sig { params(description: ::String).returns(::String) }
          def description=(description); end

          sig { returns(T.nilable(T::Boolean)) }
          def enabled; end

          sig { params(enabled: T.nilable(T::Boolean)).returns(T.nilable(T::Boolean)) }
          def enabled=(enabled); end

          sig { params(published: T.nilable(T::Boolean)).returns(T.nilable(T::Boolean)) }
          def published=(published); end

          sig { returns(T.nilable(T::Boolean)) }
          def published?; end

          sig { returns(T.nilable(::String)) }
          def title; end

          sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
          def title=(title); end
        end
      RUBY

      with_contents(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Post)
        expect(parlour.rbi).to(eq(expected))
      end
    end
  end
end
