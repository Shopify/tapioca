# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveJobSpec < DslSpec
  describe("#initialize") do
    it("gathers no constants if there are no ActiveJob subclasses") do
      assert_empty(gathered_constants)
    end

    it("gathers only ActiveJob subclasses") do
      add_ruby_file("content.rb", <<~RUBY)
        class NotifyJob < ActiveJob::Base
        end

        class User
        end
      RUBY

      assert_equal(["NotifyJob"], gathered_constants)
      assert_empty(generated_errors)
    end

    it("gathers subclasses of ActiveJob subclasses") do
      add_ruby_file("content.rb", <<~RUBY)
        class NotifyJob < ActiveJob::Base
        end

        class SecondaryNotifyJob < NotifyJob
        end
      RUBY

      assert_equal(["NotifyJob", "SecondaryNotifyJob"], gathered_constants)
      assert_empty(generated_errors)
    end
  end

  describe("#decorate") do
    it("generates an empty RBI file if there is no perform method") do
      add_ruby_file("job.rb", <<~RUBY)
        class NotifyJob < ActiveJob::Base
        end
      RUBY

      expected = <<~RBI
        # typed: strong
      RBI

      assert_equal(expected, rbi_for(:NotifyJob))
      assert_empty(generated_errors)
    end

    it("generates correct RBI file for subclass with methods") do
      add_ruby_file("job.rb", <<~RUBY)
        class NotifyJob < ActiveJob::Base
          def perform(user_id)
            # ...
          end
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class NotifyJob
          sig { params(user_id: T.untyped).returns(T.any(NotifyJob, FalseClass)) }
          def self.perform_later(user_id); end

          sig { params(user_id: T.untyped).returns(T.untyped) }
          def self.perform_now(user_id); end
        end
      RBI

      assert_equal(expected, rbi_for(:NotifyJob))
      assert_empty(generated_errors)
    end

    it("generates correct RBI file for subclass with method signatures") do
      add_ruby_file("job.rb", <<~RUBY)
        class NotifyJob < ActiveJob::Base
          extend T::Sig
          sig { params(user_id: Integer).void }
          def perform(user_id)
            # ...
          end
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class NotifyJob
          sig { params(user_id: Integer).returns(T.any(NotifyJob, FalseClass)) }
          def self.perform_later(user_id); end

          sig { params(user_id: Integer).void }
          def self.perform_now(user_id); end
        end
      RBI

      assert_equal(expected, rbi_for(:NotifyJob))
      assert_empty(generated_errors)
    end
  end
end
