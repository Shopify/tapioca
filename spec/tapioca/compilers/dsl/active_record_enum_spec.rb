# typed: false
# frozen_string_literal: true

require "spec_helper"

describe("Tapioca::Compilers::Dsl::ActiveRecordEnum") do
  before(:each) do
    require "tapioca/compilers/dsl/active_record_enum"
  end

  subject do
    Tapioca::Compilers::Dsl::ActiveRecordEnum.new
  end

  describe("#initialize") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    it("gathers no constants if there are no ActiveRecord classes") do
      assert_empty(subject.processable_constants)
    end

    it("gathers only ActiveRecord constants with no abstract classes") do
      content = <<~RUBY
        class Conversation < ActiveRecord::Base
        end

        class Product < ActiveRecord::Base
          self.abstract_class = true
        end

        class User
        end
      RUBY

      assert_equal(["Conversation"], constants_from(content))
    end
  end

  describe("#decorate") do
    def rbi_for(content)
      with_content(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Conversation)
        parlour.rbi
      end
    end

    it("generates RBI file for classes with an enum attribute") do
      content = <<~RUBY
        class Conversation < ActiveRecord::Base
          enum status: [ :active, :archived ]
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Conversation
          include Conversation::EnumMethodsModule

          sig { returns(T::Hash[T.any(String, Symbol), Integer]) }
          def self.statuses; end
        end

        module Conversation::EnumMethodsModule
          sig { void }
          def active!; end

          sig { returns(T::Boolean) }
          def active?; end

          sig { void }
          def archived!; end

          sig { returns(T::Boolean) }
          def archived?; end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates RBI file for classes with an enum attribute with string values") do
      content = <<~RUBY
        class Conversation < ActiveRecord::Base
          enum status: { active: "0", archived: "1" }
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Conversation
          include Conversation::EnumMethodsModule

          sig { returns(T::Hash[T.any(String, Symbol), String]) }
          def self.statuses; end
        end

        module Conversation::EnumMethodsModule
          sig { void }
          def active!; end

          sig { returns(T::Boolean) }
          def active?; end

          sig { void }
          def archived!; end

          sig { returns(T::Boolean) }
          def archived?; end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates RBI file for classes with an enum attribute with mix value types") do
      content = <<~RUBY
        class Conversation < ActiveRecord::Base
          enum status: { active: 0, archived: true, inactive: "Inactive" }
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Conversation
          include Conversation::EnumMethodsModule

          sig { returns(T::Hash[T.any(String, Symbol), T.any(Integer, TrueClass, String)]) }
          def self.statuses; end
        end

        module Conversation::EnumMethodsModule
          sig { void }
          def active!; end

          sig { returns(T::Boolean) }
          def active?; end

          sig { void }
          def archived!; end

          sig { returns(T::Boolean) }
          def archived?; end

          sig { void }
          def inactive!; end

          sig { returns(T::Boolean) }
          def inactive?; end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates RBI file for classes with multiple enum attributes") do
      content = <<~RUBY
        class Conversation < ActiveRecord::Base
          enum status: [ :active, :archived ]
          enum comments_status: [:on, :off]
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Conversation
          include Conversation::EnumMethodsModule

          sig { returns(T::Hash[T.any(String, Symbol), Integer]) }
          def self.comments_statuses; end

          sig { returns(T::Hash[T.any(String, Symbol), Integer]) }
          def self.statuses; end
        end

        module Conversation::EnumMethodsModule
          sig { void }
          def active!; end

          sig { returns(T::Boolean) }
          def active?; end

          sig { void }
          def archived!; end

          sig { returns(T::Boolean) }
          def archived?; end

          sig { void }
          def off!; end

          sig { returns(T::Boolean) }
          def off?; end

          sig { void }
          def on!; end

          sig { returns(T::Boolean) }
          def on?; end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates RBI file for classes with multiple enum attributes with mix value types") do
      content = <<~RUBY
        class Conversation < ActiveRecord::Base
          enum status: { active: 0, archived: true, inactive: "Inactive" }
          enum comments_status: { on: 0, off: false, ongoing: "Ongoing", topic: [1,2,3] }
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Conversation
          include Conversation::EnumMethodsModule

          sig { returns(T::Hash[T.any(String, Symbol), T.any(Integer, FalseClass, String, Array)]) }
          def self.comments_statuses; end

          sig { returns(T::Hash[T.any(String, Symbol), T.any(Integer, TrueClass, String)]) }
          def self.statuses; end
        end

        module Conversation::EnumMethodsModule
          sig { void }
          def active!; end

          sig { returns(T::Boolean) }
          def active?; end

          sig { void }
          def archived!; end

          sig { returns(T::Boolean) }
          def archived?; end

          sig { void }
          def inactive!; end

          sig { returns(T::Boolean) }
          def inactive?; end

          sig { void }
          def off!; end

          sig { returns(T::Boolean) }
          def off?; end

          sig { void }
          def on!; end

          sig { returns(T::Boolean) }
          def on?; end

          sig { void }
          def ongoing!; end

          sig { returns(T::Boolean) }
          def ongoing?; end

          sig { void }
          def topic!; end

          sig { returns(T::Boolean) }
          def topic?; end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates RBI file for classes with enum attribute with suffix specified") do
      content = <<~RUBY
        class Conversation < ActiveRecord::Base
          enum status: [:active, :archived], _suffix: true
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Conversation
          include Conversation::EnumMethodsModule

          sig { returns(T::Hash[T.any(String, Symbol), Integer]) }
          def self.statuses; end
        end

        module Conversation::EnumMethodsModule
          sig { void }
          def active_status!; end

          sig { returns(T::Boolean) }
          def active_status?; end

          sig { void }
          def archived_status!; end

          sig { returns(T::Boolean) }
          def archived_status?; end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end

    it("generates RBI file for classes with enum attribute with prefix specified") do
      content = <<~RUBY
        class Conversation < ActiveRecord::Base
          enum status: [:active, :archived], _prefix: :comments
        end

      RUBY

      expected = <<~RUBY
        # typed: strong
        class Conversation
          include Conversation::EnumMethodsModule

          sig { returns(T::Hash[T.any(String, Symbol), Integer]) }
          def self.statuses; end
        end

        module Conversation::EnumMethodsModule
          sig { void }
          def comments_active!; end

          sig { returns(T::Boolean) }
          def comments_active?; end

          sig { void }
          def comments_archived!; end

          sig { returns(T::Boolean) }
          def comments_archived?; end
        end
      RUBY

      assert_equal(expected, rbi_for(content))
    end
  end
end
