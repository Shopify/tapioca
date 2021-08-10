# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveStorageSpec < DslSpec
  before do
    add_ruby_file("require.rb", <<~RUBY)
      require "active_record"
      require "active_storage/attached"
      require "active_storage/reflection"
      ActiveRecord::Base.include(ActiveStorage::Attached::Model)
      ActiveRecord::Base.include(ActiveStorage::Reflection::ActiveRecordExtensions)
      ActiveRecord::Reflection.singleton_class.prepend(ActiveStorage::Reflection::ReflectionExtension)
    RUBY
  end

  describe("#initialize") do
    it("gathers no constants if there are no ActiveRecord classes") do
      assert_empty(gathered_constants)
    end

    it("gathers only ActiveRecord constants with no abstract classes") do
      add_ruby_file("conversation.rb", <<~RUBY)
        class Post < ActiveRecord::Base
        end

        class Product < ActiveRecord::Base
          self.abstract_class = true
        end

        class User
        end
      RUBY

      assert_equal(["Post"], gathered_constants)
    end
  end

  describe("#decorate") do
    it("generates an empty RBI file for ActiveRecord classes with no attachment") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
        end
      RUBY

      expected = <<~RBI
        # typed: strong
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for ActiveRecord classes with an attachment") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          has_one_attached :photo
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          sig { returns(ActiveStorage::Attached::One) }
          def photo; end

          sig { params(attachable: T.untyped).void }
          def photo=(attachable); end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end

    it("generates RBI file for ActiveRecord classes with attachments") do
      add_ruby_file("post.rb", <<~RUBY)
        class Post < ActiveRecord::Base
          has_many_attached :photos
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        class Post
          sig { returns(ActiveStorage::Attached::Many) }
          def photos; end

          sig { params(attachable: T.untyped).void }
          def photos=(attachable); end
        end
      RBI

      assert_equal(expected, rbi_for(:Post))
    end
  end
end
