# typed: false
# frozen_string_literal: true

require "spec_helper"

describe("Tapioca::Compilers::Dsl::ActiveResource") do
  before(:each) do
    require "tapioca/compilers/dsl/active_resource"
  end

  subject do
    Tapioca::Compilers::Dsl::ActiveResource.new
  end

  describe("#initialize") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    it("gathers no constants if there are no ActiveResource classes") do
      assert_empty(subject.processable_constants)
    end

    it("gathers only ActiveResource constants ") do
      content = <<~RUBY
        class Post < ActiveResource::Base
        end

        class Product < Post
        end

        class User
        end
      RUBY

      assert_equal(["Post", "Product"], constants_from(content))
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

    it("generates RBI file for ActiveResource classes with an integer schema field") do
      content = <<~RUBY
        class Post < ActiveResource::Base
          schema do
            integer 'id'
          end
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(Integer) }
          def id; end

          sig { params(value: Integer).returns(Integer) }
          def id=(value); end

          sig { returns(T::Boolean) }
          def id?; end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates RBI file for ActiveResource classes with multiple integer schema fields") do
      content = <<~RUBY
        class Post < ActiveResource::Base
          schema do
            integer 'id', 'month', 'year'
          end
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(Integer) }
          def id; end

          sig { params(value: Integer).returns(Integer) }
          def id=(value); end

          sig { returns(T::Boolean) }
          def id?; end

          sig { returns(Integer) }
          def month; end

          sig { params(value: Integer).returns(Integer) }
          def month=(value); end

          sig { returns(T::Boolean) }
          def month?; end

          sig { returns(Integer) }
          def year; end

          sig { params(value: Integer).returns(Integer) }
          def year=(value); end

          sig { returns(T::Boolean) }
          def year?; end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates RBI file for ActiveResource classes with schema with different types") do
      content = <<~RUBY
        class Post < ActiveResource::Base
          schema do
            integer 'month'
            string  'title'
          end
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(Integer) }
          def month; end

          sig { params(value: Integer).returns(Integer) }
          def month=(value); end

          sig { returns(T::Boolean) }
          def month?; end

          sig { returns(String) }
          def title; end

          sig { params(value: String).returns(String) }
          def title=(value); end

          sig { returns(T::Boolean) }
          def title?; end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates methods for ActiveResource classes with an unsupported schema type") do
      content = <<~RUBY
        class Post < ActiveResource::Base
          schema  do
            attribute 'id',nil
          end
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.untyped) }
          def id; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def id=(value); end

          sig { returns(T::Boolean) }
          def id?; end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end
    it("generates methods for ActiveResource classes including all types in schema field") do
      content = <<~RUBY
        class Post < ActiveResource::Base
          schema do
            boolean  'reviewed'
            integer  'id'
            string   'title'
            float    'price'
            date     'month'
            time     'post_time'
            datetime 'review_time'
            decimal  'credit_point'
            binary   'active'
            text     'message'
          end
        end

      RUBY

      rbi_output = rbi_for(content)

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: T::Boolean).returns(T::Boolean) }
        def reviewed=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: Integer).returns(Integer) }
        def id=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: String).returns(String) }
        def title=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: Float).returns(Float) }
        def price=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: Date).returns(Date) }
        def month=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: Time).returns(Time) }
        def post_time=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: DateTime).returns(DateTime) }
        def review_time=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: BigDecimal).returns(BigDecimal) }
        def credit_point=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: String).returns(String) }
        def active=(value); end
      RUBY

      assert_includes(rbi_output, indented(<<~RUBY, 2))
        sig { params(value: String).returns(String) }
        def message=(value); end
      RUBY
    end
  end
end
