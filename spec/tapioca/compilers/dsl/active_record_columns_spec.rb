# typed: false
# frozen_string_literal: true

require "spec_helper"

describe("Tapioca::Compilers::Dsl::ActiveRecordColumns") do
  before(:each) do
    require "tapioca/compilers/dsl/active_record_columns"
  end

  subject do
    Tapioca::Compilers::Dsl::ActiveRecordColumns.new
  end

  describe("#initialize") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    it("gathers no constants if there are no ActiveRecord subclasses") do
      assert_empty(subject.processable_constants)
    end

    it("gathers only ActiveRecord subclasses") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
        end

        class Current
        end
      RUBY

      assert_equal(constants_from(content), ["Post"])
    end

    it("rejects abstract ActiveRecord subclasses") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
        end

        class Current < ActiveRecord::Base
          self.abstract_class = true
        end
      RUBY

      assert_equal(constants_from(content), ["Post"])
    end
  end

  describe("#decorate") do
    before(:each) do
      ActiveRecord::Base.establish_connection(
        adapter: 'sqlite3',
        database: ':memory:'
      )
    end

    def rbi_for(contents)
      with_contents(contents, requires: contents.keys) do
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Post)
        parlour.rbi
      end
    end

    it("generates RBI file for class without custom attributes with StrongTypeGeneration") do
      files = {
        "file.rb" => <<~RUBY,
          module StrongTypeGeneration
          end

          class Post < ActiveRecord::Base
            extend StrongTypeGeneration
          end
        RUBY

        "schema.rb" => <<~RUBY,
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Schema.define do
              create_table :posts do |t|
              end
            end
          end
        RUBY
      }

      expected = <<~RUBY
        # typed: strong
        class Post
          include Post::GeneratedAttributeMethods
        end

        module Post::GeneratedAttributeMethods
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

          sig { returns([T.nilable(::Integer), T.nilable(::Integer)]) }
          def id_change; end

          sig { returns([T.nilable(::Integer), T.nilable(::Integer)]) }
          def id_change_to_be_saved; end

          sig { returns(T::Boolean) }
          def id_changed?; end

          sig { returns(T.nilable(::Integer)) }
          def id_in_database; end

          sig { returns([T.nilable(::Integer), T.nilable(::Integer)]) }
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

          sig { returns([T.nilable(::Integer), T.nilable(::Integer)]) }
          def saved_change_to_id; end

          sig { returns(T::Boolean) }
          def saved_change_to_id?; end

          sig { returns(T::Boolean) }
          def will_save_change_to_id?; end
        end
      RUBY

      assert_equal(rbi_for(files), expected)
    end

    it("generates RBI file for custom attributes with strong type generation") do
      files = {
        "file.rb" => <<~RUBY,
          module StrongTypeGeneration
          end

          class Post < ActiveRecord::Base
            extend StrongTypeGeneration
          end
        RUBY

        "schema.rb" => <<~RUBY,
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Schema.define do
              create_table :posts do |t|
                t.string :body
              end
            end
          end
        RUBY
      }

      expected = <<~RUBY
        module Post::GeneratedAttributeMethods
          sig { returns(T.nilable(::String)) }
          def body; end

          sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
          def body=(value); end

          sig { returns(T::Boolean) }
          def body?; end
      RUBY
      assert_includes(rbi_for(files), expected)
    end

    it("generates RBI file for custom attributes without strong type generation") do
      files = {
        "file.rb" => <<~RUBY,
          module StrongTypeGeneration
          end

          class Post < ActiveRecord::Base
            # StrongTypeGeneration is not extended
          end
        RUBY

        "schema.rb" => <<~RUBY,
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Schema.define do
              create_table :posts do |t|
                t.string :body
              end
            end
          end
        RUBY
      }

      expected = <<~RUBY
        module Post::GeneratedAttributeMethods
          sig { returns(T.untyped) }
          def body; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def body=(value); end

          sig { returns(T::Boolean) }
          def body?; end
      RUBY

      assert_includes(rbi_for(files), expected)
    end

    it("generates RBI file given nullability of an attribute") do
      files = {
        "file.rb" => <<~RUBY,
          module StrongTypeGeneration
          end

          class Post < ActiveRecord::Base
            extend StrongTypeGeneration
          end
        RUBY

        "schema.rb" => <<~RUBY,
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
      }

      expected = indented(<<~RUBY, 2)
        sig { returns(T.nilable(::String)) }
        def body; end

        sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
        def body=(value); end

        sig { returns(T::Boolean) }
        def body?; end
      RUBY
      output = rbi_for(files)
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { returns(::String) }
        def title; end

        sig { params(value: ::String).returns(::String) }
        def title=(value); end

        sig { returns(T::Boolean) }
        def title?; end
      RUBY
      assert_includes(output, expected)
    end

    it("generates RBI file containing every ActiveRecord column type") do
      files = {
        "file.rb" => <<~RUBY,
          module StrongTypeGeneration
          end

          class Post < ActiveRecord::Base
            extend StrongTypeGeneration
          end
        RUBY

        "schema.rb" => <<~RUBY,
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
              end
            end
          end
        RUBY
      }

      expected = indented(<<~RUBY, 2)
        sig { params(value: T.nilable(::Integer)).returns(T.nilable(::Integer)) }
        def integer_column=(value); end
      RUBY

      output = rbi_for(files)
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { params(value: T.nilable(::String)).returns(T.nilable(::String)) }
        def string_column=(value); end
      RUBY
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { params(value: T.nilable(::Date)).returns(T.nilable(::Date)) }
        def date_column=(value); end
      RUBY
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { params(value: T.nilable(::BigDecimal)).returns(T.nilable(::BigDecimal)) }
        def decimal_column=(value); end
      RUBY
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { params(value: T.nilable(::Float)).returns(T.nilable(::Float)) }
        def float_column=(value); end
      RUBY
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { params(value: T.nilable(T::Boolean)).returns(T.nilable(T::Boolean)) }
        def boolean_column=(value); end
      RUBY
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { params(value: T.nilable(::DateTime)).returns(T.nilable(::DateTime)) }
        def datetime_column=(value); end
      RUBY
      assert_includes(output, expected)
    end

    it("generates RBI file for time_zone_aware_attributes") do
      files = {
        "file.rb" => <<~RUBY,
          module StrongTypeGeneration
          end

          class Post < ActiveRecord::Base
            extend StrongTypeGeneration
          end
        RUBY

        "schema.rb" => <<~RUBY,
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
      }

      expected = indented(<<~RUBY, 2)
        sig { params(value: T.nilable(::ActiveSupport::TimeWithZone)).returns(T.nilable(::ActiveSupport::TimeWithZone)) }
        def timestamp_column=(value); end
      RUBY

      output = rbi_for(files)
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { params(value: T.nilable(::ActiveSupport::TimeWithZone)).returns(T.nilable(::ActiveSupport::TimeWithZone)) }
        def datetime_column=(value); end
      RUBY
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { params(value: T.nilable(::ActiveSupport::TimeWithZone)).returns(T.nilable(::ActiveSupport::TimeWithZone)) }
        def time_column=(value); end
      RUBY
      assert_includes(output, expected)
    end

    it("generates RBI file for alias_attributes") do
      files = {
        "file.rb" => <<~RUBY,
          module StrongTypeGeneration
          end

          class Post < ActiveRecord::Base
            extend StrongTypeGeneration
            alias_attribute :author, :name
          end
        RUBY

        "schema.rb" => <<~RUBY,
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Schema.define do
              create_table :posts do |t|
                t.string :name
              end
            end
          end
        RUBY
      }

      expected = <<~RUBY
        module Post::GeneratedAttributeMethods
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

          sig { returns([T.nilable(::String), T.nilable(::String)]) }
          def author_change; end

          sig { returns([T.nilable(::String), T.nilable(::String)]) }
          def author_change_to_be_saved; end

          sig { returns(T::Boolean) }
          def author_changed?; end

          sig { returns(T.nilable(::String)) }
          def author_in_database; end

          sig { returns([T.nilable(::String), T.nilable(::String)]) }
          def author_previous_change; end

          sig { returns(T::Boolean) }
          def author_previously_changed?; end

          sig { returns(T.nilable(::String)) }
          def author_was; end

          sig { void }
          def author_will_change!; end
      RUBY

      output = rbi_for(files)
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { void }
        def restore_author!; end
      RUBY
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { returns([T.nilable(::String), T.nilable(::String)]) }
        def saved_change_to_author; end

        sig { returns(T::Boolean) }
        def saved_change_to_author?; end
      RUBY
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { returns(T::Boolean) }
        def will_save_change_to_author?; end
      RUBY
      assert_includes(output, expected)
    end

    it("generated RBI file ignores conflicting alias_attributes") do
      files = {
        "file.rb" => <<~RUBY,
          module StrongTypeGeneration
          end

          class Post < ActiveRecord::Base
            extend StrongTypeGeneration
            alias_attribute :body?, :body
          end
        RUBY

        "schema.rb" => <<~RUBY,
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Schema.define do
              create_table :posts do |t|
                t.string :body
              end
            end
          end
        RUBY
      }

      expected = <<~RUBY
        module Post::GeneratedAttributeMethods
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

          sig { returns([T.nilable(::String), T.nilable(::String)]) }
          def body_change; end

          sig { returns([T.nilable(::String), T.nilable(::String)]) }
          def body_change_to_be_saved; end

          sig { returns(T::Boolean) }
          def body_changed?; end

          sig { returns(T.nilable(::String)) }
          def body_in_database; end

          sig { returns([T.nilable(::String), T.nilable(::String)]) }
          def body_previous_change; end

          sig { returns(T::Boolean) }
          def body_previously_changed?; end

          sig { returns(T.nilable(::String)) }
          def body_previously_was; end

          sig { returns(T.nilable(::String)) }
          def body_was; end

          sig { void }
          def body_will_change!; end
      RUBY

      output = rbi_for(files)
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { void }
        def restore_body!; end
      RUBY
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { returns([T.nilable(::String), T.nilable(::String)]) }
        def saved_change_to_body; end

        sig { returns(T::Boolean) }
        def saved_change_to_body?; end
      RUBY
      assert_includes(output, expected)

      expected = indented(<<~RUBY, 2)
        sig { returns(T::Boolean) }
        def will_save_change_to_body?; end
      RUBY
      assert_includes(output, expected)
    end
  end
end
