# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActionMailerSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActionMailer" do
          sig { void }
          def before_setup
            require "action_mailer"
          end

          describe "initialize" do
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
                    sig { params(customer_id: ::Integer).returns(::ActionMailer::MessageDelivery) }
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

                  def notify_admin(...); end
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
                <% else %>
                    sig { params(_arg0: T.untyped, _arg1: T.untyped).returns(::ActionMailer::MessageDelivery) }
                    def notify_admin(*_arg0, &_arg1); end

                    sig { params(_arg0: T.untyped, _arg1: T.untyped).returns(::ActionMailer::MessageDelivery) }
                    def notify_customer(*_arg0, &_arg1); end
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

            it "generates correct RBI file for subclasses of ActionMailer subclasses" do
              add_ruby_file("mailer.rb", <<~RUBY)
                class NotifierMailer < ActionMailer::Base
                  def notify_customer(customer_id)
                    # ...
                  end
                end

                class SecondaryMailer < NotifierMailer
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class SecondaryMailer
                  class << self
                    sig { params(customer_id: T.untyped).returns(::ActionMailer::MessageDelivery) }
                    def notify_customer(customer_id); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:SecondaryMailer))
            end

            it "does not generate RBI for methods defined via helper" do
              add_ruby_file("mailer.rb", <<~RUBY)
                module Foo
                  def foo_helper_method
                  end
                end

                module Bar
                  def bar_helper_method
                  end
                end

                class NotifierMailer < ActionMailer::Base
                  include Foo
                  helper Bar

                  def notify_customer(customer_id)
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class NotifierMailer
                  class << self
                    sig { returns(::ActionMailer::MessageDelivery) }
                    def foo_helper_method; end

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
    end
  end
end
