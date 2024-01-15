# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordStoreSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveRecordStoreSpec" do
          sig { void }
          def before_setup
            require "active_record"
            require "tapioca/dsl/extensions/active_record"
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
            it "generates empty RBI file if there are no stored attributes" do
              add_ruby_file("user.rb", <<~RUBY)
                class User < ActiveRecord::Base
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:User))
            end

            it "generates methods for stored attribute declared with store" do
              add_ruby_file("user.rb", <<~RUBY)
                class User < ActiveRecord::Base
                  store :settings, accessors: :theme
                end
              RUBY

              expected = template(<<~RBI)
                # typed: strong

                class User
                  include GeneratedStoredAttributesMethods

                  module GeneratedStoredAttributesMethods
                    sig { returns(T.untyped) }
                    def saved_change_to_theme; end

                    sig { returns(T::Boolean) }
                    def saved_change_to_theme?; end

                    sig { returns(T.untyped) }
                    def theme; end

                    sig { params(value: T.untyped).returns(T.untyped) }
                    def theme=(value); end

                    sig { returns(T.untyped) }
                    def theme_before_last_save; end

                    sig { returns(T.untyped) }
                    def theme_change; end

                    sig { returns(T::Boolean) }
                    def theme_changed?; end

                    sig { returns(T.untyped) }
                    def theme_was; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:User))
            end

            it "generates methods for stored attribute declared with store_accessor" do
              add_ruby_file("user.rb", <<~RUBY)
                class User < ActiveRecord::Base
                  store_accessor :settings, :theme
                end
              RUBY

              expected = template(<<~RBI)
                # typed: strong

                class User
                  include GeneratedStoredAttributesMethods

                  module GeneratedStoredAttributesMethods
                    sig { returns(T.untyped) }
                    def saved_change_to_theme; end

                    sig { returns(T::Boolean) }
                    def saved_change_to_theme?; end

                    sig { returns(T.untyped) }
                    def theme; end

                    sig { params(value: T.untyped).returns(T.untyped) }
                    def theme=(value); end

                    sig { returns(T.untyped) }
                    def theme_before_last_save; end

                    sig { returns(T.untyped) }
                    def theme_change; end

                    sig { returns(T::Boolean) }
                    def theme_changed?; end

                    sig { returns(T.untyped) }
                    def theme_was; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:User))
            end

            it "generates methods for multiple stored attributes" do
              add_ruby_file("user.rb", <<~RUBY)
                class User < ActiveRecord::Base
                  store :settings, accessors: [:theme, :language]
                  store_accessor :settings, :power_source, :expiry
                end
              RUBY

              output = rbi_for(:User)

              expected = indented(<<~RBI, 4)
                sig { params(value: T.untyped).returns(T.untyped) }
                def theme=(value); end
              RBI
              assert_includes(output, expected)

              expected = indented(<<~RBI, 4)
                sig { params(value: T.untyped).returns(T.untyped) }
                def language=(value); end
              RBI
              assert_includes(output, expected)

              expected = indented(<<~RBI, 4)
                sig { params(value: T.untyped).returns(T.untyped) }
                def power_source=(value); end
              RBI
              assert_includes(output, expected)

              expected = indented(<<~RBI, 4)
                sig { params(value: T.untyped).returns(T.untyped) }
                def expiry=(value); end
              RBI
              assert_includes(output, expected)
            end

            it "generates methods for stored attributes with prefix" do
              add_ruby_file("user.rb", <<~RUBY)
                class User < ActiveRecord::Base
                  store :settings, accessors: :theme, prefix: true
                  store_accessor :settings, :power_source, prefix: :prefs
                end
              RUBY

              output = rbi_for(:User)

              expected = indented(<<~RBI, 4)
                sig { params(value: T.untyped).returns(T.untyped) }
                def settings_theme=(value); end
              RBI
              assert_includes(output, expected)

              expected = indented(<<~RBI, 4)
                sig { params(value: T.untyped).returns(T.untyped) }
                def prefs_power_source=(value); end
              RBI
              assert_includes(output, expected)
            end

            it "generates methods for stored attributes with suffix" do
              add_ruby_file("user.rb", <<~RUBY)
                class User < ActiveRecord::Base
                  store :settings, accessors: :theme, suffix: true
                  store_accessor :settings, :power_source, suffix: :prefs
                end
              RUBY

              output = rbi_for(:User)

              expected = indented(<<~RBI, 4)
                sig { params(value: T.untyped).returns(T.untyped) }
                def theme_settings=(value); end
              RBI
              assert_includes(output, expected)

              expected = indented(<<~RBI, 4)
                sig { params(value: T.untyped).returns(T.untyped) }
                def power_source_prefs=(value); end
              RBI
              assert_includes(output, expected)
            end
          end
        end
      end
    end
  end
end
