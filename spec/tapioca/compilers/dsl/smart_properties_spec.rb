# typed: false
# frozen_string_literal: true

require "spec_helper"

describe("Tapioca::Compilers::Dsl::SmartProperties") do
  before(:each) do
    require "tapioca/compilers/dsl/smart_properties"
  end

  subject do
    Tapioca::Compilers::Dsl::SmartProperties.new
  end

  describe("#initialize") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    it("gathers no constants if there are no SmartProperty classes") do
      assert_empty(subject.processable_constants)
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

      assert_equal(constants_from(content), ["Post", "User"])
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

      assert_empty(constants_from(content))
    end
  end

  describe("#decorate") do
    def rbi_for(content)
      with_content(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Post)
        parlour.rbi
      end
    end

    it("generates empty RBI file if there are no smart properties") do
      content = <<~RUBY
        class Post
          include SmartProperties
        end
      RUBY

      expected = <<~RUBY
        # typed: strong

      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for simple smart property") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property :title, accepts: String
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(::String)) }
          def title; end

          sig { params(title: T.nilable(::String)).returns(T.nilable(::String)) }
          def title=(title); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for required smart property") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property! :description, accepts: String
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(::String) }
          def description; end

          sig { params(description: ::String).returns(::String) }
          def description=(description); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("defaults to T.untyped for smart property that does not have an accepter") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property :title
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.untyped) }
          def title; end

          sig { params(title: T.untyped).returns(T.untyped) }
          def title=(title); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("defaults to T::Array for smart property that accepts Arrays") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property :categories, accepts: Array
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(T::Array[T.untyped])) }
          def categories; end

          sig { params(categories: T.nilable(T::Array[T.untyped])).returns(T.nilable(T::Array[T.untyped])) }
          def categories=(categories); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for smart property that accepts booleans") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property :published, accepts: [true, false]
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(T::Boolean)) }
          def published; end

          sig { params(published: T.nilable(T::Boolean)).returns(T.nilable(T::Boolean)) }
          def published=(published); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for smart property that accepts an array of values") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property :status, accepts: [String, Integer]
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(T.any(::String, ::Integer))) }
          def status; end

          sig { params(status: T.nilable(T.any(::String, ::Integer))).returns(T.nilable(T.any(::String, ::Integer))) }
          def status=(status); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("defaults to T.untyped if a converter is defined") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property :status, accepts: Integer, converts: :to_s
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.untyped) }
          def status; end

          sig { params(status: T.untyped).returns(T.untyped) }
          def status=(status); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("ignores required if it is a lambda") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property :status, accepts: Integer, required: -> { true }
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(::Integer)) }
          def status; end

          sig { params(status: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
          def status=(status); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("ignores required if property is not typed") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property :status, required: true
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.untyped) }
          def status; end

          sig { params(status: T.untyped).returns(T.untyped) }
          def status=(status); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates a reader that has been renamed correctly") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property :status, accepts: Integer, reader: :reader_for_status
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(::Integer)) }
          def reader_for_status; end

          sig { params(status: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
          def status=(status); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for smart property that accepts boolean and has a default") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property :enabled, accepts: [true, false], default: false
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(T::Boolean)) }
          def enabled; end

          sig { params(enabled: T.nilable(T::Boolean)).returns(T.nilable(T::Boolean)) }
          def enabled=(enabled); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for smart property that accepts a lambda") do
      content = <<~RUBY
        class Post
          include SmartProperties
          property :title, accepts: lambda { |title| /^Lorem \w+$/ =~ title }
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.untyped) }
          def title; end

          sig { params(title: T.untyped).returns(T.untyped) }
          def title=(title); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for smart property that accepts another ObjectClass") do
      content = <<~RUBY
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

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(::Post::TrackingInfoInput)) }
          def title; end

          sig { params(title: T.nilable(::Post::TrackingInfoInput)).returns(T.nilable(::Post::TrackingInfoInput)) }
          def title=(title); end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end
  end
end
