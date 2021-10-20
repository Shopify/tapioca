# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::ActiveRecordFixturesSpec < DslSpec
  describe("#initialize") do
    it("gathers only the ActiveSupport::TestCase base class") do
      add_ruby_file("post_test.rb", <<~RUBY)
        class PostTest < ActiveSupport::TestCase
        end

        class User
        end
      RUBY

      assert_equal(["ActiveSupport::TestCase"], gathered_constants)
      assert_empty(generated_errors)
    end
  end

  describe("#decorate") do
    before do
      require "active_record"
      require "rails"

      define_fake_rails_app
    end

    it("does nothing if there are no fixtures") do
      expected = <<~RBI
        # typed: strong
      RBI

      assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
      assert_empty(generated_errors)
    end

    it("generates methods for fixtures") do
      add_content_file("test/fixtures/posts.yml", <<~YAML)
        super_post:
          title: An incredible Ruby post
          author: Johnny Developer
          created_at: 2021-09-08 11:00:00
          updated_at: 2021-09-08 11:00:00
      YAML

      expected = <<~RBI
        # typed: strong

        class ActiveSupport::TestCase
          sig { params(fixture_names: Symbol).returns(T.untyped) }
          def posts(*fixture_names); end
        end
      RBI

      assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
      assert_empty(generated_errors)
    end

    it("generates methods for fixtures from multiple sources") do
      add_content_file("test/fixtures/posts.yml", <<~YAML)
        super_post:
          title: An incredible Ruby post
          author: Johnny Developer
          created_at: 2021-09-08 11:00:00
          updated_at: 2021-09-08 11:00:00
      YAML

      add_content_file("test/fixtures/users.yml", <<~YAML)
        customer:
          first_name: John
          last_name: Doe
          created_at: 2021-09-08 11:00:00
          updated_at: 2021-09-08 11:00:00
      YAML

      expected = <<~RBI
        # typed: strong

        class ActiveSupport::TestCase
          sig { params(fixture_names: Symbol).returns(T.untyped) }
          def posts(*fixture_names); end

          sig { params(fixture_names: Symbol).returns(T.untyped) }
          def users(*fixture_names); end
        end
      RBI

      assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
      assert_empty(generated_errors)
    end
  end

  private

  sig { void }
  def define_fake_rails_app
    base_folder = Pathname.new(tmp_path("lib"))

    config_class = Struct.new(:root)
    config = config_class.new(base_folder)
    app_class = Struct.new(:config)
    Rails.application = app_class.new(config)
  end
end
