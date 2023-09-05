# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActionControllerHelpersSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActionControllerHelpers" do
          describe "initialize" do
            it "gathers no constants if there are no  classes" do
              assert_empty(gathered_constants)
            end

            it "gathers only ActionController subclasses with helpers" do
              add_ruby_file("content.rb", <<~RUBY)
                class UserController < ActionController::Base
                  helper_method :foo
                end

                class AnotherController < ActionController::Base
                end

                class User
                end
              RUBY

              assert_equal(["UserController"], gathered_constants)
            end

            it "does not gather included modules as their own processable constant" do
              add_ruby_file("content.rb", <<~RUBY)
                module UserHelper
                end

                class UserController < ActionController::Base
                  include UserHelper
                  helper_method :foo
                end
              RUBY

              assert_equal(["UserController"], gathered_constants)
            end

            it "gathers subclasses of ActionController subclasses with helpers" do
              add_ruby_file("content.rb", <<~RUBY)
                class UserController < ActionController::Base
                  helper_method :foo
                end

                class HandController < UserController
                  helper_method :bar
                end
              RUBY

              assert_equal(["HandController", "UserController"], gathered_constants)
            end

            it "gathers abstract subclasses of ActionController" do
              add_ruby_file("content.rb", <<~RUBY)
                class UserController < ActionController::Base
                  helper_method :foo
                end

                class HomeController < ActionController::Base
                  abstract!
                  helper_method :foo
                end
              RUBY

              assert_equal(["HomeController", "UserController"], gathered_constants)
            end

            it "ignores anonymous subclasses of ActionController" do
              add_ruby_file("content.rb", <<~RUBY)
                Class.new(ActionController::Base) do
                  helper_method :foo
                end
              RUBY

              assert_equal([], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates helper module and helper proxy class if helper_method target does not exist" do
              add_ruby_file("controller.rb", <<~RUBY)
                class BaseController < ActionController::Base
                  extend T::Sig

                  helper_method :current_user_name
                  helper_method "notify_user"
                end

                class UserController < BaseController
                  def current_user_name
                    # ...
                  end

                  # Make the following method private to make sure that
                  # we handle private methods properly wrt their existence.
                  private

                  sig { params(user_id: Integer).void }
                  def notify_user(user_id)
                    # ...
                  end
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class BaseController
                  sig { returns(HelperProxy) }
                  def helpers; end

                  module HelperMethods
                    include ::ActionController::Base::HelperMethods

                    sig { params(args: T.untyped, kwargs: T.untyped, blk: T.untyped).returns(T.untyped) }
                    def current_user_name(*args, **kwargs, &blk); end

                    sig { params(args: T.untyped, kwargs: T.untyped, blk: T.untyped).returns(T.untyped) }
                    def notify_user(*args, **kwargs, &blk); end
                  end

                  class HelperProxy < ::ActionView::Base
                    include HelperMethods
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:BaseController))
            end

            it "generates helper module and helper proxy class when defining helper using helper_method" do
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
                  sig { returns(HelperProxy) }
                  def helpers; end

                  module HelperMethods
                    include ::ActionController::Base::HelperMethods

                    sig { returns(T.untyped) }
                    def current_user_name; end

                    sig { params(user_id: ::Integer).void }
                    def notify_user(user_id); end
                  end

                  class HelperProxy < ::ActionView::Base
                    include HelperMethods
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:UserController))
            end

            it "generates helper module and helper proxy class when defining helper using block" do
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
                  sig { returns(HelperProxy) }
                  def helpers; end

                  module HelperMethods
                    include ::ActionController::Base::HelperMethods

                    sig { params(user: T.untyped).returns(T.untyped) }
                    def greet(user); end

                    sig { params(user_id: ::Integer).void }
                    def notify_user(user_id); end
                  end

                  class HelperProxy < ::ActionView::Base
                    include HelperMethods
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:UserController))
            end

            it "generates helper module and helper proxy class for defining external helper" do
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
                  sig { returns(HelperProxy) }
                  def helpers; end

                  module HelperMethods
                    include ::ActionController::Base::HelperMethods
                    include ::GreetHelper
                  end

                  class HelperProxy < ::ActionView::Base
                    include HelperMethods
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:UserController))
            end

            it "does not crash if the helper redefines `name`" do
              add_ruby_file("greet_helper.rb", <<~RUBY)
                module GreetHelper
                  class << self
                    def name(str)
                      str
                    end
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
                  sig { returns(HelperProxy) }
                  def helpers; end

                  module HelperMethods
                    include ::ActionController::Base::HelperMethods
                    include ::GreetHelper
                  end

                  class HelperProxy < ::ActionView::Base
                    include HelperMethods
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:UserController))
            end

            it "works correctly with abstract ApplicationController" do
              add_ruby_file("greet_helper.rb", <<~RUBY)
                module GreetHelper
                  def greet(user)
                    # ...
                  end
                end
              RUBY

              add_ruby_file("application_controller.rb", <<~RUBY)
                # typed: false

                class ApplicationController < ActionController::Base
                  abstract!

                  helper_method :foo
                  def foo; end
                end
              RUBY
              add_ruby_file("user_controller.rb", <<~RUBY)
                class UserController < ApplicationController
                  helper GreetHelper
                end
              RUBY
              add_ruby_file("posts_controller.rb", <<~RUBY)
                class PostsController < ApplicationController
                end
              RUBY
              assert_equal(["ApplicationController", "UserController"], gathered_constants)

              expected = <<~RBI
                # typed: strong

                class ApplicationController
                  sig { returns(HelperProxy) }
                  def helpers; end

                  module HelperMethods
                    include ::ActionController::Base::HelperMethods

                    sig { returns(T.untyped) }
                    def foo; end
                  end

                  class HelperProxy < ::ActionView::Base
                    include HelperMethods
                  end
                end
              RBI
              assert_equal expected, rbi_for(:ApplicationController)

              expected = <<~RBI
                # typed: strong

                class UserController
                  sig { returns(HelperProxy) }
                  def helpers; end

                  module HelperMethods
                    include ::ActionController::Base::HelperMethods
                    include ::ApplicationController::HelperMethods
                    include ::GreetHelper
                  end

                  class HelperProxy < ::ActionView::Base
                    include HelperMethods
                  end
                end
              RBI
              assert_equal expected, rbi_for(:UserController)
            end
          end
        end
      end
    end
  end
end
