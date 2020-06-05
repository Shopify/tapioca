# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Tapioca::Compilers::Dsl::ActiveRecordTypedStore) do
  describe("#initialize") do
    it("gathers no constants if there are no ActiveRecordTypedStore classes") do
      expect(subject.processable_constants).to(be_empty)
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
          typed_store :metadatado do |s|
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
  end
end
