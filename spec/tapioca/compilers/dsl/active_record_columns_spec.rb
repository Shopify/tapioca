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

    def indented(str, indent)
      str.lines.map! do |line|
        next line if line.chomp.empty?
        " " * indent + line
      end.join
    end

    it("generates RBI file for class without custom attributes") do
      files = {
        "file.rb" => <<~RUBY,
          class Post < ActiveRecord::Base
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

    it("generates RBI file that includes custom attributes") do
      files = {
        "file.rb" => <<~RUBY,
          class Post < ActiveRecord::Base
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

    # TODO: Split this test. Ugly.
    # it("generates RBI that includes all dsl methods") do
    #   files = {
    #     "file.rb" => <<~RUBY,
    #       class Post < ActiveRecord::Base
    #       end
    #     RUBY

    #     "schema.rb" => <<~RUBY
    #       ActiveRecord::Schema.define do
    #         create_table :posts do |t|
    #           t.string :body
    #         end
    #       end
    #    RUBY
    #   }

    #   expected = <<~RUBY
    #     # typed: strong
    #     class Post
    #       include Post::GeneratedAttributeMethods
    #     end

    #     module Post::GeneratedAttributeMethods
    #       sig { returns(T.nilable(::String)) }
    #       def body; end

    #       sig { params(value: ::String).returns(::String) }
    #       def body=(value); end

    #       sig { returns(T::Boolean) }
    #       def body?; end

    #       sig { returns(T.nilable(::String)) }
    #       def body_before_last_save; end

    #       sig { returns(T.untyped) }
    #       def body_before_type_cast; end

    #       sig { returns(T::Boolean) }
    #       def body_came_from_user?; end

    #       sig { returns([T.nilable(::String), T.nilable(::String)]) }
    #       def body_change; end

    #       sig { returns([T.nilable(::String), T.nilable(::String)]) }
    #       def body_change_to_be_saved; end

    #       sig { returns(T::Boolean) }
    #       def body_changed?; end

    #       sig { returns(T.nilable(::String)) }
    #       def body_in_database; end

    #       sig { returns([T.nilable(::String), T.nilable(::String)]) }
    #       def body_previous_change; end

    #       sig { returns(T::Boolean) }
    #       def body_previously_changed?; end

    #       sig { returns(T.nilable(::String)) }
    #       def body_previously_was; end

    #       sig { returns(T.nilable(::String)) }
    #       def body_was; end

    #       sig { void }
    #       def body_will_change!; end

    #       sig { returns(T.nilable(::Integer)) }
    #       def id; end

    #       sig { params(value: ::Integer).returns(::Integer) }
    #       def id=(value); end

    #       sig { returns(T::Boolean) }
    #       def id?; end

    #       sig { returns(T.nilable(::Integer)) }
    #       def id_before_last_save; end

    #       sig { returns(T.untyped) }
    #       def id_before_type_cast; end

    #       sig { returns(T::Boolean) }
    #       def id_came_from_user?; end

    #       sig { returns([T.nilable(::Integer), T.nilable(::Integer)]) }
    #       def id_change; end

    #       sig { returns([T.nilable(::Integer), T.nilable(::Integer)]) }
    #       def id_change_to_be_saved; end

    #       sig { returns(T::Boolean) }
    #       def id_changed?; end

    #       sig { returns(T.nilable(::Integer)) }
    #       def id_in_database; end

    #       sig { returns([T.nilable(::Integer), T.nilable(::Integer)]) }
    #       def id_previous_change; end

    #       sig { returns(T::Boolean) }
    #       def id_previously_changed?; end

    #       sig { returns(T.nilable(::Integer)) }
    #       def id_previously_was; end

    #       sig { returns(T.nilable(::Integer)) }
    #       def id_was; end

    #       sig { void }
    #       def id_will_change!; end

    #       sig { void }
    #       def restore_body!; end

    #       sig { void }
    #       def restore_id!; end

    #       sig { returns([T.nilable(::String), T.nilable(::String)]) }
    #       def saved_change_to_body; end

    #       sig { returns(T::Boolean) }
    #       def saved_change_to_body?; end

    #       sig { returns([T.nilable(::Integer), T.nilable(::Integer)]) }
    #       def saved_change_to_id; end

    #       sig { returns(T::Boolean) }
    #       def saved_change_to_id?; end

    #       sig { returns(T::Boolean) }
    #       def will_save_change_to_body?; end

    #       sig { returns(T::Boolean) }
    #       def will_save_change_to_id?; end
    #     end
    #   RUBY

    #   expect(rbi_for(files)).to(eq(expected))
    # end
  end
end
