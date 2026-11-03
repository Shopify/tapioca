# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActionMailerHelpersSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActionMailerHelpers" do
          #: -> void
          def before_setup
            require "action_mailer"
          end

          describe "initialize" do
            it "gathers no constants if there are no classes" do
              assert_empty(gathered_constants)
            end

            it "gathers only ActionMailer subclasses with helpers" do
              add_ruby_file("content.rb", <<~RUBY)
                class NotifierMailer < ActionMailer::Base
                  helper_method :foo
                end

                class AnotherMailer < ActionMailer::Base
                end

                class User
                end
              RUBY

              assert_equal(["NotifierMailer"], gathered_constants)
            end

            it "gathers subclasses of ActionMailer subclasses with helpers" do
              add_ruby_file("content.rb", <<~RUBY)
                class ApplicationMailer < ActionMailer::Base
                  helper_method :foo
                end

                class NotifierMailer < ApplicationMailer
                  helper_method :bar
                end

                class AnotherMailer < ApplicationMailer
                end
              RUBY

              assert_equal(["ApplicationMailer", "NotifierMailer"], gathered_constants)
            end

            it "ignores anonymous subclasses of ActionMailer" do
              add_ruby_file("content.rb", <<~RUBY)
                Class.new(ActionMailer::Base) do
                  helper_method :foo
                end
              RUBY

              assert_equal([], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates helper module with included helpers, helper methods and helper blocks" do
              add_ruby_file("format_helper.rb", <<~RUBY)
                module FormatHelper
                  def format_amount(cents)
                    # ...
                  end
                end
              RUBY

              add_ruby_file("mailer.rb", <<~RUBY)
                class NotifierMailer < ActionMailer::Base
                  extend T::Sig

                  helper FormatHelper
                  helper { def signature; end }
                  helper_method :unsubscribe_url, :missing_target

                  sig { params(email: String).returns(String) }
                  def unsubscribe_url(email)
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class NotifierMailer
                  module HelperMethods
                    include ::ActionMailer::MailHelper
                    include ::ActionMailer::Base::HelperMethods
                    include ::FormatHelper

                    sig { params(args: T.untyped, kwargs: T.untyped, blk: T.untyped).returns(T.untyped) }
                    def missing_target(*args, **kwargs, &blk); end

                    sig { returns(T.untyped) }
                    def signature; end

                    sig { params(email: ::String).returns(::String) }
                    def unsubscribe_url(email); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:NotifierMailer))
            end

            it "includes the parent mailer's helper module and only the helper modules a mailer adds" do
              add_ruby_file("helpers.rb", <<~RUBY)
                module FormatHelper
                  def format_amount(cents)
                    # ...
                  end
                end

                module BillingHelper
                  def invoice_total(invoice)
                    # ...
                  end
                end
              RUBY

              add_ruby_file("mailers.rb", <<~RUBY)
                class ApplicationMailer < ActionMailer::Base
                  helper FormatHelper
                end

                class AccountMailer < ApplicationMailer
                end

                class BillingMailer < AccountMailer
                  helper FormatHelper, BillingHelper
                end
              RUBY

              assert_equal(["ApplicationMailer", "BillingMailer"], gathered_constants)

              expected = <<~RBI
                # typed: strong

                class ApplicationMailer
                  module HelperMethods
                    include ::ActionMailer::MailHelper
                    include ::ActionMailer::Base::HelperMethods
                    include ::FormatHelper
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:ApplicationMailer))

              expected = <<~RBI
                # typed: strong

                class BillingMailer
                  module HelperMethods
                    include ::ApplicationMailer::HelperMethods
                    include ::BillingHelper
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:BillingMailer))
            end

            it "includes the parent mailer's helper module when only the mailer is requested" do
              add_ruby_file("mailers.rb", <<~RUBY)
                module FormatHelper
                  def format_amount(cents)
                    # ...
                  end
                end

                class ApplicationMailer < ActionMailer::Base
                  helper FormatHelper
                end

                class NotifierMailer < ApplicationMailer
                  helper_method :foo
                  def foo; end
                end
              RUBY

              Tapioca::Dsl::Compiler.requested_constants = [Object.const_get(:NotifierMailer)]
              assert_equal(["NotifierMailer"], gathered_constants)

              expected = <<~RBI
                # typed: strong

                class NotifierMailer
                  module HelperMethods
                    include ::ApplicationMailer::HelperMethods

                    sig { returns(T.untyped) }
                    def foo; end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:NotifierMailer))
            ensure
              Tapioca::Dsl::Compiler.requested_constants = []
            end
          end
        end
      end
    end
  end
end
