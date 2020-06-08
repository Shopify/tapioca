# typed: false
# frozen_string_literal: true

require "spec_helper"
require "active_record"

RSpec.describe(Tapioca::Compilers::Dsl::ActiveRecordTypedStore) do
  describe("#initialize") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    it("gathers no constants if there are no ActiveRecordTypedStore classes") do
      expect(subject.processable_constants).to(be_empty)
    end

    it("gather only TypedStore classes") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.string(:reviewer, blank: false, accessor: false)
          end
        end

        class CustomPost < Post
        end

        class Shop < ActiveRecord::Base
        end

        class User
        end
      RUBY

      expect(constants_from(content)).to(eq(["CustomPost", "Post"]))
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

    it("generates no definitions if there are no accessors to define") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.string(:reviewer, blank: false, accessor: false)
          end

          typed_store :properties, accessors: false do |s|
            s.string(:title)
            s.integer(:comment_count)
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong

      RUBY

      expect(rbi_for(content)).to(eq(expected))
    end

    it("generates RBI for TypedStore classes with string type") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.string(:reviewer)
          end

          typed_store :properties do |s|
            s.string(:title)
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(String)) }
          def reviewer; end

          sig { params(reviewer: T.nilable(String)).returns(T.nilable(String)) }
          def reviewer=(reviewer); end

          sig { returns(T::Boolean) }
          def reviewer?; end

          sig { returns(T.nilable(String)) }
          def reviewer_before_last_save; end

          sig { returns(T.nilable([T.nilable(String), T.nilable(String)])) }
          def reviewer_change; end

          sig { returns(T::Boolean) }
          def reviewer_changed?; end

          sig { returns(T.nilable(String)) }
          def reviewer_was; end

          sig { returns(T.nilable([T.nilable(String), T.nilable(String)])) }
          def saved_change_to_reviewer; end

          sig { returns(T::Boolean) }
          def saved_change_to_reviewer?; end

          sig { returns(T.nilable([T.nilable(String), T.nilable(String)])) }
          def saved_change_to_title; end

          sig { returns(T::Boolean) }
          def saved_change_to_title?; end

          sig { returns(T.nilable(String)) }
          def title; end

          sig { params(title: T.nilable(String)).returns(T.nilable(String)) }
          def title=(title); end

          sig { returns(T::Boolean) }
          def title?; end

          sig { returns(T.nilable(String)) }
          def title_before_last_save; end

          sig { returns(T.nilable([T.nilable(String), T.nilable(String)])) }
          def title_change; end

          sig { returns(T::Boolean) }
          def title_changed?; end

          sig { returns(T.nilable(String)) }
          def title_was; end
        end
       RUBY

      expect(rbi_for(content)).to(eq(expected))
    end

    it("generates methods with non-nilable types for accessors marked as not null") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.boolean(:reviewed, null: false, default: false)
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T::Boolean) }
          def reviewed; end

          sig { params(reviewed: T::Boolean).returns(T::Boolean) }
          def reviewed=(reviewed); end

          sig { returns(T::Boolean) }
          def reviewed?; end

          sig { returns(T::Boolean) }
          def reviewed_before_last_save; end

          sig { returns(T.nilable([T::Boolean, T::Boolean])) }
          def reviewed_change; end

          sig { returns(T::Boolean) }
          def reviewed_changed?; end

          sig { returns(T::Boolean) }
          def reviewed_was; end

          sig { returns(T.nilable([T::Boolean, T::Boolean])) }
          def saved_change_to_reviewed; end

          sig { returns(T::Boolean) }
          def saved_change_to_reviewed?; end
        end
        RUBY

      expect(rbi_for(content)).to(eq(expected))
    end

    it("generates methods with Date type for attributes with date type") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.date(:review_date)
          end

          typed_store :properties do |s|
            s.date(:title_date)
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(Date)) }
          def review_date; end

          sig { params(review_date: T.nilable(Date)).returns(T.nilable(Date)) }
          def review_date=(review_date); end

          sig { returns(T::Boolean) }
          def review_date?; end

          sig { returns(T.nilable(Date)) }
          def review_date_before_last_save; end

          sig { returns(T.nilable([T.nilable(Date), T.nilable(Date)])) }
          def review_date_change; end

          sig { returns(T::Boolean) }
          def review_date_changed?; end

          sig { returns(T.nilable(Date)) }
          def review_date_was; end

          sig { returns(T.nilable([T.nilable(Date), T.nilable(Date)])) }
          def saved_change_to_review_date; end

          sig { returns(T::Boolean) }
          def saved_change_to_review_date?; end

          sig { returns(T.nilable([T.nilable(Date), T.nilable(Date)])) }
          def saved_change_to_title_date; end

          sig { returns(T::Boolean) }
          def saved_change_to_title_date?; end

          sig { returns(T.nilable(Date)) }
          def title_date; end

          sig { params(title_date: T.nilable(Date)).returns(T.nilable(Date)) }
          def title_date=(title_date); end

          sig { returns(T::Boolean) }
          def title_date?; end

          sig { returns(T.nilable(Date)) }
          def title_date_before_last_save; end

          sig { returns(T.nilable([T.nilable(Date), T.nilable(Date)])) }
          def title_date_change; end

          sig { returns(T::Boolean) }
          def title_date_changed?; end

          sig { returns(T.nilable(Date)) }
          def title_date_was; end
        end
        RUBY

      expect(rbi_for(content)).to(eq(expected))
    end

    it("generates methods with DteTime type for attributes with datetime type") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.datetime(:review_date)
          end

        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(DateTime)) }
          def review_date; end

          sig { params(review_date: T.nilable(DateTime)).returns(T.nilable(DateTime)) }
          def review_date=(review_date); end

        RUBY
      expect(rbi_for(content)).to(include(expected))
    end

    it("generates methods with Time type for attributes with time type") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.time(:review_time)
          end

        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(Time)) }
          def review_time; end

          sig { params(review_time: T.nilable(Time)).returns(T.nilable(Time)) }
          def review_time=(review_time); end

        RUBY
      expect(rbi_for(content)).to(include(expected))
    end

    it("generates methods with Decimal type for attributes with decimal type") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.decimal(:rate)
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(BigDecimal)) }
          def rate; end

          sig { params(rate: T.nilable(BigDecimal)).returns(T.nilable(BigDecimal)) }
          def rate=(rate); end
        RUBY
      expect(rbi_for(content)).to(include(expected))
    end

    it("generates methods with T.untyped type for attributes with any type") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.any(:kind)
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.untyped) }
          def kind; end

          sig { params(kind: T.untyped).returns(T.untyped) }
          def kind=(kind); end
        RUBY
      expect(rbi_for(content)).to(include(expected))
    end

    it("generates methods with Integer type for attributes with integer type") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.integer(:rate)
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(Integer)) }
          def rate; end

          sig { params(rate: T.nilable(Integer)).returns(T.nilable(Integer)) }
          def rate=(rate); end
        RUBY
      expect(rbi_for(content)).to(include(expected))
    end

    it("generates methods with Float type for attributes with float type") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.float(:rate)
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Post
          sig { returns(T.nilable(Float)) }
          def rate; end

          sig { params(rate: T.nilable(Float)).returns(T.nilable(Float)) }
          def rate=(rate); end
        RUBY
      expect(rbi_for(content)).to(include(expected))
    end
  end
end
