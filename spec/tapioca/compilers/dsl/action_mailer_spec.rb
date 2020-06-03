# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Tapioca::Compilers::Dsl::ActionMailer) do
  describe("#initialize") do
    it("gathers no constants if there are no ActionMailer subclasses") do
      expect(subject.processable_constants).to(be_empty)
    end

    it("gathers only ActionMailer subclasses") do
      content = <<~RUBY
        class NotifierMailer < ActionMailer::Base
        end

        class User
        end
      RUBY

      with_content(content) do
        expect(subject.processable_constants).to(eq(Set.new([NotifierMailer])))
      end
    end

    it("gathers subclasses of ActionMailer subclasses") do
      content = <<~RUBY
        class NotifierMailer < ActionMailer::Base
        end

        class SecondaryMailer < NotifierMailer
        end
      RUBY

      with_content(content) do
        expect(subject.processable_constants).to(eq(Set.new([NotifierMailer, SecondaryMailer])))
      end
    end

    it("ignores abstract subclasses") do
      content = <<~RUBY
        class NotifierMailer < ActionMailer::Base
        end

        class AbstractMailer < ActionMailer::Base
          abstract!
        end
      RUBY

      with_content(content) do
        expect(subject.processable_constants).to(eq(Set.new([NotifierMailer])))
      end
    end
  end

  describe("#decorate") do
    def rbi_for(content)
      with_content(content) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, NotifierMailer)
        parlour.rbi
      end
    end

    it("generates empty RBI file if there are no methods") do
      content = <<~RUBY
        class NotifierMailer < ActionMailer::Base
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class NotifierMailer
        end
      RUBY

      expect(rbi_for(content)).to(eq(expected))
    end

    it("generates correct RBI file for subclass with methods") do
      content = <<~RUBY
        class NotifierMailer < ActionMailer::Base
          def notify_customer(customer_id)
            # ...
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class NotifierMailer
          sig { params(customer_id: T.untyped).returns(::ActionMailer::MessageDelivery) }
          def self.notify_customer(customer_id); end
        end
      RUBY

      expect(rbi_for(content)).to(eq(expected))
    end

    it("generates correct RBI file for subclass with method signatures") do
      content = <<~RUBY
        class NotifierMailer < ActionMailer::Base
          extend T::Sig
          sig { params(customer_id: Integer).void }
          def notify_customer(customer_id)
            # ...
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class NotifierMailer
          sig { params(customer_id: Integer).returns(::ActionMailer::MessageDelivery) }
          def self.notify_customer(customer_id); end
        end
      RUBY
      expect(rbi_for(content)).to(eq(expected))
    end

    it("does not generate RBI for methods defined in abstract classes") do
      content = <<~RUBY
        class AbstractMailer < ActionMailer::Base
          abstract!

          def helper_method
            # ...
          end
        end

        class NotifierMailer < AbstractMailer
          def notify_customer(customer_id)
            # ...
          end
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class NotifierMailer
          sig { params(customer_id: T.untyped).returns(::ActionMailer::MessageDelivery) }
          def self.notify_customer(customer_id); end
        end
      RUBY

      expect(rbi_for(content)).to(eq(expected))
    end
  end
end
