# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActionControllerHelpersSpec < DslSpec
  describe("#initialize") do
    it("gathers no constants if there are no  classes") do
      assert_empty(constants_from(""))
    end

    it("gathers only ActionController subclasses") do
      content = <<~RUBY
        class UserController < ActionController::Base
        end

        class User
        end
      RUBY

      assert_equal(["UserController"], constants_from(content))
    end

    it("does not gather included modules as their own processable constant") do
      content = <<~RUBY
        module UserHelper
        end

        class UserController < ActionController::Base
          include UserHelper
        end
      RUBY

      assert_equal(["UserController"], constants_from(content))
    end

    it("gathers subclasses of ActionController subclasses") do
      content = <<~RUBY
        class UserController < ActionController::Base
        end

        class HandController < UserController
        end
      RUBY

      assert_equal(["HandController", "UserController"], constants_from(content))
    end

    it("ignores abstract subclasses of ActionController") do
      content = <<~RUBY
        class UserController < ActionController::Base
        end

        class HomeController < ActionController::Base
          abstract!
        end
      RUBY

      assert_equal(["UserController"], constants_from(content))
    end

    it("ignores anonymous subclasses of ActionController") do
      content = <<~RUBY
        Class.new(ActionController::Base)
      RUBY

      assert_equal([], constants_from(content))
    end
  end

  describe("#decorate") do
    it("generates empty helper module when there are no helper methods specified") do
      files = {
        "controller.rb" => <<~RUBY,
          class UserController < ActionController::Base
            def current_user_name
              # ...
            end
          end
        RUBY
      }

      expected = <<~RUBY
        # typed: strong
        class UserController
          sig { returns(UserController::HelperProxy) }
          def helpers; end
        end

        module UserController::HelperMethods
        end

        class UserController::HelperProxy < ::ActionView::Base
          include UserController::HelperMethods
        end
      RUBY

      assert_equal(expected, rbi_for(:UserController, files))
    end

    it("generates helper module and helper proxy class when defining helper using helper_method") do
      files = {
        "controller.rb" => <<~RUBY,
          class UserController < ActionController::Base
            extend T::Sig

            helper_method :current_user_name
            helper_method "notify_user"

            def current_user_name
              # ...
            end

            sig { params(user_id: Integer).void }
            def notify_user(user_id)
              # ...
            end
          end
        RUBY
      }

      expected = <<~RUBY
        # typed: strong
        class UserController
          sig { returns(UserController::HelperProxy) }
          def helpers; end
        end

        module UserController::HelperMethods
          sig { returns(T.untyped) }
          def current_user_name; end

          sig { params(user_id: Integer).void }
          def notify_user(user_id); end
        end

        class UserController::HelperProxy < ::ActionView::Base
          include UserController::HelperMethods
        end
      RUBY

      assert_equal(expected, rbi_for(:UserController, files))
    end

    it("generates helper module and helper proxy class when defining helper using block") do
      files = {
        "controller.rb" => <<~RUBY,
          class UserController < ActionController::Base
            helper { def greet(user) "Hello" end }
            helper do
              extend T::Sig

              sig { params(user_id: Integer).void }
              def notify_user(user_id)
                # ...
              end
            end

            def current_user_name
              # ...
            end
          end
        RUBY
      }

      expected = <<~RUBY
        # typed: strong
        class UserController
          sig { returns(UserController::HelperProxy) }
          def helpers; end
        end

        module UserController::HelperMethods
          sig { params(user: T.untyped).returns(T.untyped) }
          def greet(user); end

          sig { params(user_id: Integer).void }
          def notify_user(user_id); end
        end

        class UserController::HelperProxy < ::ActionView::Base
          include UserController::HelperMethods
        end
      RUBY

      assert_equal(expected, rbi_for(:UserController, files))
    end

    it("generates helper module and helper proxy class for defining external helper") do
      files = {
        "greet_helper.rb" => <<~RUBY,
          module GreetHelper
            def greet(user)
              # ...
            end
          end
        RUBY

        "controller.rb" => <<~RUBY,
          class UserController < ActionController::Base
            helper GreetHelper

            def current_user_name
              # ...
            end
          end
        RUBY
      }

      expected = <<~RUBY
        # typed: strong
        class UserController
          sig { returns(UserController::HelperProxy) }
          def helpers; end
        end

        module UserController::HelperMethods
          include GreetHelper
        end

        class UserController::HelperProxy < ::ActionView::Base
          include UserController::HelperMethods
        end
      RUBY

      assert_equal(expected, rbi_for(:UserController, files))
    end
  end
end
