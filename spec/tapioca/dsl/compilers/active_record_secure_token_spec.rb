# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordSecureTokenSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveRecordSecureTokenSpec" do
          sig { void }
          def before_setup
            require "tapioca/dsl/extensions/active_record"
            require "active_record"
          end

          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord subclasses" do
              assert_empty(gathered_constants)
            end

            it "gathers only ActiveRecord subclasses" do
              add_ruby_file("user.rb", <<~RUBY)
                class User
                end

                class UserRecord < ActiveRecord::Base
                end
              RUBY

              assert_equal(["UserRecord"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates empty RBI file if there are no calls to has_secure_token" do
              add_ruby_file("user.rb", <<~RUBY)
                class User < ActiveRecord::Base
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:User))
            end

            it "generates default secure password methods" do
              add_ruby_file("user.rb", <<~RUBY)
                class User < ActiveRecord::Base
                  has_secure_token
                end
              RUBY

              expected = template(<<~RBI)
                # typed: strong

                class User
                  include GeneratedSecureTokenMethods

                  module GeneratedSecureTokenMethods
                    sig { returns(T::Boolean) }
                    def regenerate_token; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:User))
            end

            it "generates custom secure password methods" do
              add_ruby_file("user.rb", <<~RUBY)
                class User < ActiveRecord::Base

                  has_secure_token :auth_token
                end
              RUBY

              expected = template(<<~RBI)
                # typed: strong

                class User
                  include GeneratedSecureTokenMethods

                  module GeneratedSecureTokenMethods
                    sig { returns(T::Boolean) }
                    def regenerate_auth_token; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:User))
            end

            it "generates multiple secure token methods" do
              add_ruby_file("user.rb", <<~RUBY)
                class User < ActiveRecord::Base

                  has_secure_token :auth_token
                  has_secure_token
                end
              RUBY

              expected = template(<<~RBI)
                # typed: strong

                class User
                  include GeneratedSecureTokenMethods

                  module GeneratedSecureTokenMethods
                    sig { returns(T::Boolean) }
                    def regenerate_auth_token; end

                    sig { returns(T::Boolean) }
                    def regenerate_token; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:User))
            end
          end
        end
      end
    end
  end
end
