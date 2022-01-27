# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::SmartPropertiesSpec < DslSpec
  describe("#initialize") do
    after do
      T.unsafe(self).assert_no_generated_errors
    end

    it("gathers no constants if there are no SmartProperty classes") do
      assert_empty(gathered_constants)
    end

    it("gathers only SmartProperty classes and modules") do
      add_ruby_file("content.rb", <<~RUBY)
        class Post
          include ::SmartProperties
        end

        class User
          include ::SmartProperties
        end

        class Comment
        end

        module Viewable
          include ::SmartProperties
        end

        module Editable
        end
      RUBY

      assert_equal(["Post", "User", "Viewable"], gathered_constants)
    end

    it("ignores SmartProperty classes and modules without a name") do
      add_ruby_file("content.rb", <<~RUBY)
        post = Class.new do
          include ::SmartProperties
        end

        viewable = Module.new do
          include ::SmartProperties
        end
      RUBY

      assert_empty(gathered_constants)
    end
  end

  describe("#decorate") do
    after do
      T.unsafe(self).assert_no_generated_errors
    end

    it("generates empty RBI file if there are no smart properties") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
        end
      RUBY

      expected = <<~RBI
        # typed: strong
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for simple smart property class") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :title, accepts: String
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(::String)) }
            def title; end

            sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
            def title=(title); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for simple smart property module") do
      add_ruby_file("viewable.rb", <<~RUBY)
        module Viewable
          include SmartProperties
          property :title, accepts: String
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        module Viewable
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(::String)) }
            def title; end

            sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
            def title=(title); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Viewable))
    end

    it("generates RBI file for required smart property") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property! :description, accepts: String
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(::String) }
            def description; end

            sig { params(description: ::String).returns(::String) }
            def description=(description); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("defaults to T.untyped for smart property that does not have an accepter") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :title
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.untyped) }
            def title; end

            sig { params(title: T.untyped).returns(T.untyped) }
            def title=(title); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("defaults to T::Array for smart property that accepts Arrays") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :categories, accepts: Array
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(T::Array[T.untyped])) }
            def categories; end

            sig { params(categories: T.nilable(T::Array[T.untyped])).returns(T.nilable(T::Array[T.untyped])) }
            def categories=(categories); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for smart property that accepts booleans") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :published, accepts: [true, false]
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(T::Boolean)) }
            def published; end

            sig { params(published: T.nilable(T::Boolean)).returns(T.nilable(T::Boolean)) }
            def published=(published); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for smart property that accepts an array of values") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :status, accepts: [String, Integer]
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(T.any(::String, ::Integer))) }
            def status; end

            sig { params(status: T.nilable(T.any(::String, ::Integer))).returns(T.nilable(T.any(::String, ::Integer))) }
            def status=(status); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("defaults to T.untyped if a converter is defined") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :status, accepts: Integer, converts: :to_s
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.untyped) }
            def status; end

            sig { params(status: T.untyped).returns(T.untyped) }
            def status=(status); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("ignores required if it is a lambda") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :status, accepts: Integer, required: -> { true }
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(::Integer)) }
            def status; end

            sig { params(status: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
            def status=(status); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("ignores required if property is not typed") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :status, required: true
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.untyped) }
            def status; end

            sig { params(status: T.untyped).returns(T.untyped) }
            def status=(status); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates a reader that has been renamed correctly") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :status, accepts: Integer, reader: :reader_for_status
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(::Integer)) }
            def reader_for_status; end

            sig { params(status: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
            def status=(status); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for smart property that accepts boolean and has a default") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :enabled, accepts: [true, false], default: false
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(T::Boolean)) }
            def enabled; end

            sig { params(enabled: T.nilable(T::Boolean)).returns(T.nilable(T::Boolean)) }
            def enabled=(enabled); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for smart property that accepts boolean and has lambda as default") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :enabled, accepts: [true, false], default: -> {}
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(T::Boolean)) }
            def enabled; end

            sig { params(enabled: T.nilable(T::Boolean)).returns(T.nilable(T::Boolean)) }
            def enabled=(enabled); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for smart property that accepts String and has a non-nil default") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :title, accepts: String, default: "here"
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(::String)) }
            def title; end

            sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
            def title=(title); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for smart property that accepts String and has a nil default") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :title, accepts: String, default: nil
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(::String)) }
            def title; end

            sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
            def title=(title); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for smart property that accepts a lambda") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :title, accepts: lambda { |title| /^Lorem \w+$/ =~ title }
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.untyped) }
            def title; end

            sig { params(title: T.untyped).returns(T.untyped) }
            def title=(title); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates smart properties that have been overriden") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties
          property :title, accepts: String
          property :body, accepts: String

          protected :body

          def body
            "body"
          end

          def title
            "title"
          end

          def title=
          end
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(::String)) }
            def body; end

            sig { params(body: T.nilable(::String)).returns(T.nilable(::String)) }
            def body=(body); end

            sig { returns(T.nilable(::String)) }
            def title; end

            sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
            def title=(title); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for smart property that accepts another ObjectClass") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post
          include SmartProperties

          class TrackingInfoInput
            include SmartProperties

            property! :number, accepts: String
            property :carrier_id, accepts: String
            property :url, accepts: String
          end

          property :title, accepts: TrackingInfoInput
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(::Post::TrackingInfoInput)) }
            def title; end

            sig { params(title: T.nilable(::Post::TrackingInfoInput)).returns(T.nilable(::Post::TrackingInfoInput)) }
            def title=(title); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))

      expected = <<~RBI
        # typed: strong

        class Post::TrackingInfoInput
          include SmartPropertiesGeneratedMethods

          module SmartPropertiesGeneratedMethods
            sig { returns(T.nilable(::String)) }
            def carrier_id; end

            sig { params(carrier_id: T.nilable(::String)).returns(T.nilable(::String)) }
            def carrier_id=(carrier_id); end

            sig { returns(::String) }
            def number; end

            sig { params(number: ::String).returns(::String) }
            def number=(number); end

            sig { returns(T.nilable(::String)) }
            def url; end

            sig { params(url: T.nilable(::String)).returns(T.nilable(::String)) }
            def url=(url); end
          end
        end
      RBI

      assert_equal(expected, rbi_for("Post::TrackingInfoInput"))
    end
  end
end
