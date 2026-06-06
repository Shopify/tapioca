# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordDelegatedTypesSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveRecordDelegatedTypesSpec" do
          #: -> void
          def before_setup
            require "tapioca/dsl/extensions/active_record"
            require "active_record"
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
                    sig { params(args: T.untyped).returns(T.any(::Message, ::Comment)) }
                    def build_entryable(*args); end

                    sig { returns(T.nilable(::Comment)) }
                    def comment; end

                    sig { returns(T::Boolean) }
                    def comment?; end

                    sig { returns(T.nilable(::Integer)) }
                    def comment_id; end

                    sig { returns(T::Class[T.anything]) }
                    def entryable_class; end

                    sig { returns(ActiveSupport::StringInquirer) }
                    def entryable_name; end

                    sig { returns(T.nilable(::Message)) }
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
                    sig { params(args: T.untyped).returns(T.any(::Message, ::Comment)) }
                    def build_entryable(*args); end

                    sig { returns(T.nilable(::Comment)) }
                    def comment; end

                    sig { returns(T::Boolean) }
                    def comment?; end

                    sig { returns(T.nilable(::String)) }
                    def comment_uuid; end

                    sig { returns(T::Class[T.anything]) }
                    def entryable_class; end

                    sig { returns(ActiveSupport::StringInquirer) }
                    def entryable_name; end

                    sig { returns(T.nilable(::Message)) }
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

            it "generates RBI file for delegated_type with single type" do
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

              add_ruby_file("message.rb", <<~RUBY)
                class Message < ActiveRecord::Base
                end
              RUBY

              add_ruby_file("entry.rb", <<~RUBY)
                class Entry < ActiveRecord::Base
                  delegated_type :entryable, types: %w[ Message ]
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Entry
                  include GeneratedDelegatedTypeMethods

                  module GeneratedDelegatedTypeMethods
                    sig { params(args: T.untyped).returns(::Message) }
                    def build_entryable(*args); end

                    sig { returns(T::Class[T.anything]) }
                    def entryable_class; end

                    sig { returns(ActiveSupport::StringInquirer) }
                    def entryable_name; end

                    sig { returns(T.nilable(::Message)) }
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

            it "generates RBI file with fully-qualified names for unqualified, namespaced, and root-prefixed types" do
              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :entries do |t|
                      t.string :entryable_type
                      t.integer :entryable_id
                      t.string :shareable_type
                      t.integer :shareable_id
                    end
                  end
                end
              RUBY

              add_ruby_file("models.rb", <<~RUBY)
                class Toplevel < ActiveRecord::Base
                  self.table_name = "entries"
                end

                module Shared
                  class Message < ActiveRecord::Base
                    self.table_name = "entries"
                  end
                end

                module Content
                  class Message < ActiveRecord::Base
                    self.table_name = "entries"
                  end

                  class Comment < ActiveRecord::Base
                    self.table_name = "entries"
                  end
                end

                class Content::Entry < ActiveRecord::Base
                  self.table_name = "entries"
                  # `Message`/`Comment` are unqualified and resolve into the parent namespace
                  # (`Content::*`); `Shared::Message` resolves outside it; `::Toplevel` is
                  # already root-qualified and must not be doubled into `::::Toplevel`.
                  delegated_type :entryable, types: %w[ Message Comment ]
                  delegated_type :shareable, types: %w[ Shared::Message ::Toplevel ]
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Content::Entry
                  include GeneratedDelegatedTypeMethods

                  module GeneratedDelegatedTypeMethods
                    sig { returns(T.nilable(::Toplevel)) }
                    def _toplevel; end

                    sig { returns(T::Boolean) }
                    def _toplevel?; end

                    sig { returns(T.nilable(::Integer)) }
                    def _toplevel_id; end

                    sig { params(args: T.untyped).returns(T.any(::Content::Message, ::Content::Comment)) }
                    def build_entryable(*args); end

                    sig { params(args: T.untyped).returns(T.any(::Shared::Message, ::Toplevel)) }
                    def build_shareable(*args); end

                    sig { returns(T.nilable(::Content::Comment)) }
                    def comment; end

                    sig { returns(T::Boolean) }
                    def comment?; end

                    sig { returns(T.nilable(::Integer)) }
                    def comment_id; end

                    sig { returns(T::Class[T.anything]) }
                    def entryable_class; end

                    sig { returns(ActiveSupport::StringInquirer) }
                    def entryable_name; end

                    sig { returns(T.nilable(::Content::Message)) }
                    def message; end

                    sig { returns(T::Boolean) }
                    def message?; end

                    sig { returns(T.nilable(::Integer)) }
                    def message_id; end

                    sig { returns(T::Class[T.anything]) }
                    def shareable_class; end

                    sig { returns(ActiveSupport::StringInquirer) }
                    def shareable_name; end

                    sig { returns(T.nilable(::Shared::Message)) }
                    def shared_message; end

                    sig { returns(T::Boolean) }
                    def shared_message?; end

                    sig { returns(T.nilable(::Integer)) }
                    def shared_message_id; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for("Content::Entry"))
            end

            it "emits T.untyped and an error for each type that cannot be resolved" do
              expect_dsl_compiler_errors!

              add_ruby_file("schema.rb", <<~RUBY)
                ActiveRecord::Migration.suppress_messages do
                  ActiveRecord::Schema.define do
                    create_table :entries do |t|
                      t.string :entryable_type
                      t.integer :entryable_id
                      t.string :attachable_type
                      t.integer :attachable_id
                    end
                  end
                end
              RUBY

              add_ruby_file("message.rb", <<~RUBY)
                class Message < ActiveRecord::Base
                  self.table_name = "entries"
                end
              RUBY

              add_ruby_file("entry.rb", <<~RUBY)
                class Entry < ActiveRecord::Base
                  self.table_name = "entries"
                  # A wholly-unresolvable role collapses `build_*` to `T.untyped`; a
                  # partially-resolvable role collapses `T.any(::Message, T.untyped)` the same way.
                  delegated_type :entryable, types: %w[ Phantom ]
                  delegated_type :attachable, types: %w[ Message Ghost ]
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class Entry
                  include GeneratedDelegatedTypeMethods

                  module GeneratedDelegatedTypeMethods
                    sig { returns(T::Class[T.anything]) }
                    def attachable_class; end

                    sig { returns(ActiveSupport::StringInquirer) }
                    def attachable_name; end

                    sig { params(args: T.untyped).returns(T.untyped) }
                    def build_attachable(*args); end

                    sig { params(args: T.untyped).returns(T.untyped) }
                    def build_entryable(*args); end

                    sig { returns(T::Class[T.anything]) }
                    def entryable_class; end

                    sig { returns(ActiveSupport::StringInquirer) }
                    def entryable_name; end

                    sig { returns(T.nilable(T.untyped)) }
                    def ghost; end

                    sig { returns(T::Boolean) }
                    def ghost?; end

                    sig { returns(T.nilable(::Integer)) }
                    def ghost_id; end

                    sig { returns(T.nilable(::Message)) }
                    def message; end

                    sig { returns(T::Boolean) }
                    def message?; end

                    sig { returns(T.nilable(::Integer)) }
                    def message_id; end

                    sig { returns(T.nilable(T.untyped)) }
                    def phantom; end

                    sig { returns(T::Boolean) }
                    def phantom?; end

                    sig { returns(T.nilable(::Integer)) }
                    def phantom_id; end
                  end
                end
              RBI

              expected_errors = [
                "Cannot generate delegated_type `entryable` on `Entry` since the type `Phantom` could not be resolved.",
                "Cannot generate delegated_type `attachable` on `Entry` since the type `Ghost` could not be resolved.",
              ]

              assert_equal(expected, rbi_for(:Entry))
              assert_equal(expected_errors, generated_errors)
            end
          end
        end
      end
    end
  end
end
