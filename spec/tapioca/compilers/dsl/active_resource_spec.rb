# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveResourceSpec < DslSpec
  describe "Tapioca::Compilers::Dsl::ActiveResource" do
    describe "initialize" do
      it "gathers no constants if there are no ActiveResource classes" do
        assert_empty(gathered_constants)
      end

      it "gathers only ActiveResource constants " do
        add_ruby_file("content.rb", <<~RUBY)
          class Post < ActiveResource::Base
          end

          class Product < Post
          end

          class User
          end
        RUBY

        assert_equal(["Post", "Product"], gathered_constants)
      end
    end

    describe "decorate" do
      it "generates RBI file for ActiveResource classes with an integer schema field" do
        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveResource::Base
            schema do
              integer 'id'
            end
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class Post
            sig { returns(Integer) }
            def id; end

            sig { params(value: Integer).returns(Integer) }
            def id=(value); end

            sig { returns(T::Boolean) }
            def id?; end
          end
        RBI

        assert_equal(expected, rbi_for(:Post))
      end

      it "generates RBI file for ActiveResource classes with multiple integer schema fields" do
        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveResource::Base
            schema do
              integer 'id', 'month', 'year'
            end
          end
        RUBY

        expected = <<~RBI
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
        RBI

        assert_equal(expected, rbi_for(:Post))
      end

      it "generates RBI file for ActiveResource classes with schema with different types" do
        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveResource::Base
            schema do
              integer 'month'
              string  'title'
            end
          end
        RUBY

        expected = <<~RBI
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
        RBI

        assert_equal(expected, rbi_for(:Post))
      end

      it "generates methods for ActiveResource classes with an unsupported schema type" do
        add_ruby_file("post.rb", <<~RUBY)
          class Post < ActiveResource::Base
            schema  do
              attribute 'id',nil
            end
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class Post
            sig { returns(T.untyped) }
            def id; end

            sig { params(value: T.untyped).returns(T.untyped) }
            def id=(value); end

            sig { returns(T::Boolean) }
            def id?; end
          end
        RBI

        assert_equal(expected, rbi_for(:Post))
      end

      it "generates methods for ActiveResource classes including all types in schema field" do
        add_ruby_file("post.rb", <<~RUBY)
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

        rbi_output = rbi_for(:Post)

        assert_includes(rbi_output, indented(<<~RBI, 2))
          sig { params(value: T::Boolean).returns(T::Boolean) }
          def reviewed=(value); end
        RBI

        assert_includes(rbi_output, indented(<<~RBI, 2))
          sig { params(value: Integer).returns(Integer) }
          def id=(value); end
        RBI

        assert_includes(rbi_output, indented(<<~RBI, 2))
          sig { params(value: String).returns(String) }
          def title=(value); end
        RBI

        assert_includes(rbi_output, indented(<<~RBI, 2))
          sig { params(value: Float).returns(Float) }
          def price=(value); end
        RBI

        assert_includes(rbi_output, indented(<<~RBI, 2))
          sig { params(value: Date).returns(Date) }
          def month=(value); end
        RBI

        assert_includes(rbi_output, indented(<<~RBI, 2))
          sig { params(value: Time).returns(Time) }
          def post_time=(value); end
        RBI

        assert_includes(rbi_output, indented(<<~RBI, 2))
          sig { params(value: DateTime).returns(DateTime) }
          def review_time=(value); end
        RBI

        assert_includes(rbi_output, indented(<<~RBI, 2))
          sig { params(value: BigDecimal).returns(BigDecimal) }
          def credit_point=(value); end
        RBI

        assert_includes(rbi_output, indented(<<~RBI, 2))
          sig { params(value: String).returns(String) }
          def active=(value); end
        RBI

        assert_includes(rbi_output, indented(<<~RBI, 2))
          sig { params(value: String).returns(String) }
          def message=(value); end
        RBI
      end
    end
  end
end
