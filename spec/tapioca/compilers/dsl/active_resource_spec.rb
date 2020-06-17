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

        class Product < ActiveRecord::Base
        end

        class User
        end
      RUBY

      assert_equal(constants_from(content), ["Post"])
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

          sig { params(id: Integer).returns(Integer) }
          def id=(id); end

          sig { returns(T::Boolean) }
          def id?; end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
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

          sig { params(id: Integer).returns(Integer) }
          def id=(id); end

          sig { returns(T::Boolean) }
          def id?; end

          sig { returns(Integer) }
          def month; end

          sig { params(month: Integer).returns(Integer) }
          def month=(month); end

          sig { returns(T::Boolean) }
          def month?; end

          sig { returns(Integer) }
          def year; end

          sig { params(year: Integer).returns(Integer) }
          def year=(year); end

          sig { returns(T::Boolean) }
          def year?; end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for ActiveResource classes with two type schema fields") do
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

          sig { params(month: Integer).returns(Integer) }
          def month=(month); end

          sig { returns(T::Boolean) }
          def month?; end

          sig { returns(String) }
          def title; end

          sig { params(title: String).returns(String) }
          def title=(title); end

          sig { returns(T::Boolean) }
          def title?; end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end

    it("generates RBI file for ActiveResource classes including boolean type schema field") do
      content = <<~RUBY
        class Post < ActiveResource::Base
          schema do
            integer 'month'
            string  'title'
            boolean 'reviewed'
          end
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(Integer) }
          def month; end

          sig { params(month: Integer).returns(Integer) }
          def month=(month); end

          sig { returns(T::Boolean) }
          def month?; end

          sig { returns(T::Boolean) }
          def reviewed; end

          sig { params(reviewed: T::Boolean).returns(T::Boolean) }
          def reviewed=(reviewed); end

          sig { returns(T::Boolean) }
          def reviewed?; end

          sig { returns(String) }
          def title; end

          sig { params(title: String).returns(String) }
          def title=(title); end

          sig { returns(T::Boolean) }
          def title?; end
        end
      RUBY

      assert_equal(rbi_for(content), expected)
    end
  end
end
