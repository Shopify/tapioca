# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::SidekiqWorkerSpec < DslSpec
  describe "Tapioca::Compilers::Dsl::SidekiqWorker" do
    describe "initialize" do
      after do
        T.unsafe(self).assert_no_generated_errors
      end

      it "gathers no constants if there are no classes with Sidekiq::Worker as ancestor" do
        assert_empty(gathered_constants)
      end

      it "gathers only classes with Sidekiq::Worker as ancestor" do
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

    describe "decorate" do
      after do
        T.unsafe(self).assert_no_generated_errors
      end

      it "generates empty RBI file if there is no perform method" do
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

      it "generates correct RBI file for class with perform method" do
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
            class << self
              sig { params(customer_id: T.untyped).returns(String) }
              def perform_async(customer_id); end

              sig { params(interval: T.any(DateTime, Time), customer_id: T.untyped).returns(String) }
              def perform_at(interval, customer_id); end

              sig { params(interval: Numeric, customer_id: T.untyped).returns(String) }
              def perform_in(interval, customer_id); end
            end
          end
        RBI

        assert_equal(expected, rbi_for(:NotifierWorker))
      end

      it "generates correct RBI file for class with perform method with signature" do
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
            class << self
              sig { params(customer_id: Integer).returns(String) }
              def perform_async(customer_id); end

              sig { params(interval: T.any(DateTime, Time), customer_id: Integer).returns(String) }
              def perform_at(interval, customer_id); end

              sig { params(interval: Numeric, customer_id: Integer).returns(String) }
              def perform_in(interval, customer_id); end
            end
          end
        RBI

        assert_equal(expected, rbi_for(:NotifierWorker))
      end

      it "generates correct RBI file for subclass of a sidekiq worker without perform method" do
        add_ruby_file("mailer.rb", <<~RUBY)
          class NotifierWorker
            include Sidekiq::Worker
            def perform(customer_id)
              # ...
            end
          end

          class SecondaryWorker < NotifierWorker
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class SecondaryWorker
            class << self
              sig { params(customer_id: T.untyped).returns(String) }
              def perform_async(customer_id); end

              sig { params(interval: T.any(DateTime, Time), customer_id: T.untyped).returns(String) }
              def perform_at(interval, customer_id); end

              sig { params(interval: Numeric, customer_id: T.untyped).returns(String) }
              def perform_in(interval, customer_id); end
            end
          end
        RBI

        assert_equal(expected, rbi_for(:SecondaryWorker))
      end

      it "generates correct RBI file for subclass of a sidekiq worker with overridden methods" do
        add_ruby_file("mailer.rb", <<~RUBY)
          class NotifierWorker
            include Sidekiq::Worker
            def perform(customer_id)
              # ...
            end
          end

          class SecondaryWorker < NotifierWorker
            def perform(customer_id, other_id)
            end

            def self.perform_at(interval, other_id)
            end
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class SecondaryWorker
            class << self
              sig { params(customer_id: T.untyped, other_id: T.untyped).returns(String) }
              def perform_async(customer_id, other_id); end

              sig { params(interval: Numeric, customer_id: T.untyped, other_id: T.untyped).returns(String) }
              def perform_in(interval, customer_id, other_id); end
            end
          end
        RBI

        assert_equal(expected, rbi_for(:SecondaryWorker))
      end

      it "generates no method definitions for methods that are already explicitly overridden" do
        add_ruby_file("job_thing.rb", <<~RUBY)
          class JobThing
            include Sidekiq::Worker

            def perform(foo)
            end

            def self.perform_at(baz)
            end

            def JobThing.perform_in(bat)
            end

            class << self
              def perform_async(bar)
              end
            end
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class JobThing; end
        RBI

        assert_equal(expected, rbi_for(:JobThing))
      end
    end
  end
end
