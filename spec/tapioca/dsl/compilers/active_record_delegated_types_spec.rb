# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordDelegatedTypesSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveRecordDelegatedTypesSpec" do
          sig { void }
          def before_setup
            require "tapioca/dsl/extensions/active_record"
          end

          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord subclasses" do
              assert_empty(gathered_constants)
            end

            it "gathers only ActiveRecord subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end

                class Current
                end
              RUBY

              assert_equal(["Post"], gathered_constants)
            end

            it "rejects abstract ActiveRecord subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class Comment < ActiveRecord::Base
                end

                class Post < Comment
                end

                class Current < ActiveRecord::Base
                  self.abstract_class = true
                end
              RUBY

              assert_equal(["Comment", "Post"], gathered_constants)
            end
          end

          describe "decorate" do
            before do
              require "active_record"

              ::ActiveRecord::Base.establish_connection(
                adapter: "sqlite3",
                database: ":memory:",
              )
            end

            it "generates empty RBI file if there are no delegated_types" do
              add_ruby_file("post.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end
              RUBY

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for(:Post))
            end

            it "generates RBI file for delegated_type with default options" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :entries do |t|
                      t.string :entryable_type
                      t.integer :entryable_id
                    end
                  end
                end
              RUBY

              add_ruby_file("comment.rb", <<~RUBY)
                class Comment < ActiveRecord::Base
                end
              RUBY

              add_ruby_file("message.rb", <<~RUBY)
                class Message < ActiveRecord::Base
                end
              RUBY

              add_ruby_file("entry.rb", <<~RUBY)
                class Entry < ActiveRecord::Base
                  delegated_type :entryable, types: %w[ Message Comment ]
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Entry
                  include GeneratedDelegatedTypeMethods

                  module GeneratedDelegatedTypeMethods
                    sig { params(args: T.untyped).returns(T.any(Message, Comment)) }
                    def build_entryable(*args); end

                    sig { returns(T.nilable(Comment)) }
                    def comment; end

                    sig { returns(T::Boolean) }
                    def comment?; end

                    sig { returns(T.nilable(::Integer)) }
                    def comment_id; end

                    sig { returns(Class) }
                    def entryable_class; end

                    sig { returns(ActiveSupport::StringInquirer) }
                    def entryable_name; end

                    sig { returns(T.nilable(Message)) }
                    def message; end

                    sig { returns(T::Boolean) }
                    def message?; end

                    sig { returns(T.nilable(::Integer)) }
                    def message_id; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Entry))
            end

            it "generates RBI file for delegated_type with options" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :entries do |t|
                      t.string :entryable_type
                      t.string :entryable_uuid
                    end
                  end
                end
              RUBY

              add_ruby_file("comment.rb", <<~RUBY)
                class Comment < ActiveRecord::Base
                end
              RUBY

              add_ruby_file("message.rb", <<~RUBY)
                class Message < ActiveRecord::Base
                end
              RUBY

              add_ruby_file("entry.rb", <<~RUBY)
                class Entry < ActiveRecord::Base
                  delegated_type :entryable, types: %w[ Message Comment ], primary_key: :uuid, foreign_key: :entryable_uuid
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Entry
                  include GeneratedDelegatedTypeMethods

                  module GeneratedDelegatedTypeMethods
                    sig { params(args: T.untyped).returns(T.any(Message, Comment)) }
                    def build_entryable(*args); end

                    sig { returns(T.nilable(Comment)) }
                    def comment; end

                    sig { returns(T::Boolean) }
                    def comment?; end

                    sig { returns(T.nilable(::String)) }
                    def comment_uuid; end

                    sig { returns(Class) }
                    def entryable_class; end

                    sig { returns(ActiveSupport::StringInquirer) }
                    def entryable_name; end

                    sig { returns(T.nilable(Message)) }
                    def message; end

                    sig { returns(T::Boolean) }
                    def message?; end

                    sig { returns(T.nilable(::String)) }
                    def message_uuid; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Entry))
            end
          end
        end
      end
    end
  end
end
