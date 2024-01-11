# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveJobSpec < ::DslSpec
        extend Tapioca::Helpers::Test::Template

        describe "Tapioca::Dsl::Compilers::ActiveJob" do
          describe "initialize" do
            it "gathers no constants if there are no ActiveJob subclasses" do
              assert_empty(gathered_constants)
            end

            it "gathers only ActiveJob subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class NotifyJob < ActiveJob::Base
                end

                class User
                end
              RUBY

              assert_equal(["NotifyJob"], gathered_constants)
            end

            it "gathers subclasses of ActiveJob subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class NotifyJob < ActiveJob::Base
                end

                class SecondaryNotifyJob < NotifyJob
                end
              RUBY

              assert_equal(["NotifyJob", "SecondaryNotifyJob"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates an empty RBI file if there is no perform method" do
              add_ruby_file("job.rb", <<~RUBY)
                class NotifyJob < ActiveJob::Base
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:NotifyJob))
            end

            it "generates correct RBI file for subclass with methods" do
              add_ruby_file("job.rb", <<~RUBY)
                class NotifyJob < ActiveJob::Base
                  def perform(user_id)
                    # ...
                  end
                end
              RUBY

              expected = template(<<~RBI)
                # typed: strong

                class NotifyJob
                  class << self
                <% if rails_version(">= 7.0") %>
                    sig { params(user_id: T.untyped, block: T.nilable(T.proc.params(job: NotifyJob).void)).returns(T.any(NotifyJob, FalseClass)) }
                    def perform_later(user_id, &block); end
                <% else %>
                    sig { params(user_id: T.untyped).returns(T.any(NotifyJob, FalseClass)) }
                    def perform_later(user_id); end
                <% end %>

                    sig { params(user_id: T.untyped).returns(T.untyped) }
                    def perform_now(user_id); end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:NotifyJob))
            end

            it "generates correct RBI file for subclass with method signatures" do
              add_ruby_file("job.rb", <<~RUBY)
                class NotifyJob < ActiveJob::Base
                  extend T::Sig
                  sig { params(user_id: Integer).void }
                  def perform(user_id)
                    # ...
                  end
                end
              RUBY

              expected = template(<<~RBI)
                # typed: strong

                class NotifyJob
                  class << self
                <% if rails_version(">= 7.0") %>
                    sig { params(user_id: ::Integer, block: T.nilable(T.proc.params(job: NotifyJob).void)).returns(T.any(NotifyJob, FalseClass)) }
                    def perform_later(user_id, &block); end
                <% else %>
                    sig { params(user_id: ::Integer).returns(T.any(NotifyJob, FalseClass)) }
                    def perform_later(user_id); end
                <% end %>

                    sig { params(user_id: ::Integer).void }
                    def perform_now(user_id); end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:NotifyJob))
            end

            it "generates correct RBI file for subclass with block argument" do
              add_ruby_file("job.rb", <<~RUBY)
                class NotifyJob < ActiveJob::Base
                  def perform(user_id, &blk)
                    # ...
                  end
                end
              RUBY

              expected = template(<<~RBI)
                # typed: strong

                class NotifyJob
                  class << self
                <% if rails_version(">= 7.0") %>
                    sig { params(user_id: T.untyped, block: T.nilable(T.proc.params(job: NotifyJob).void)).returns(T.any(NotifyJob, FalseClass)) }
                    def perform_later(user_id, &block); end
                <% else %>
                    sig { params(user_id: T.untyped).returns(T.any(NotifyJob, FalseClass)) }
                    def perform_later(user_id); end
                <% end %>

                    sig { params(user_id: T.untyped).returns(T.untyped) }
                    def perform_now(user_id); end
                  end
                end
              RBI
              assert_equal(expected, rbi_for(:NotifyJob))
            end
          end
        end
      end
    end
  end
end
