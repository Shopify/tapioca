# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActionMailerSpec < DslSpec
  describe "Tapioca::Compilers::Dsl::ActionMailer" do
    describe "initialize" do
      after do
        T.unsafe(self).assert_no_generated_errors
      end

      it "gathers no constants if there are no ActionMailer subclasses" do
        assert_empty(gathered_constants)
      end

      it "gathers only ActionMailer subclasses" do
        add_ruby_file("content.rb", <<~RUBY)
          class NotifierMailer < ActionMailer::Base
          end

          class User
          end
        RUBY

        assert_equal(["NotifierMailer"], gathered_constants)
      end

      it "gathers subclasses of ActionMailer subclasses" do
        add_ruby_file("content.rb", <<~RUBY)
          class NotifierMailer < ActionMailer::Base
          end

          class SecondaryMailer < NotifierMailer
          end
        RUBY

        assert_equal(["NotifierMailer", "SecondaryMailer"], gathered_constants)
      end

      it "ignores abstract subclasses" do
        add_ruby_file("content.rb", <<~RUBY)
          class NotifierMailer < ActionMailer::Base
          end

          class AbstractMailer < ActionMailer::Base
            abstract!
          end
        RUBY

        assert_equal(["NotifierMailer"], gathered_constants)
      end
    end

    describe "decorate" do
      after do
        T.unsafe(self).assert_no_generated_errors
      end

      it "generates empty RBI file if there are no methods" do
        add_ruby_file("mailer.rb", <<~RUBY)
          class NotifierMailer < ActionMailer::Base
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class NotifierMailer; end
        RBI

        assert_equal(expected, rbi_for(:NotifierMailer))
      end

      it "generates correct RBI file for subclass with methods" do
        add_ruby_file("mailer.rb", <<~RUBY)
          class NotifierMailer < ActionMailer::Base
            def notify_customer(customer_id)
              # ...
            end
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class NotifierMailer
            class << self
              sig { params(customer_id: T.untyped).returns(::ActionMailer::MessageDelivery) }
              def notify_customer(customer_id); end
            end
          end
        RBI

        assert_equal(expected, rbi_for(:NotifierMailer))
      end

      it "generates correct RBI file for subclass with method signatures" do
        add_ruby_file("mailer.rb", <<~RUBY)
          class NotifierMailer < ActionMailer::Base
            extend T::Sig
            sig { params(customer_id: Integer).void }
            def notify_customer(customer_id)
              # ...
            end
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class NotifierMailer
            class << self
              sig { params(customer_id: Integer).returns(::ActionMailer::MessageDelivery) }
              def notify_customer(customer_id); end
            end
          end
        RBI

        assert_equal(expected, rbi_for(:NotifierMailer))
      end

      it "generates correct RBI file for mailer with delegated methods" do
        add_ruby_file("mailer.rb", template(<<~RUBY))
          class NotifierMailer < ActionMailer::Base
            delegate :notify_customer, to: :foo

          <% if ruby_version(">= 2.7.0") %>
            module_eval("def notify_admin(...); end")
          <% end %>
          end
        RUBY

        expected = template(<<~RBI)
          # typed: strong

          class NotifierMailer
            class << self
          <% if ruby_version(">= 3.1.0") %>
              sig { params(_arg0: T.untyped, _arg1: T.untyped, _arg2: T.untyped).returns(::ActionMailer::MessageDelivery) }
              def notify_admin(*_arg0, **_arg1, &_arg2); end

              sig { params(_arg0: T.untyped, _arg1: T.untyped, _arg2: T.untyped).returns(::ActionMailer::MessageDelivery) }
              def notify_customer(*_arg0, **_arg1, &_arg2); end
          <% elsif ruby_version(">= 2.7.0") %>
              sig { params(_arg0: T.untyped, _arg1: T.untyped).returns(::ActionMailer::MessageDelivery) }
              def notify_admin(*_arg0, &_arg1); end

              sig { params(_arg0: T.untyped, _arg1: T.untyped).returns(::ActionMailer::MessageDelivery) }
              def notify_customer(*_arg0, &_arg1); end
          <% else %>
              sig { params(args: T.untyped, block: T.untyped).returns(::ActionMailer::MessageDelivery) }
              def notify_customer(*args, &block); end
          <% end %>
            end
          end
        RBI

        assert_equal(expected, rbi_for(:NotifierMailer))
      end

      it "does not generate RBI for methods defined in abstract classes" do
        add_ruby_file("mailer.rb", <<~RUBY)
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

        expected = <<~RBI
          # typed: strong

          class NotifierMailer
            class << self
              sig { params(customer_id: T.untyped).returns(::ActionMailer::MessageDelivery) }
              def notify_customer(customer_id); end
            end
          end
        RBI

        assert_equal(expected, rbi_for(:NotifierMailer))
      end
    end
  end
end
