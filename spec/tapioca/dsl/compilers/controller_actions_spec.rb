# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ControllerActionsSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActionController" do
          describe "initialize" do
            it "gathers no constants if there are no ActionController::Base subclasses" do
              assert_empty(gathered_constants)
            end

            it "gathers only ActionController::Base subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class UsersController < ActionController::Base
                end

                class User
                end
              RUBY

              assert_equal(["UsersController"], gathered_constants)
            end

            it "gathers subclasses of ActionController::Base subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class UserController < ActionController::Base
                end

                class LoginController < UserController
                end
              RUBY

              assert_equal(["LoginController", "UserController"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates an empty RBI file if there is no actions" do
              add_ruby_file("job.rb", <<~RUBY)
                class UserController < ActionController::Base
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:UserController))
            end

            it "generates correct RBI file for subclass with private methods" do
              add_ruby_file("job.rb", <<~RUBY)
                class UserController < ActionController::Base
                  def index
                  end
                  def show
                  end

                  private
                  def private_index
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class UserController
                  sig { void }
                  def index; end

                  sig { void }
                  def show; end
                end
              RBI

              assert_equal(expected, rbi_for(:UserController))
            end

            it "generates correct RBI file for subclass with protected methods" do
              add_ruby_file("job.rb", <<~RUBY)
                class UserController < ActionController::Base
                  def index
                  end
                  def show
                  end

                  protected
                  def protected_index
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class UserController
                  sig { void }
                  def index; end

                  sig { void }
                  def show; end
                end
              RBI

              assert_equal(expected, rbi_for(:UserController))
            end

            it "generates correct RBI file for subclass with method signatures" do
              add_ruby_file("job.rb", <<~RUBY)
                class UserController < ActionController::Base
                  extend T::Sig
                  sig { void }
                  def index
                    # ...
                  end

                  def show
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class UserController
                  sig { void }
                  def show; end
                end
              RBI

              assert_equal(expected, rbi_for(:UserController))
            end
          end
        end
      end
    end
  end
end
