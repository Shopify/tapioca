# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordEnumSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveRecordEnum" do
          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord classes" do
              assert_empty(gathered_constants)
            end

            it "gathers only ActiveRecord constants including abstract classes" do
              add_ruby_file("content.rb", <<~RUBY)
                class Conversation < ActiveRecord::Base
                end

                class Product < ActiveRecord::Base
                  self.abstract_class = true
                end

                class User
                end
              RUBY

              assert_equal(["Conversation", "Product"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates RBI file for classes with an enum attribute" do
              add_ruby_file("conversation.rb", <<~RUBY)
                class Conversation < ActiveRecord::Base
                  enum status: [ :active, :archived ]
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Conversation
                  include EnumMethodsModule

                  class << self
                    sig { returns(T::Hash[T.any(::String, ::Symbol), ::Integer]) }
                    def statuses; end
                  end

                  module EnumMethodsModule
                    sig { void }
                    def active!; end

                    sig { returns(T::Boolean) }
                    def active?; end

                    sig { void }
                    def archived!; end

                    sig { returns(T::Boolean) }
                    def archived?; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Conversation))
            end

            it "generates RBI file for classes with an enum attribute with string values" do
              add_ruby_file("conversation.rb", <<~RUBY)
                class Conversation < ActiveRecord::Base
                  enum status: { active: "0", archived: "1" }
                end

              RUBY

              expected = <<~RBI
                # typed: strong

                class Conversation
                  include EnumMethodsModule

                  class << self
                    sig { returns(T::Hash[T.any(::String, ::Symbol), ::String]) }
                    def statuses; end
                  end

                  module EnumMethodsModule
                    sig { void }
                    def active!; end

                    sig { returns(T::Boolean) }
                    def active?; end

                    sig { void }
                    def archived!; end

                    sig { returns(T::Boolean) }
                    def archived?; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Conversation))
            end

            it "generates RBI file for classes with an enum attribute with mix value types" do
              add_ruby_file("conversation.rb", <<~RUBY)
                class Conversation < ActiveRecord::Base
                  enum status: { active: 0, archived: true, inactive: "Inactive" }
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Conversation
                  include EnumMethodsModule

                  class << self
                    sig { returns(T::Hash[T.any(::String, ::Symbol), T.any(::Integer, ::TrueClass, ::String)]) }
                    def statuses; end
                  end

                  module EnumMethodsModule
                    sig { void }
                    def active!; end

                    sig { returns(T::Boolean) }
                    def active?; end

                    sig { void }
                    def archived!; end

                    sig { returns(T::Boolean) }
                    def archived?; end

                    sig { void }
                    def inactive!; end

                    sig { returns(T::Boolean) }
                    def inactive?; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Conversation))
            end

            it "generates RBI file for classes with multiple enum attributes" do
              add_ruby_file("conversation.rb", <<~RUBY)
                class Conversation < ActiveRecord::Base
                  enum status: [ :active, :archived ]
                  enum comments_status: [:on, :off]
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Conversation
                  include EnumMethodsModule

                  class << self
                    sig { returns(T::Hash[T.any(::String, ::Symbol), ::Integer]) }
                    def comments_statuses; end

                    sig { returns(T::Hash[T.any(::String, ::Symbol), ::Integer]) }
                    def statuses; end
                  end

                  module EnumMethodsModule
                    sig { void }
                    def active!; end

                    sig { returns(T::Boolean) }
                    def active?; end

                    sig { void }
                    def archived!; end

                    sig { returns(T::Boolean) }
                    def archived?; end

                    sig { void }
                    def off!; end

                    sig { returns(T::Boolean) }
                    def off?; end

                    sig { void }
                    def on!; end

                    sig { returns(T::Boolean) }
                    def on?; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Conversation))
            end

            it "generates RBI file for classes with multiple enum attributes with mix value types" do
              add_ruby_file("conversation.rb", <<~RUBY)
                class Conversation < ActiveRecord::Base
                  enum status: { active: 0, archived: true, inactive: "Inactive" }
                  enum comments_status: { on: 0, off: false, ongoing: "Ongoing", topic: [1,2,3] }
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Conversation
                  include EnumMethodsModule

                  class << self
                    sig { returns(T::Hash[T.any(::String, ::Symbol), T.any(::Integer, ::FalseClass, ::String, ::Array)]) }
                    def comments_statuses; end

                    sig { returns(T::Hash[T.any(::String, ::Symbol), T.any(::Integer, ::TrueClass, ::String)]) }
                    def statuses; end
                  end

                  module EnumMethodsModule
                    sig { void }
                    def active!; end

                    sig { returns(T::Boolean) }
                    def active?; end

                    sig { void }
                    def archived!; end

                    sig { returns(T::Boolean) }
                    def archived?; end

                    sig { void }
                    def inactive!; end

                    sig { returns(T::Boolean) }
                    def inactive?; end

                    sig { void }
                    def off!; end

                    sig { returns(T::Boolean) }
                    def off?; end

                    sig { void }
                    def on!; end

                    sig { returns(T::Boolean) }
                    def on?; end

                    sig { void }
                    def ongoing!; end

                    sig { returns(T::Boolean) }
                    def ongoing?; end

                    sig { void }
                    def topic!; end

                    sig { returns(T::Boolean) }
                    def topic?; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Conversation))
            end

            it "generates RBI file for classes with enum attribute with suffix specified" do
              add_ruby_file("conversation.rb", <<~RUBY)
                class Conversation < ActiveRecord::Base
                  enum status: [:active, :archived], _suffix: true
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Conversation
                  include EnumMethodsModule

                  class << self
                    sig { returns(T::Hash[T.any(::String, ::Symbol), ::Integer]) }
                    def statuses; end
                  end

                  module EnumMethodsModule
                    sig { void }
                    def active_status!; end

                    sig { returns(T::Boolean) }
                    def active_status?; end

                    sig { void }
                    def archived_status!; end

                    sig { returns(T::Boolean) }
                    def archived_status?; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Conversation))
            end

            it "generates RBI file for classes with enum attribute with prefix specified" do
              add_ruby_file("conversation.rb", <<~RUBY)
                class Conversation < ActiveRecord::Base
                  enum status: [:active, :archived], _prefix: :comments
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Conversation
                  include EnumMethodsModule

                  class << self
                    sig { returns(T::Hash[T.any(::String, ::Symbol), ::Integer]) }
                    def statuses; end
                  end

                  module EnumMethodsModule
                    sig { void }
                    def comments_active!; end

                    sig { returns(T::Boolean) }
                    def comments_active?; end

                    sig { void }
                    def comments_archived!; end

                    sig { returns(T::Boolean) }
                    def comments_archived?; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Conversation))
            end

            it "generates RBI file for classes with enum attribute with inheritance" do
              add_ruby_file("conversation.rb", <<~RUBY)
                class AbstractConversation < ActiveRecord::Base
                  enum status: [:active, :archived]
                end

                class Conversation < AbstractConversation
                  enum status: [:inactive]
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Conversation
                  include EnumMethodsModule

                  class << self
                    sig { returns(T::Hash[T.any(::String, ::Symbol), ::Integer]) }
                    def statuses; end
                  end

                  module EnumMethodsModule
                    sig { void }
                    def inactive!; end

                    sig { returns(T::Boolean) }
                    def inactive?; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Conversation))

              expected = <<~RBI
                # typed: strong

                class AbstractConversation
                  include EnumMethodsModule

                  class << self
                    sig { returns(T::Hash[T.any(::String, ::Symbol), ::Integer]) }
                    def statuses; end
                  end

                  module EnumMethodsModule
                    sig { void }
                    def active!; end

                    sig { returns(T::Boolean) }
                    def active?; end

                    sig { void }
                    def archived!; end

                    sig { returns(T::Boolean) }
                    def archived?; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:AbstractConversation))
            end

            it "generates RBI file for classes with enum attribute with inheritance from abstract class" do
              add_ruby_file("conversation.rb", <<~RUBY)
                class AbstractConversation < ActiveRecord::Base
                  self.abstract_class = true

                  enum status: [:active, :archived]
                end

                class Conversation < AbstractConversation
                  enum status: [:inactive]
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Conversation
                  include EnumMethodsModule

                  class << self
                    sig { returns(T::Hash[T.any(::String, ::Symbol), ::Integer]) }
                    def statuses; end
                  end

                  module EnumMethodsModule
                    sig { void }
                    def inactive!; end

                    sig { returns(T::Boolean) }
                    def inactive?; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Conversation))

              expected = <<~RBI
                # typed: strong

                class AbstractConversation
                  include EnumMethodsModule

                  class << self
                    sig { returns(T::Hash[T.any(::String, ::Symbol), ::Integer]) }
                    def statuses; end
                  end

                  module EnumMethodsModule
                    sig { void }
                    def active!; end

                    sig { returns(T::Boolean) }
                    def active?; end

                    sig { void }
                    def archived!; end

                    sig { returns(T::Boolean) }
                    def archived?; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:AbstractConversation))
            end
          end
        end
      end
    end
  end
end
