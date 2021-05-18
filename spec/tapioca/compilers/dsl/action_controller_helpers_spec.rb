# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActionControllerHelpersSpec < DslSpec
  describe("#initialize") do
    it("gathers no constants if there are no  classes") do
      assert_empty(gathered_constants)
    end

    it("gathers only ActionController subclasses") do
      add_ruby_file("content.rb", <<~RUBY)
        class UserController < ActionController::Base
        end

        class User
        end
      RUBY

      assert_equal(["UserController"], gathered_constants)
    end

    it("does not gather included modules as their own processable constant") do
      add_ruby_file("content.rb", <<~RUBY)
        module UserHelper
        end

        class UserController < ActionController::Base
          include UserHelper
        end
      RUBY

      assert_equal(["UserController"], gathered_constants)
    end

    it("gathers subclasses of ActionController subclasses") do
      add_ruby_file("content.rb", <<~RUBY)
        class UserController < ActionController::Base
        end

        class HandController < UserController
        end
      RUBY

      assert_equal(["HandController", "UserController"], gathered_constants)
    end

    it("ignores abstract subclasses of ActionController") do
      add_ruby_file("content.rb", <<~RUBY)
        class UserController < ActionController::Base
        end

        class HomeController < ActionController::Base
          abstract!
        end
      RUBY

      assert_equal(["UserController"], gathered_constants)
    end

    it("ignores anonymous subclasses of ActionController") do
      add_ruby_file("content.rb", <<~RUBY)
        Class.new(ActionController::Base)
      RUBY

      assert_equal([], gathered_constants)
    end
  end

  describe("#decorate") do
    it("generates empty helper module when there are no helper methods specified") do
      add_ruby_file("controller.rb", <<~RUBY)
        class UserController < ActionController::Base
          def current_user_name
            # ...
          end
        end
      RUBY

      expected = <<~RBI
        # typed: strong
        class UserController
          module HelperMethods
            include ::ActionController::Base::HelperMethods
          end

          class HelperProxy < ::ActionView::Base
            include HelperMethods
          end

          sig { returns(HelperProxy) }
          def helpers; end
        end
      RBI

      assert_equal(expected, rbi_for(:UserController))
    end

    it("generates helper module and helper proxy class when defining helper using helper_method") do
      add_ruby_file("controller.rb", <<~RUBY)
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

      expected = <<~RBI
        # typed: strong
        class UserController
          module HelperMethods
            include ::ActionController::Base::HelperMethods

            sig { returns(T.untyped) }
            def current_user_name; end

            sig { params(user_id: Integer).void }
            def notify_user(user_id); end
          end

          class HelperProxy < ::ActionView::Base
            include HelperMethods
          end

          sig { returns(HelperProxy) }
          def helpers; end
        end
      RBI

      assert_equal(expected, rbi_for(:UserController))
    end

    it("generates helper module and helper proxy class when defining helper using block") do
      add_ruby_file("controller.rb", <<~RUBY)
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

      expected = <<~RBI
        # typed: strong
        class UserController
          module HelperMethods
            include ::ActionController::Base::HelperMethods

            sig { params(user: T.untyped).returns(T.untyped) }
            def greet(user); end

            sig { params(user_id: Integer).void }
            def notify_user(user_id); end
          end

          class HelperProxy < ::ActionView::Base
            include HelperMethods
          end

          sig { returns(HelperProxy) }
          def helpers; end
        end
      RBI

      assert_equal(expected, rbi_for(:UserController))
    end

    it("generates helper module and helper proxy class for defining external helper") do
      add_ruby_file("greet_helper.rb", <<~RUBY)
        module GreetHelper
          def greet(user)
            # ...
          end
        end
      RUBY

      add_ruby_file("controller.rb", <<~RUBY)
        class UserController < ActionController::Base
          helper GreetHelper

          def current_user_name
            # ...
          end
        end
      RUBY

      expected = <<~RBI
        # typed: strong
        class UserController
          module HelperMethods
            include ::ActionController::Base::HelperMethods
            include ::GreetHelper
          end

          class HelperProxy < ::ActionView::Base
            include HelperMethods
          end

          sig { returns(HelperProxy) }
          def helpers; end
        end
      RBI

      assert_equal(expected, rbi_for(:UserController))
    end
  end
end
