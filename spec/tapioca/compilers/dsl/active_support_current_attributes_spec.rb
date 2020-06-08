# typed: false
# frozen_string_literal: true

require "spec_helper"
require "tapioca/compilers/dsl/active_support_current_attributes"

RSpec.describe(Tapioca::Compilers::Dsl::ActiveSupportCurrentAttributes) do
  describe("#initialize") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    it("gathers no constants if there are no ActiveSupport::CurrentAttributes subclasses") do
      expect(subject.processable_constants).to(be_empty)
    end

    it("gathers only ActiveSupport::CurrentAttributes subclasses") do
      content = <<~RUBY
        class User
        end

        class Current < ActiveSupport::CurrentAttributes
        end
      RUBY

      expect(constants_from(content)).to(eq(["Current"]))
    end
  end

  describe("#decorate") do
    def rbi_for(content)
      with_content(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Current)
        parlour.rbi
      end
    end

    it("generates empty RBI file if there are no current attributes") do
      content = <<~RUBY
        class Current < ActiveSupport::CurrentAttributes
        end
      RUBY

      expected = <<~RUBY
        # typed: strong

      RUBY

      expect(rbi_for(content)).to(eq(expected))
    end

    it("generates method sigs for every current attribute") do
      content = <<~RUBY
        class Current < ActiveSupport::CurrentAttributes
          attribute :account, :user

        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class Current
          sig { returns(T.untyped) }
          def self.account; end

          sig { returns(T.untyped) }
          def account; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def self.account=(value); end

          sig { params(value: T.untyped).returns(T.untyped) }
          def account=(value); end

          sig { returns(T.untyped) }
          def self.user; end

          sig { returns(T.untyped) }
          def user; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def self.user=(value); end

          sig { params(value: T.untyped).returns(T.untyped) }
          def user=(value); end
        end
      RUBY

      expect(rbi_for(content)).to(eq(expected))
    end

    it("only generates a class method definition for non current attribute methods") do
      content = <<~RUBY
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

      expected = <<~RUBY
        # typed: strong
        class Current
          sig { returns(T.untyped) }
          def self.account; end

          sig { returns(T.untyped) }
          def account; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def self.account=(value); end

          sig { params(value: T.untyped).returns(T.untyped) }
          def account=(value); end

          sig { params(user_id: Integer).void }
          def self.authenticate(user_id); end

          sig { returns(T.untyped) }
          def self.helper; end
        end
      RUBY

      expect(rbi_for(content)).to(eq(expected))
    end
  end
end
