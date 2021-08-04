# typed: strict
# frozen_string_literal: true

require "spec_helper"
require "active_record"

class Tapioca::Compilers::Dsl::ActiveStorageSpec < DslSpec
  describe("#initialize") do
    it("gathers no constants if there are no ActiveRecord subclasses") do
      assert_empty(gathered_constants)
    end
  end

  describe("#decorate") do
    before(:each) do
      require "active_storage"
      require "active_storage/attached"
      require "active_storage/reflection"
      require "active_record"
      ActiveRecord::Base.include(ActiveStorage::Attached::Model)
      ActiveRecord::Base.include(ActiveStorage::Reflection::ActiveRecordExtensions)
      ActiveRecord::Reflection.singleton_class.prepend(ActiveStorage::Reflection::ReflectionExtension)

      ::ActiveRecord::Base.establish_connection(
        adapter: "sqlite3",
        database: ":memory:"
      )
    end

    it("generates RBI file for has_one_attached single association") do
      add_ruby_file("schema.rb", <<~RUBY)
        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Schema.define do
            create_table :users
          end
        end
      RUBY
      add_ruby_file("user.rb", <<~RUBY)
        class User < ActiveRecord::Base
          has_one_attached :avatar
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class User
          include GeneratedActiveStorageMethods

          module GeneratedActiveStorageMethods
            sig { returns(T.nilable(ActiveStorage::Attachment)) }
            def avatar; end

            sig { params(value: T.nilable(ActiveStorage::Atachment)).void }
            def avatar=(value); end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:User))
    end
  end

  sig { returns(T::Array[String]) }
  def gathered_constants
    T.unsafe(self).subject.processable_constants.map(&:name).sort
  end
end
