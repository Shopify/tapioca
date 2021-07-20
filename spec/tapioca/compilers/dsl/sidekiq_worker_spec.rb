# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::SidekiqWorkerSpec < DslSpec
  describe("#initialize") do
    it("gathers no constants if there are no classes with Sidekiq::Worker as ancestor") do
      assert_empty(gathered_constants)
    end

    it("gathers only classes with Sidekiq::Worker as ancestor") do
      add_ruby_file("content.rb", <<~RUBY)
        class NotifierWorker
          include Sidekiq::Worker
        end

        class SecondaryWorker < NotifierWorker
        end

        class User
        end
      RUBY

      assert_equal(["NotifierWorker", "SecondaryWorker"], gathered_constants)
    end
  end

  describe("#decorate") do
    it("generates empty RBI file if there are no perform") do
      add_ruby_file("mailer.rb", <<~RUBY)
        class NotifierWorker
          include Sidekiq::Worker
        end
      RUBY

      expected = <<~RBI
        # typed: strong
      RBI

      assert_equal(expected, rbi_for(:NotifierWorker))
    end

    it("generates correct RBI file for subclass with methods") do
      add_ruby_file("mailer.rb", <<~RUBY)
        class NotifierWorker
          include Sidekiq::Worker
          def perform(customer_id)
            # ...
          end
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class NotifierWorker
          sig { params(customer_id: T.untyped).returns(String) }
          def self.perform_async(customer_id); end

          sig { params(interval: T.any(DateTime, Time), customer_id: T.untyped).returns(String) }
          def self.perform_at(interval, customer_id); end

          sig { params(interval: Numeric, customer_id: T.untyped).returns(String) }
          def self.perform_in(interval, customer_id); end
        end
      RBI

      assert_equal(expected, rbi_for(:NotifierWorker))
    end

    it("generates correct RBI file for subclass with method signatures") do
      add_ruby_file("mailer.rb", <<~RUBY)
        class NotifierWorker
          include Sidekiq::Worker
          extend T::Sig
          sig { params(customer_id: Integer).void }
          def perform(customer_id)
            # ...
          end
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class NotifierWorker
          sig { params(customer_id: Integer).returns(String) }
          def self.perform_async(customer_id); end

          sig { params(interval: T.any(DateTime, Time), customer_id: Integer).returns(String) }
          def self.perform_at(interval, customer_id); end

          sig { params(interval: Numeric, customer_id: Integer).returns(String) }
          def self.perform_in(interval, customer_id); end
        end
      RBI

      assert_equal(expected, rbi_for(:NotifierWorker))
    end
  end
end
