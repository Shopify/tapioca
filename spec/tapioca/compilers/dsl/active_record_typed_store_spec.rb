# typed: false
# frozen_string_literal: true

require "spec_helper"

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
        class Shop < ActiveRecord::Base
        end

        class User
        end
      RUBY

      expect(constants_from(content)).to(eq(["Post"]))
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

    it("generate RBI for TypedStore classes without accessor") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadatado do |s|
            s.string(:reviewer, blank: false, accessor: false)
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong

      RUBY

      expect(rbi_for(content)).to(eq(expected))
    end

    it("generate RBI for TypedStore classes with accessor") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.string(:reviewer, blank: false, accessor: true)
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
        end
       RUBY

      expect(rbi_for(content)).to(eq(expected))
    end

    it("generate RBI for TypedStore classes with fields nul and default as false") do
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

    it("generate RBI for simple TypedStore classes with no fields specified ") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
          typed_store :metadata do |s|
            s.date(:review_date)
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
        end
        RUBY

      expect(rbi_for(content)).to(eq(expected))
    end
  end
end
