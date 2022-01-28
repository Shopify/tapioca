# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveModelSecurePasswordSpec < DslSpec
  describe "Tapioca::Compilers::Dsl::ActiveModelSecurePasswordSpec" do
    describe "initialize" do
      it "gathers no constants if there are no classes using ActiveModel::SecurePassword" do
        assert_empty(gathered_constants)
      end

      it "gathers only classes including ActiveModel::SecurePassword" do
        add_ruby_file("user.rb", <<~RUBY)
          class User
          end

          class UserWithSecurePasswordModule
            include ActiveModel::SecurePassword
          end

          class UserWithSecurePassword
            include ActiveModel::SecurePassword

            has_secure_password
          end
        RUBY

        assert_equal(["UserWithSecurePassword", "UserWithSecurePasswordModule"], gathered_constants)
      end
    end

    describe "decorate" do
      it "generates empty RBI file if there are no calls to has_secure_password" do
        add_ruby_file("user.rb", <<~RUBY)
          class User
            include ActiveModel::SecurePassword
          end
        RUBY

        expected = <<~RBI
          # typed: strong
        RBI

        assert_equal(expected, rbi_for(:User))
      end

      it "generates default secure password methods" do
        add_ruby_file("user.rb", <<~RUBY)
          class User
            include ActiveModel::SecurePassword

            has_secure_password
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class User
            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def authenticate(unencrypted_password); end

            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def authenticate_password(unencrypted_password); end

            sig { returns(T.untyped) }
            def password; end

            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def password=(unencrypted_password); end

            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def password_confirmation=(unencrypted_password); end
          end
        RBI

        assert_equal(expected, rbi_for(:User))
      end

      it "generates custom secure password methods" do
        add_ruby_file("user.rb", <<~RUBY)
          class User
            include ActiveModel::SecurePassword

            has_secure_password :token
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class User
            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def authenticate_token(unencrypted_password); end

            sig { returns(T.untyped) }
            def token; end

            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def token=(unencrypted_password); end

            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def token_confirmation=(unencrypted_password); end
          end
        RBI

        assert_equal(expected, rbi_for(:User))
      end

      it "generates multiple secure password methods" do
        add_ruby_file("user.rb", <<~RUBY)
          class User
            include ActiveModel::SecurePassword

            has_secure_password :token
            has_secure_password
          end
        RUBY

        expected = <<~RBI
          # typed: strong

          class User
            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def authenticate(unencrypted_password); end

            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def authenticate_password(unencrypted_password); end

            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def authenticate_token(unencrypted_password); end

            sig { returns(T.untyped) }
            def password; end

            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def password=(unencrypted_password); end

            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def password_confirmation=(unencrypted_password); end

            sig { returns(T.untyped) }
            def token; end

            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def token=(unencrypted_password); end

            sig { params(unencrypted_password: T.untyped).returns(T.untyped) }
            def token_confirmation=(unencrypted_password); end
          end
        RBI

        assert_equal(expected, rbi_for(:User))
      end
    end
  end
end
