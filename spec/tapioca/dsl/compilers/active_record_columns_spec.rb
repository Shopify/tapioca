# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordColumnsSpec < ::DslSpec
        extend Tapioca::Helpers::Test::Template

        describe "Tapioca::Dsl::Compilers::ActiveRecordColumns" do
          sig { void }
          def before_setup
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
                class Post < ActiveRecord::Base
                end

                class Current < ActiveRecord::Base
                  self.abstract_class = true
                end
              RUBY

              assert_equal(["Post"], gathered_constants)
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

            describe "by default" do
              it "generates default columns with persisted types and respects db nullability" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                  end
                RUBY

                expected = template(<<~RBI, trim_mode: "-")
                  # typed: strong

                  class Post
                    include GeneratedAttributeMethods

                    module GeneratedAttributeMethods
                      sig { returns(::Integer) }
                      def id; end

                      sig { params(value: ::Integer).returns(::Integer) }
                      def id=(value); end

                      sig { returns(T::Boolean) }
                      def id?; end

                      sig { returns(T.nilable(::Integer)) }
                      def id_before_last_save; end

                      sig { returns(T.untyped) }
                      def id_before_type_cast; end

                      sig { returns(T::Boolean) }
                      def id_came_from_user?; end

                      sig { returns(T.nilable([::Integer, ::Integer])) }
                      def id_change; end

                      sig { returns(T.nilable([::Integer, ::Integer])) }
                      def id_change_to_be_saved; end

                      sig { params(from: ::Integer, to: ::Integer).returns(T::Boolean) }
                      def id_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                      sig { returns(T.nilable(::Integer)) }
                      def id_in_database; end

                      sig { returns(T.nilable([::Integer, ::Integer])) }
                      def id_previous_change; end

                      sig { params(from: ::Integer, to: ::Integer).returns(T::Boolean) }
                      def id_previously_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                      sig { returns(T.nilable(::Integer)) }
                      def id_previously_was; end

                    <%- if rails_version(">= 7.1") -%>
                      sig { returns(::Integer) }
                      def id_value; end

                      sig { params(value: ::Integer).returns(::Integer) }
                      def id_value=(value); end

                      sig { returns(T::Boolean) }
                      def id_value?; end

                      sig { returns(T.nilable(::Integer)) }
                      def id_value_before_last_save; end

                      sig { returns(T.untyped) }
                      def id_value_before_type_cast; end

                      sig { returns(T::Boolean) }
                      def id_value_came_from_user?; end

                      sig { returns(T.nilable([::Integer, ::Integer])) }
                      def id_value_change; end

                      sig { returns(T.nilable([::Integer, ::Integer])) }
                      def id_value_change_to_be_saved; end

                      sig { params(from: ::Integer, to: ::Integer).returns(T::Boolean) }
                      def id_value_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                      sig { returns(T.nilable(::Integer)) }
                      def id_value_in_database; end

                      sig { returns(T.nilable([::Integer, ::Integer])) }
                      def id_value_previous_change; end

                      sig { params(from: ::Integer, to: ::Integer).returns(T::Boolean) }
                      def id_value_previously_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                      sig { returns(T.nilable(::Integer)) }
                      def id_value_previously_was; end

                      sig { returns(T.nilable(::Integer)) }
                      def id_value_was; end

                      sig { void }
                      def id_value_will_change!; end

                    <%- end -%>
                      sig { returns(T.nilable(::Integer)) }
                      def id_was; end

                      sig { void }
                      def id_will_change!; end

                      sig { void }
                      def restore_id!; end

                    <%- if rails_version(">= 7.1") -%>
                      sig { void }
                      def restore_id_value!; end

                    <%- end -%>
                      sig { returns(T.nilable([::Integer, ::Integer])) }
                      def saved_change_to_id; end

                      sig { returns(T::Boolean) }
                      def saved_change_to_id?; end

                    <%- if rails_version(">= 7.1") -%>
                      sig { returns(T.nilable([::Integer, ::Integer])) }
                      def saved_change_to_id_value; end

                      sig { returns(T::Boolean) }
                      def saved_change_to_id_value?; end

                      sig { returns(T::Boolean) }
                      def will_save_change_to_id?; end

                      sig { returns(T::Boolean) }
                      def will_save_change_to_id_value?; end
                    <%- else -%>
                      sig { returns(T::Boolean) }
                      def will_save_change_to_id?; end
                    <%- end -%>
                    end
                  end
                RBI

                assert_equal(expected, rbi_for(:Post))
              end

              it "generates attributes with persisted types and respects db nullability" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        t.string :body
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                  end
                RUBY

                expected = indented(<<~RBI, 2)
                  module GeneratedAttributeMethods
                    sig { returns(T.nilable(::String)) }
                    def body; end

                    sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                    def body=(value); end

                    sig { returns(T::Boolean) }
                    def body?; end
                RBI

                assert_includes(rbi_for(:Post), expected)
              end

              it "respects nullability of attributes" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        t.string :title, null: false
                        t.string :body, null: true
                        t.timestamps
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                  end
                RUBY

                output = rbi_for(:Post)

                expected = indented(<<~RBI, 4)
                  sig { returns(T.nilable(::String)) }
                  def body; end

                  sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                  def body=(value); end

                  sig { returns(T::Boolean) }
                  def body?; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(::String) }
                  def title; end

                  sig { params(value: ::String).returns(::String) }
                  def title=(value); end

                  sig { returns(T::Boolean) }
                  def title?; end
                RBI
                assert_includes(output, expected)
              end

              it "skips columns with names that can't be Ruby method names" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        t.string :"4_to_5"
                        t.string :"foo-bar"
                        t.string :"@foo"
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                  end
                RUBY

                output = rbi_for(:Post)

                # "4_to_5" should never be the start of a method name,
                # but method names like "saved_change_to_4_to_5" are fine.
                refute_includes(output, "def 4_to_5")
                # no method name should include "foo-bar"
                refute_includes(output, "foo-bar")
                # no method name should include "@foo"
                refute_includes(output, "@foo")
              end

              it "generates a proper type for every ActiveRecord column type" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        t.integer :integer_column
                        t.string :string_column
                        t.date :date_column
                        t.decimal :decimal_column
                        t.float :float_column
                        t.boolean :boolean_column
                        t.datetime :datetime_column
                        t.decimal :money_column
                        t.text :serialized_column
                        # Ideally this would also test t.enum but that is not supported by sqlite
                        t.integer :integer_enum_column
                        t.string :string_enum_column
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  require "rails/railtie"
                  require "money"

                  class Post < ActiveRecord::Base
                    money_column(:money_column, currency: "USD")
                    serialize :serialized_column
                    # Change enum calls to new syntax when we drop support to Rails 6.
                    enum integer_enum_column: [ :active, :archived ]
                    enum string_enum_column: { high: 'high', low: 'low' }
                  end
                RUBY

                output = rbi_for(:Post)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
                  def integer_column=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                  def string_column=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(::Date)).returns(T.nilable(::Date)) }
                  def date_column=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(::BigDecimal)).returns(T.nilable(::BigDecimal)) }
                  def decimal_column=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(::Float)).returns(T.nilable(::Float)) }
                  def float_column=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(T::Boolean)).returns(T.nilable(T::Boolean)) }
                  def boolean_column=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(::Time)).returns(T.nilable(::Time)) }
                  def datetime_column=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(::Money)).returns(T.nilable(::Money)) }
                  def money_column=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.untyped).returns(T.untyped) }
                  def serialized_column=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(T.nilable(::String)) }
                  def integer_enum_column; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(T.any(::String, ::Symbol, ::Integer))).returns(T.nilable(T.any(::String, ::Symbol, ::Integer))) }
                  def integer_enum_column=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(T.nilable(::String)) }
                  def string_enum_column; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(T.any(::String, ::Symbol))).returns(T.nilable(T.any(::String, ::Symbol))) }
                  def string_enum_column=(value); end
                RBI
                assert_includes(output, expected)
              end

              it "generates correct types for serialized columns" do
                add_ruby_file("schema.rb", <<~RUBY)
                  class CustomCoder
                    def self.dump(value); nil end
                    def self.load; nil end
                  end

                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        t.text :serialized_column_array
                        t.text :serialized_column_custom
                        t.text :serialized_column_hash
                        t.text :serialized_column_json
                      end
                    end
                  end
                RUBY

                if rails_version(">= 7.1")
                  add_ruby_file("post.rb", <<~RUBY)
                    class Post < ActiveRecord::Base
                      serialize :serialized_column_array, type: Array
                      serialize :serialized_column_hash, type: Hash
                      serialize :serialized_column_json, coder: JSON
                      serialize :serialized_column_custom, coder: CustomCoder
                    end
                  RUBY
                else
                  add_ruby_file("post.rb", <<~RUBY)
                    class Post < ActiveRecord::Base
                      serialize :serialized_column_array, Array
                      serialize :serialized_column_hash, Hash
                      serialize :serialized_column_json, JSON
                      serialize :serialized_column_custom, CustomCoder
                    end
                  RUBY
                end

                output = rbi_for(:Post)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(T::Array[T.untyped])).returns(T.nilable(T::Array[T.untyped])) }
                  def serialized_column_array=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(T::Array[T.untyped]) }
                  def serialized_column_array; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.untyped).returns(T.untyped) }
                  def serialized_column_custom=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(T.untyped) }
                  def serialized_column_custom; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(T::Hash[T.untyped, T.untyped])).returns(T.nilable(T::Hash[T.untyped, T.untyped])) }
                  def serialized_column_hash=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(T::Hash[T.untyped, T.untyped]) }
                  def serialized_column_hash; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.untyped).returns(T.untyped) }
                  def serialized_column_json=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(T.untyped) }
                  def serialized_column_json; end
                RBI
                assert_includes(output, expected)
              end

              it "falls back to generating BigDecimal for money column if MoneyColumn is not defined" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        t.decimal :money_column
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  require "rails/railtie"
                  require "money"

                  class Post < ActiveRecord::Base
                    money_column(:money_column, currency: "USD")
                  end

                  # Make `MoneyColumn` disappear artificially
                  Object.send(:remove_const, :MoneyColumn)
                RUBY

                output = rbi_for(:Post)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(::BigDecimal)).returns(T.nilable(::BigDecimal)) }
                  def money_column=(value); end
                RBI
                assert_includes(output, expected)
              end

              it "generates proper types for time_zone_aware_attributes" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Base.time_zone_aware_attributes = true
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        t.timestamp :timestamp_column
                        t.datetime :datetime_column
                        t.time :time_column
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                  end
                RUBY

                output = rbi_for(:Post)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(::ActiveSupport::TimeWithZone)).returns(T.nilable(::ActiveSupport::TimeWithZone)) }
                  def timestamp_column=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(::ActiveSupport::TimeWithZone)).returns(T.nilable(::ActiveSupport::TimeWithZone)) }
                  def datetime_column=(value); end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { params(value: T.nilable(::ActiveSupport::TimeWithZone)).returns(T.nilable(::ActiveSupport::TimeWithZone)) }
                  def time_column=(value); end
                RBI
                assert_includes(output, expected)
              end

              it "generates methods for alias_attributes" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        t.string :name
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                    alias_attribute :author, :name
                  end
                RUBY

                output = rbi_for(:Post)

                expected = indented(<<~RBI, 2)
                  module GeneratedAttributeMethods
                    sig { returns(T.nilable(::String)) }
                    def author; end

                    sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                    def author=(value); end

                    sig { returns(T::Boolean) }
                    def author?; end

                    sig { returns(T.nilable(::String)) }
                    def author_before_last_save; end

                    sig { returns(T.untyped) }
                    def author_before_type_cast; end

                    sig { returns(T::Boolean) }
                    def author_came_from_user?; end

                    sig { returns(T.nilable([T.nilable(::String), T.nilable(::String)])) }
                    def author_change; end

                    sig { returns(T.nilable([T.nilable(::String), T.nilable(::String)])) }
                    def author_change_to_be_saved; end

                    sig { params(from: T.nilable(::String), to: T.nilable(::String)).returns(T::Boolean) }
                    def author_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                    sig { returns(T.nilable(::String)) }
                    def author_in_database; end

                    sig { returns(T.nilable([T.nilable(::String), T.nilable(::String)])) }
                    def author_previous_change; end

                    sig { params(from: T.nilable(::String), to: T.nilable(::String)).returns(T::Boolean) }
                    def author_previously_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                    sig { returns(T.nilable(::String)) }
                    def author_previously_was; end

                    sig { returns(T.nilable(::String)) }
                    def author_was; end

                    sig { void }
                    def author_will_change!; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { void }
                  def restore_author!; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(T.nilable([T.nilable(::String), T.nilable(::String)])) }
                  def saved_change_to_author; end

                  sig { returns(T::Boolean) }
                  def saved_change_to_author?; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(T::Boolean) }
                  def will_save_change_to_author?; end
                RBI
                assert_includes(output, expected)
              end

              it "ignores conflicting alias_attributes" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        t.string :body
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                    alias_attribute :body?, :body
                  end
                RUBY

                output = rbi_for(:Post)

                expected = indented(<<~RBI, 2)
                  module GeneratedAttributeMethods
                    sig { returns(T.nilable(::String)) }
                    def body; end

                    sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                    def body=(value); end

                    sig { returns(T::Boolean) }
                    def body?; end

                    sig { returns(T.nilable(::String)) }
                    def body_before_last_save; end

                    sig { returns(T.untyped) }
                    def body_before_type_cast; end

                    sig { returns(T::Boolean) }
                    def body_came_from_user?; end

                    sig { returns(T.nilable([T.nilable(::String), T.nilable(::String)])) }
                    def body_change; end

                    sig { returns(T.nilable([T.nilable(::String), T.nilable(::String)])) }
                    def body_change_to_be_saved; end

                    sig { params(from: T.nilable(::String), to: T.nilable(::String)).returns(T::Boolean) }
                    def body_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                    sig { returns(T.nilable(::String)) }
                    def body_in_database; end

                    sig { returns(T.nilable([T.nilable(::String), T.nilable(::String)])) }
                    def body_previous_change; end

                    sig { params(from: T.nilable(::String), to: T.nilable(::String)).returns(T::Boolean) }
                    def body_previously_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                    sig { returns(T.nilable(::String)) }
                    def body_previously_was; end

                    sig { returns(T.nilable(::String)) }
                    def body_was; end

                    sig { void }
                    def body_will_change!; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { void }
                  def restore_body!; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(T.nilable([T.nilable(::String), T.nilable(::String)])) }
                  def saved_change_to_body; end

                  sig { returns(T::Boolean) }
                  def saved_change_to_body?; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(T::Boolean) }
                  def will_save_change_to_body?; end
                RBI
                assert_includes(output, expected)
              end

              it "generates methods for virtual attributes" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                    attribute :publication_date, :date
                  end
                RUBY

                output = rbi_for(:Post)

                expected = indented(<<~RBI, 4)
                  sig { returns(::Date) }
                  def publication_date; end

                  sig { params(value: ::Date).returns(::Date) }
                  def publication_date=(value); end

                  sig { returns(T::Boolean) }
                  def publication_date?; end

                  sig { returns(T.nilable(::Date)) }
                  def publication_date_before_last_save; end

                  sig { returns(T.untyped) }
                  def publication_date_before_type_cast; end

                  sig { returns(T::Boolean) }
                  def publication_date_came_from_user?; end

                  sig { returns(T.nilable([::Date, ::Date])) }
                  def publication_date_change; end

                  sig { returns(T.nilable([::Date, ::Date])) }
                  def publication_date_change_to_be_saved; end

                  sig { params(from: ::Date, to: ::Date).returns(T::Boolean) }
                  def publication_date_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                  sig { returns(T.nilable(::Date)) }
                  def publication_date_in_database; end

                  sig { returns(T.nilable([::Date, ::Date])) }
                  def publication_date_previous_change; end

                  sig { params(from: ::Date, to: ::Date).returns(T::Boolean) }
                  def publication_date_previously_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                  sig { returns(T.nilable(::Date)) }
                  def publication_date_previously_was; end

                  sig { returns(T.nilable(::Date)) }
                  def publication_date_was; end

                  sig { void }
                  def publication_date_will_change!; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { void }
                  def restore_publication_date!; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(T.nilable([::Date, ::Date])) }
                  def saved_change_to_publication_date; end

                  sig { returns(T::Boolean) }
                  def saved_change_to_publication_date?; end
                RBI
                assert_includes(output, expected)

                expected = indented(<<~RBI, 4)
                  sig { returns(T::Boolean) }
                  def will_save_change_to_publication_date?; end
                RBI
                assert_includes(output, expected)
              end

              it "discovers cast type for normalized attributes" do
                # Support for normalization was added in Rails 7.1 so this test is only relevant
                # for that version and above.
                return unless rails_version(">= 7.1")

                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        t.string :title
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                    normalizes :title, with: ->(title) { title.titleize }
                  end
                RUBY

                expected = indented(<<~RBI, 4)
                  sig { returns(T.nilable(::String)) }
                  def title; end

                  sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                  def title=(value); end

                  sig { returns(T::Boolean) }
                  def title?; end
                RBI

                assert_includes(rbi_for(:Post), expected)
              end

              it "discovers custom type from signature on deserialize method" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        t.decimal :cost
                      end
                    end
                  end
                RUBY

                add_ruby_file("custom_type.rb", <<~RUBY)
                  class CustomType
                    attr_accessor :value

                    def initialize(number = 0.0)
                      @value = number
                    end

                    class Type < ActiveRecord::Type::Value
                      extend(T::Sig)

                      sig { params(value: Numeric).returns(::CustomType)}
                      def deserialize(value)
                        CustomType.new(value)
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                    attribute :cost, CustomType::Type.new
                  end
                RUBY

                expected = indented(<<~RBI, 4)
                  sig { returns(T.nilable(::CustomType)) }
                  def cost; end

                  sig { params(value: T.nilable(::CustomType)).returns(T.nilable(::CustomType)) }
                  def cost=(value); end
                RBI

                assert_includes(rbi_for(:Post), expected)
              end

              it "generates id accessors when primary key isn't id" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts, primary_key: :number do |t|
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                    self.primary_key = :number
                  end
                RUBY

                expected = indented(<<~RBI, 4)
                  sig { returns(::Integer) }
                  def id; end
                RBI

                assert_includes(rbi_for(:Post), expected)
              end
            end

            describe "when compiled with 'untyped' column types" do
              it "generates attributes with untyped" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        t.string :body
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                  end
                RUBY

                expected = indented(<<~RBI, 2)
                  module GeneratedAttributeMethods
                    sig { returns(T.untyped) }
                    def body; end

                    sig { params(value: T.untyped).returns(T.untyped) }
                    def body=(value); end

                    sig { returns(T::Boolean) }
                    def body?; end
                RBI

                assert_includes(rbi_for(:Post, compiler_options: { types: "untyped" }), expected)
              end

              it "generates default columns with untyped" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                  end
                RUBY

                expected = template(<<~RBI, trim_mode: "-")
                  # typed: strong

                  class Post
                    include GeneratedAttributeMethods

                    module GeneratedAttributeMethods
                      sig { returns(T.untyped) }
                      def id; end

                      sig { params(value: T.untyped).returns(T.untyped) }
                      def id=(value); end

                      sig { returns(T::Boolean) }
                      def id?; end

                      sig { returns(T.untyped) }
                      def id_before_last_save; end

                      sig { returns(T.untyped) }
                      def id_before_type_cast; end

                      sig { returns(T::Boolean) }
                      def id_came_from_user?; end

                      sig { returns(T.nilable([T.untyped, T.untyped])) }
                      def id_change; end

                      sig { returns(T.nilable([T.untyped, T.untyped])) }
                      def id_change_to_be_saved; end

                      sig { params(from: T.untyped, to: T.untyped).returns(T::Boolean) }
                      def id_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                      sig { returns(T.untyped) }
                      def id_in_database; end

                      sig { returns(T.nilable([T.untyped, T.untyped])) }
                      def id_previous_change; end

                      sig { params(from: T.untyped, to: T.untyped).returns(T::Boolean) }
                      def id_previously_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                      sig { returns(T.untyped) }
                      def id_previously_was; end

                    <%- if rails_version(">= 7.1") -%>
                      sig { returns(T.untyped) }
                      def id_value; end

                      sig { params(value: T.untyped).returns(T.untyped) }
                      def id_value=(value); end

                      sig { returns(T::Boolean) }
                      def id_value?; end

                      sig { returns(T.untyped) }
                      def id_value_before_last_save; end

                      sig { returns(T.untyped) }
                      def id_value_before_type_cast; end

                      sig { returns(T::Boolean) }
                      def id_value_came_from_user?; end

                      sig { returns(T.nilable([T.untyped, T.untyped])) }
                      def id_value_change; end

                      sig { returns(T.nilable([T.untyped, T.untyped])) }
                      def id_value_change_to_be_saved; end

                      sig { params(from: T.untyped, to: T.untyped).returns(T::Boolean) }
                      def id_value_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                      sig { returns(T.untyped) }
                      def id_value_in_database; end

                      sig { returns(T.nilable([T.untyped, T.untyped])) }
                      def id_value_previous_change; end

                      sig { params(from: T.untyped, to: T.untyped).returns(T::Boolean) }
                      def id_value_previously_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                      sig { returns(T.untyped) }
                      def id_value_previously_was; end

                      sig { returns(T.untyped) }
                      def id_value_was; end

                      sig { void }
                      def id_value_will_change!; end

                    <%- end -%>
                      sig { returns(T.untyped) }
                      def id_was; end

                      sig { void }
                      def id_will_change!; end

                      sig { void }
                      def restore_id!; end

                    <%- if rails_version(">= 7.1") -%>
                      sig { void }
                      def restore_id_value!; end

                    <%- end -%>
                      sig { returns(T.nilable([T.untyped, T.untyped])) }
                      def saved_change_to_id; end

                      sig { returns(T::Boolean) }
                      def saved_change_to_id?; end

                    <%- if rails_version(">= 7.1") -%>
                      sig { returns(T.nilable([T.untyped, T.untyped])) }
                      def saved_change_to_id_value; end

                      sig { returns(T::Boolean) }
                      def saved_change_to_id_value?; end

                      sig { returns(T::Boolean) }
                      def will_save_change_to_id?; end

                      sig { returns(T::Boolean) }
                      def will_save_change_to_id_value?; end
                    <%- else -%>
                      sig { returns(T::Boolean) }
                      def will_save_change_to_id?; end
                    <%- end -%>
                    end
                  end
                RBI

                assert_equal(expected, rbi_for(:Post, compiler_options: { types: "untyped" }))
              end
            end

            describe "when compiled with 'nilable' column types" do
              it "generates attributes with nilable" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                        # explicitly setting null to false to test that we always generate
                        # nilable column types despite this setting
                        t.string :body, null: false
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                  end
                RUBY

                expected = indented(<<~RBI, 2)
                  module GeneratedAttributeMethods
                    sig { returns(T.nilable(::String)) }
                    def body; end

                    sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
                    def body=(value); end

                    sig { returns(T::Boolean) }
                    def body?; end
                RBI

                assert_includes(rbi_for(:Post, compiler_options: { types: "nilable" }), expected)
              end

              it "generates default columns with nilable" do
                add_ruby_file("schema.rb", <<~RUBY)
                  ActiveRecord::Migration.suppress_messages do
                    ActiveRecord::Schema.define do
                      create_table :posts do |t|
                      end
                    end
                  end
                RUBY

                add_ruby_file("post.rb", <<~RUBY)
                  class Post < ActiveRecord::Base
                  end
                RUBY

                expected = template(<<~RBI, trim_mode: "-")
                  # typed: strong

                  class Post
                    include GeneratedAttributeMethods

                    module GeneratedAttributeMethods
                      sig { returns(T.nilable(::Integer)) }
                      def id; end

                      sig { params(value: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
                      def id=(value); end

                      sig { returns(T::Boolean) }
                      def id?; end

                      sig { returns(T.nilable(::Integer)) }
                      def id_before_last_save; end

                      sig { returns(T.untyped) }
                      def id_before_type_cast; end

                      sig { returns(T::Boolean) }
                      def id_came_from_user?; end

                      sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                      def id_change; end

                      sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                      def id_change_to_be_saved; end

                      sig { params(from: T.nilable(::Integer), to: T.nilable(::Integer)).returns(T::Boolean) }
                      def id_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                      sig { returns(T.nilable(::Integer)) }
                      def id_in_database; end

                      sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                      def id_previous_change; end

                      sig { params(from: T.nilable(::Integer), to: T.nilable(::Integer)).returns(T::Boolean) }
                      def id_previously_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                      sig { returns(T.nilable(::Integer)) }
                      def id_previously_was; end

                    <%- if rails_version(">= 7.1") -%>
                      sig { returns(T.nilable(::Integer)) }
                      def id_value; end

                      sig { params(value: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
                      def id_value=(value); end

                      sig { returns(T::Boolean) }
                      def id_value?; end

                      sig { returns(T.nilable(::Integer)) }
                      def id_value_before_last_save; end

                      sig { returns(T.untyped) }
                      def id_value_before_type_cast; end

                      sig { returns(T::Boolean) }
                      def id_value_came_from_user?; end

                      sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                      def id_value_change; end

                      sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                      def id_value_change_to_be_saved; end

                      sig { params(from: T.nilable(::Integer), to: T.nilable(::Integer)).returns(T::Boolean) }
                      def id_value_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                      sig { returns(T.nilable(::Integer)) }
                      def id_value_in_database; end

                      sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                      def id_value_previous_change; end

                      sig { params(from: T.nilable(::Integer), to: T.nilable(::Integer)).returns(T::Boolean) }
                      def id_value_previously_changed?(from: T.unsafe(nil), to: T.unsafe(nil)); end

                      sig { returns(T.nilable(::Integer)) }
                      def id_value_previously_was; end

                      sig { returns(T.nilable(::Integer)) }
                      def id_value_was; end

                      sig { void }
                      def id_value_will_change!; end

                    <%- end -%>
                      sig { returns(T.nilable(::Integer)) }
                      def id_was; end

                      sig { void }
                      def id_will_change!; end

                      sig { void }
                      def restore_id!; end

                    <%- if rails_version(">= 7.1") -%>
                      sig { void }
                      def restore_id_value!; end

                    <%- end -%>
                      sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                      def saved_change_to_id; end

                      sig { returns(T::Boolean) }
                      def saved_change_to_id?; end

                    <%- if rails_version(">= 7.1") -%>
                      sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                      def saved_change_to_id_value; end

                      sig { returns(T::Boolean) }
                      def saved_change_to_id_value?; end

                      sig { returns(T::Boolean) }
                      def will_save_change_to_id?; end

                      sig { returns(T::Boolean) }
                      def will_save_change_to_id_value?; end
                    <%- else -%>
                      sig { returns(T::Boolean) }
                      def will_save_change_to_id?; end
                    <%- end -%>
                    end
                  end
                RBI

                assert_equal(expected, rbi_for(:Post, compiler_options: { types: "nilable" }))
              end
            end
          end
        end
      end
    end
  end
end
