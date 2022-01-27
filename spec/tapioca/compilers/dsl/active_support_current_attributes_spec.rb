# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveSupportCurrentAttributesSpec < DslSpec
  describe("#initialize") do
    after do
      T.unsafe(self).assert_no_generated_errors
    end

    it "gathers no constants if there are no ActiveSupport::CurrentAttributes subclasses" do
      assert_empty(gathered_constants)
    end

    it "gathers only ActiveSupport::CurrentAttributes subclasses" do
      add_ruby_file("content.rb", <<~RUBY)
        class User
        end

        class Current < ActiveSupport::CurrentAttributes
        end
      RUBY

      assert_equal(["Current"], gathered_constants)
    end
  end

  describe("#decorate") do
    after do
      T.unsafe(self).assert_no_generated_errors
    end

    it "generates empty RBI file if there are no current attributes" do
      add_ruby_file("current.rb", <<~RUBY)
        class Current < ActiveSupport::CurrentAttributes
        end
      RUBY

      expected = <<~RBI
        # typed: strong
      RBI

      assert_equal(expected, rbi_for(:Current))
    end

    it "generates method sigs for every current attribute" do
      add_ruby_file("current.rb", <<~RUBY)
        class Current < ActiveSupport::CurrentAttributes
          attribute :account, :user
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Current
          sig { returns(T.untyped) }
          def account; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def account=(value); end

          sig { returns(T.untyped) }
          def user; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def user=(value); end

          class << self
            sig { returns(T.untyped) }
            def account; end

            sig { params(value: T.untyped).returns(T.untyped) }
            def account=(value); end

            sig { returns(T.untyped) }
            def user; end

            sig { params(value: T.untyped).returns(T.untyped) }
            def user=(value); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Current))
    end

    it "only generates a class method definition for non current attribute methods" do
      add_ruby_file("current.rb", <<~RUBY)
        class Current < ActiveSupport::CurrentAttributes
          extend T::Sig

          attribute :account

          def helper
            # ...
          end

          sig { params(user_id: Integer).void }
          def authenticate(user_id)
            # ...
          end
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Current
          sig { returns(T.untyped) }
          def account; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def account=(value); end

          class << self
            sig { returns(T.untyped) }
            def account; end

            sig { params(value: T.untyped).returns(T.untyped) }
            def account=(value); end

            sig { params(user_id: Integer).void }
            def authenticate(user_id); end

            sig { returns(T.untyped) }
            def helper; end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Current))
    end
  end
end
