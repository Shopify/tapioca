# typed: false
# frozen_string_literal: true

require "spec_helper"
require "tapioca/compilers/dsl/active_record_columns"

RSpec.describe(Tapioca::Compilers::Dsl::ActiveRecordColumns) do
  describe("#initialize") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    it("gathers no constants if there are no ActiveRecord subclasses") do
      expect(subject.processable_constants).to(be_empty)
    end

    it("gathers only ActiveRecord subclasses") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
        end

        class Current
        end
      RUBY

      expect(constants_from(content)).to(eq(["Post"]))
    end

    it("rejects abstract ActiveRecord subclasses") do
      content = <<~RUBY
        class Post < ActiveRecord::Base
        end

        class Current < ActiveRecord::Base
          self.abstract_class = true
        end
      RUBY

      expect(constants_from(content)).to(eq(["Post"]))
    end
  end

  describe("#decorate") do
    before(:all) do
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

      expect(rbi_for(files)).to(eq(expected))
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

          sig { params(value: ::String).returns(::String) }
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
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { void }
        def restore_body!; end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { returns([T.nilable(::String), T.nilable(::String)]) }
        def saved_change_to_body; end

        sig { returns(T::Boolean) }
        def saved_change_to_body?; end
      RUBY
      expect(output).to(include(expected))
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

          sig { returns(T.untyped) }
          def body_before_last_save; end

          sig { returns(T.untyped) }
          def body_before_type_cast; end

          sig { returns(T::Boolean) }
          def body_came_from_user?; end

          sig { returns([T.untyped, T.untyped]) }
          def body_change; end

          sig { returns([T.untyped, T.untyped]) }
          def body_change_to_be_saved; end

          sig { returns(T::Boolean) }
          def body_changed?; end

          sig { returns(T.untyped) }
          def body_in_database; end

          sig { returns([T.untyped, T.untyped]) }
          def body_previous_change; end

          sig { returns(T::Boolean) }
          def body_previously_changed?; end

          sig { returns(T.untyped) }
          def body_previously_was; end

          sig { returns(T.untyped) }
          def body_was; end

          sig { void }
          def body_will_change!; end
      RUBY

      output = rbi_for(files)
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { void }
        def restore_body!; end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { returns([T.untyped, T.untyped]) }
        def saved_change_to_body; end

        sig { returns(T::Boolean) }
        def saved_change_to_body?; end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { returns(T::Boolean) }
        def will_save_change_to_body?; end
      RUBY
      expect(output).to(include(expected))
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

        sig { params(value: ::String).returns(::String) }
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
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { returns([T.nilable(::String), T.nilable(::String)]) }
        def saved_change_to_body; end

        sig { returns(T::Boolean) }
        def saved_change_to_body?; end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { returns([::String, ::String]) }
        def saved_change_to_title; end

        sig { returns(T::Boolean) }
        def saved_change_to_title?; end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { returns(::String) }
        def title; end

        sig { params(value: ::String).returns(::String) }
        def title=(value); end

        sig { returns(T::Boolean) }
        def title?; end

        sig { returns(::String) }
        def title_before_last_save; end

        sig { returns(T.untyped) }
        def title_before_type_cast; end

        sig { returns(T::Boolean) }
        def title_came_from_user?; end

        sig { returns([::String, ::String]) }
        def title_change; end

        sig { returns([::String, ::String]) }
        def title_change_to_be_saved; end

        sig { returns(T::Boolean) }
        def title_changed?; end

        sig { returns(::String) }
        def title_in_database; end

        sig { returns([::String, ::String]) }
        def title_previous_change; end

        sig { returns(T::Boolean) }
        def title_previously_changed?; end

        sig { returns(::String) }
        def title_previously_was; end

        sig { returns(::String) }
        def title_was; end

        sig { void }
        def title_will_change!; end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { returns(T.nilable(::DateTime)) }
        def created_at_in_database; end

        sig { returns([T.nilable(::DateTime), T.nilable(::DateTime)]) }
        def created_at_previous_change; end
      RUBY

      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { returns(T.nilable(::DateTime)) }
        def updated_at_in_database; end

        sig { returns([T.nilable(::DateTime), T.nilable(::DateTime)]) }
        def updated_at_previous_change; end
      RUBY

      expect(output).to(include(expected))
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
                t.integer :column1
                t.string :column2
                t.date :column3
                t.decimal :column4
                t.float :column5
                t.boolean :column6
                t.datetime :column7
              end
            end
          end
        RUBY
      }

      expected = indented(<<~RUBY, 2)
        sig { params(value: ::Integer).returns(::Integer) }
        def column1=(value); end
      RUBY

      output = rbi_for(files)
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { params(value: ::String).returns(::String) }
        def column2=(value); end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { params(value: ::Date).returns(::Date) }
        def column3=(value); end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { params(value: ::BigDecimal).returns(::BigDecimal) }
        def column4=(value); end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { params(value: ::Float).returns(::Float) }
        def column5=(value); end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { params(value: T::Boolean).returns(T::Boolean) }
        def column6=(value); end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { params(value: ::DateTime).returns(::DateTime) }
        def column7=(value); end
      RUBY
      expect(output).to(include(expected))
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
                t.timestamp :column1
                t.datetime :column2
                t.time :column3
              end
            end
          end
        RUBY
      }

      expected = indented(<<~RUBY, 2)
        sig { params(value: ::ActiveSupport::TimeWithZone).returns(::ActiveSupport::TimeWithZone) }
        def column1=(value); end
      RUBY

      output = rbi_for(files)
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { params(value: ::ActiveSupport::TimeWithZone).returns(::ActiveSupport::TimeWithZone) }
        def column2=(value); end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { params(value: ::ActiveSupport::TimeWithZone).returns(::ActiveSupport::TimeWithZone) }
        def column3=(value); end
      RUBY
      expect(output).to(include(expected))
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
          sig { returns(T.untyped) }
          def author; end

          sig { params(value: T.untyped).returns(T.untyped) }
          def author=(value); end

          sig { returns(T::Boolean) }
          def author?; end

          sig { returns(T.untyped) }
          def author_before_last_save; end

          sig { returns(T.untyped) }
          def author_before_type_cast; end

          sig { returns(T::Boolean) }
          def author_came_from_user?; end

          sig { returns([T.untyped, T.untyped]) }
          def author_change; end

          sig { returns([T.untyped, T.untyped]) }
          def author_change_to_be_saved; end

          sig { returns(T::Boolean) }
          def author_changed?; end

          sig { returns(T.untyped) }
          def author_in_database; end

          sig { returns([T.untyped, T.untyped]) }
          def author_previous_change; end

          sig { returns(T::Boolean) }
          def author_previously_changed?; end

          sig { returns(T.untyped) }
          def author_was; end

          sig { void }
          def author_will_change!; end
      RUBY

      output = rbi_for(files)
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { void }
        def restore_author!; end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { returns([T.untyped, T.untyped]) }
        def saved_change_to_author; end

        sig { returns(T::Boolean) }
        def saved_change_to_author?; end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { returns(T::Boolean) }
        def will_save_change_to_author?; end
      RUBY
      expect(output).to(include(expected))
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

          sig { params(value: ::String).returns(::String) }
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
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { void }
        def restore_body!; end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { returns([T.nilable(::String), T.nilable(::String)]) }
        def saved_change_to_body; end

        sig { returns(T::Boolean) }
        def saved_change_to_body?; end
      RUBY
      expect(output).to(include(expected))

      expected = indented(<<~RUBY, 2)
        sig { returns(T::Boolean) }
        def will_save_change_to_body?; end
      RUBY
      expect(output).to(include(expected))
    end
  end
end
