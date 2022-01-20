# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveRecordColumnsSpec < DslSpec
  describe("Tapioca::Compilers::Dsl::ActiveRecordColumns") do
    describe("#initialize") do
      after(:each) do
        T.unsafe(self).assert_no_generated_errors
      end

      it("gathers no constants if there are no ActiveRecord subclasses") do
        assert_empty(gathered_constants)
      end

      it("gathers only ActiveRecord subclasses") do
        add_ruby_file("content.rb", <<~RUBY)
          class Post < ActiveRecord::Base
          end

          class Current
          end
        RUBY

        assert_equal(["Post"], gathered_constants)
      end

      it("rejects abstract ActiveRecord subclasses") do
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

    describe("#decorate") do
      before(:each) do
        require "active_record"

        ::ActiveRecord::Base.establish_connection(
          adapter: "sqlite3",
          database: ":memory:"
        )
      end

      describe("by default") do
        after(:each) do
          T.unsafe(self).assert_no_generated_errors
        end

        it("generates default columns with strong types") do
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

          expected = <<~RBI
            # typed: strong

            class Post
              include GeneratedAttributeMethods

              module GeneratedAttributeMethods
                sig { returns(T.nilable(::Integer)) }
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

                sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                def id_change; end

                sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                def id_change_to_be_saved; end

                sig { returns(T::Boolean) }
                def id_changed?; end

                sig { returns(T.nilable(::Integer)) }
                def id_in_database; end

                sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                def id_previous_change; end

                sig { returns(T::Boolean) }
                def id_previously_changed?; end

                sig { returns(T.nilable(::Integer)) }
                def id_previously_was; end

                sig { returns(T.nilable(::Integer)) }
                def id_was; end

                sig { void }
                def id_will_change!; end

                sig { void }
                def restore_id!; end

                sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                def saved_change_to_id; end

                sig { returns(T::Boolean) }
                def saved_change_to_id?; end

                sig { returns(T::Boolean) }
                def will_save_change_to_id?; end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it("generates attributes with strong types") do
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

        it("respects nullability of attributes") do
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

        it("generates a proper type for every ActiveRecord column type") do
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
            sig { params(value: T.nilable(::DateTime)).returns(T.nilable(::DateTime)) }
            def datetime_column=(value); end
          RBI
          assert_includes(output, expected)

          expected = indented(<<~RBI, 4)
            sig { params(value: T.nilable(::Money)).returns(T.nilable(::Money)) }
            def money_column=(value); end
          RBI
          assert_includes(output, expected)
        end

        it("falls back to generating BigDecimal for money column if MoneyColumn is not defined") do
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

            # Make `MoneyColumn` disappear artifically
            Object.send(:remove_const, :MoneyColumn)
          RUBY

          output = rbi_for(:Post)

          expected = indented(<<~RBI, 4)
            sig { params(value: T.nilable(::BigDecimal)).returns(T.nilable(::BigDecimal)) }
            def money_column=(value); end
          RBI
          assert_includes(output, expected)
        end

        it("generates proper types for time_zone_aware_attributes") do
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

        it("generates methods for alias_attributes") do
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

              sig { returns(T::Boolean) }
              def author_changed?; end

              sig { returns(T.nilable(::String)) }
              def author_in_database; end

              sig { returns(T.nilable([T.nilable(::String), T.nilable(::String)])) }
              def author_previous_change; end

              sig { returns(T::Boolean) }
              def author_previously_changed?; end

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

        it("ignores conflicting alias_attributes") do
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

              sig { returns(T::Boolean) }
              def body_changed?; end

              sig { returns(T.nilable(::String)) }
              def body_in_database; end

              sig { returns(T.nilable([T.nilable(::String), T.nilable(::String)])) }
              def body_previous_change; end

              sig { returns(T::Boolean) }
              def body_previously_changed?; end

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

        it("discovers custom type from signature on deserialize method") do
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
            sig { returns(T.nilable(CustomType)) }
            def cost; end

            sig { params(value: T.nilable(CustomType)).returns(T.nilable(CustomType)) }
            def cost=(value); end
          RBI

          assert_includes(rbi_for(:Post), expected)
        end

        it("discovers custom type from signature on cast method") do
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

                sig { params(value: ::Numeric).returns(T.any(::CustomType, Numeric)) }
                def cast(value)
                  decimal = super
                  return CustomType.new(decimal) if decimal
                  decimal
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
            sig { returns(T.nilable(T.any(CustomType, Numeric))) }
            def cost; end

            sig { params(value: T.nilable(T.any(CustomType, Numeric))).returns(T.nilable(T.any(CustomType, Numeric))) }
            def cost=(value); end
          RBI

          assert_includes(rbi_for(:Post), expected)
        end

        it("discovers custom type from signature on serialize method") do
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

                sig { params(value: ::CustomType).returns(Numeric) }
                def serialize(value)
                  value = super unless value.is_a?(::CustomType)
                  value.value unless value.nil?
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
            sig { returns(T.nilable(CustomType)) }
            def cost; end

            sig { params(value: T.nilable(CustomType)).returns(T.nilable(CustomType)) }
            def cost=(value); end
          RBI

          assert_includes(rbi_for(:Post), expected)
        end

        it("discovers custom type even if it is generic") do
          add_ruby_file("schema.rb", <<~RUBY)
            ActiveRecord::Migration.suppress_messages do
              ActiveRecord::Schema.define do
                create_table :posts do |t|
                  t.decimal :cost
                end
              end
            end
          RUBY

          add_ruby_file("column_type.rb", <<~RUBY)
            class ValueType
              extend T::Generic

              Elem = type_member
            end

            class ColumnType < ActiveRecord::Type::Value
              extend(T::Sig)

              sig { params(value: ::ValueType[Integer]).returns(Numeric) }
              def serialize(value)
                super
              end
            end
          RUBY

          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
              attribute :cost, ColumnType.new
            end
          RUBY

          expected = indented(<<~RUBY, 4)
            sig { returns(T.nilable(ValueType[Integer])) }
            def cost; end

            sig { params(value: T.nilable(ValueType[Integer])).returns(T.nilable(ValueType[Integer])) }
            def cost=(value); end
          RUBY

          assert_includes(rbi_for(:Post), expected)
        end

        it("generates a weak type when the custom column type is a type variable") do
          add_ruby_file("schema.rb", <<~RUBY)
            ActiveRecord::Migration.suppress_messages do
              ActiveRecord::Schema.define do
                create_table :posts do |t|
                  t.decimal :cost
                end
              end
            end
          RUBY

          add_ruby_file("column_type.rb", <<~RUBY)
            class ColumnType < ActiveRecord::Type::Value
              extend(T::Sig)
              extend T::Generic

              Elem = type_member

              sig { params(value: Elem).returns(Numeric) }
              def serialize(value)
                super
              end
            end
          RUBY

          add_ruby_file("post.rb", <<~RUBY)
            class Post < ActiveRecord::Base
              attribute :cost, ColumnType[Integer].new
            end
          RUBY

          expected = indented(<<~RUBY, 4)
            sig { returns(T.untyped) }
            def cost; end

            sig { params(value: T.untyped).returns(T.untyped) }
            def cost=(value); end
          RUBY

          assert_includes(rbi_for(:Post), expected)
        end

        it("generates a weak type if custom type cannot be discovered from signatures") do
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
            sig { returns(T.untyped) }
            def cost; end

            sig { params(value: T.untyped).returns(T.untyped) }
            def cost=(value); end
          RBI

          assert_includes(rbi_for(:Post), expected)
        end
      end

      describe("when StrongTypeGeneration is defined") do
        after(:each) do
          T.unsafe(self).assert_no_generated_errors
        end

        before do
          add_ruby_file("strong_type_generation.rb", <<~RUBY)
            module StrongTypeGeneration
            end
          RUBY
        end

        it("generates default columns with strong types if model extends StrongTypeGeneration") do
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
              extend StrongTypeGeneration
            end
          RUBY

          expected = <<~RBI
            # typed: strong

            class Post
              include GeneratedAttributeMethods

              module GeneratedAttributeMethods
                sig { returns(T.nilable(::Integer)) }
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

                sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                def id_change; end

                sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                def id_change_to_be_saved; end

                sig { returns(T::Boolean) }
                def id_changed?; end

                sig { returns(T.nilable(::Integer)) }
                def id_in_database; end

                sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                def id_previous_change; end

                sig { returns(T::Boolean) }
                def id_previously_changed?; end

                sig { returns(T.nilable(::Integer)) }
                def id_previously_was; end

                sig { returns(T.nilable(::Integer)) }
                def id_was; end

                sig { void }
                def id_will_change!; end

                sig { void }
                def restore_id!; end

                sig { returns(T.nilable([T.nilable(::Integer), T.nilable(::Integer)])) }
                def saved_change_to_id; end

                sig { returns(T::Boolean) }
                def saved_change_to_id?; end

                sig { returns(T::Boolean) }
                def will_save_change_to_id?; end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it("generates default columns with weak types if model does not extend StrongTypeGeneration") do
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
              # StrongTypeGeneration is not extended
            end
          RUBY

          expected = <<~RBI
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

                sig { returns(T::Boolean) }
                def id_changed?; end

                sig { returns(T.untyped) }
                def id_in_database; end

                sig { returns(T.nilable([T.untyped, T.untyped])) }
                def id_previous_change; end

                sig { returns(T::Boolean) }
                def id_previously_changed?; end

                sig { returns(T.untyped) }
                def id_previously_was; end

                sig { returns(T.untyped) }
                def id_was; end

                sig { void }
                def id_will_change!; end

                sig { void }
                def restore_id!; end

                sig { returns(T.nilable([T.untyped, T.untyped])) }
                def saved_change_to_id; end

                sig { returns(T::Boolean) }
                def saved_change_to_id?; end

                sig { returns(T::Boolean) }
                def will_save_change_to_id?; end
              end
            end
          RBI

          assert_equal(expected, rbi_for(:Post))
        end

        it("generates attributes with strong types if model extends StrongTypeGeneration") do
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
              extend StrongTypeGeneration
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

        it("generates attributes with weak types if model does not extend StrongTypeGeneration") do
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
              # StrongTypeGeneration is not extended
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

          assert_includes(rbi_for(:Post), expected)
        end
      end
    end
  end
end
