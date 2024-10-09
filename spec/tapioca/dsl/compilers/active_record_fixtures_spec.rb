# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordFixturesSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveRecordFixtures" do
          sig { void }
          def before_setup
            require "active_record"
            require "active_record/fixtures"
          end

          describe "without a Rails app" do
            it "gathers nothing if not in a Rails application" do
              add_ruby_file("post_test.rb", <<~RUBY)
                class PostTest < ActiveSupport::TestCase
                end

                class User
                end
              RUBY

              assert_empty(gathered_constants)
            end
          end

          describe "with a Rails app" do
            before do
              require "rails"

              define_fake_rails_app
            end

            it "gathers only the ActiveSupport::TestCase base class" do
              add_ruby_file("post_test.rb", <<~RUBY)
                class PostTest < ActiveSupport::TestCase
                end

                class User
                end
              RUBY

              assert_equal(["ActiveSupport::TestCase"], gathered_constants)
            end

            it "does nothing if there are no fixtures" do
              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
            end

            it "ignores fixtures that do not have an associated model" do
              add_content_file("test/fixtures/serialized_data.yml", <<~YAML)
                ---
                field1: 123
                name: Hello
              YAML

              add_content_file("test/fixtures/posts.yml", <<~YAML)
                super_post:
                  title: An incredible Ruby post
                  author: Johnny Developer
                  created_at: 2021-09-08 11:00:00
                  updated_at: 2021-09-08 11:00:00
              YAML

              add_ruby_file("test_models.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class ActiveSupport::TestCase
                  sig { params(fixture_name: NilClass, other_fixtures: NilClass).returns(T::Array[Post]) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: NilClass).returns(Post) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: T.any(String, Symbol)).returns(T::Array[Post]) }
                  def posts(fixture_name = nil, *other_fixtures); end
                end
              RBI

              assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
            end

            it "generates methods for fixtures" do
              add_content_file("test/fixtures/posts.yml", <<~YAML)
                super_post:
                  title: An incredible Ruby post
                  author: Johnny Developer
                  created_at: 2021-09-08 11:00:00
                  updated_at: 2021-09-08 11:00:00
              YAML

              add_ruby_file("test_models.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class ActiveSupport::TestCase
                  sig { params(fixture_name: NilClass, other_fixtures: NilClass).returns(T::Array[Post]) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: NilClass).returns(Post) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: T.any(String, Symbol)).returns(T::Array[Post]) }
                  def posts(fixture_name = nil, *other_fixtures); end
                end
              RBI

              assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
            end

            it "generates methods for fixtures from multiple sources" do
              add_ruby_file("test_models.rb", <<~RUBY)
                module Blog
                  class Post < ActiveRecord::Base
                  end
                end
                class User < ActiveRecord::Base
                end
              RUBY
              add_content_file("test/fixtures/blog/posts.yml", <<~YAML)
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
                  sig { params(fixture_name: NilClass, other_fixtures: NilClass).returns(T::Array[Blog::Post]) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: NilClass).returns(Blog::Post) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: T.any(String, Symbol)).returns(T::Array[Blog::Post]) }
                  def blog_posts(fixture_name = nil, *other_fixtures); end

                  sig { params(fixture_name: NilClass, other_fixtures: NilClass).returns(T::Array[User]) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: NilClass).returns(User) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: T.any(String, Symbol)).returns(T::Array[User]) }
                  def users(fixture_name = nil, *other_fixtures); end
                end
              RBI

              assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
            end

            it "generates methods for fixtures with explicit class name" do
              add_content_file("test/fixtures/posts_with_other_names.yml", <<~YAML)
                _fixture:
                  model_class: Post
                super_post:
                  title: An incredible Ruby post
                  author: Johnny Developer
                  created_at: 2021-09-08 11:00:00
                  updated_at: 2021-09-08 11:00:00
              YAML

              add_ruby_file("test_models.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end
              RUBY

              expected = <<~RBI
                # typed: strong

                class ActiveSupport::TestCase
                  sig { params(fixture_name: NilClass, other_fixtures: NilClass).returns(T::Array[Post]) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: NilClass).returns(Post) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: T.any(String, Symbol)).returns(T::Array[Post]) }
                  def posts_with_other_names(fixture_name = nil, *other_fixtures); end
                end
              RBI

              assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
            end

            it "generates methods for fixtures with a fallback to T.untyped if no matching model exists" do
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
                  sig { params(fixture_name: NilClass, other_fixtures: NilClass).returns(T::Array[T.untyped]) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: NilClass).returns(T.untyped) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: T.any(String, Symbol)).returns(T::Array[T.untyped]) }
                  def posts(fixture_name = nil, *other_fixtures); end
                end
              RBI

              assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
            end

            it "generates no methods for file fixtures" do
              add_content_file("test/fixtures/files/posts.yml", <<~YAML)
                super_post:
                  title: An incredible Ruby post
                  author: Johnny Developer
                  created_at: 2021-09-08 11:00:00
                  updated_at: 2021-09-08 11:00:00
              YAML

              expected = <<~RBI
                # typed: strong
              RBI

              assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
            end
          end

          describe "#handles_path?" do
            it "matches the fixtures path" do
              assert(ActiveRecordFixtures.handles_path?("test/fixtures/posts.yml"))
              assert(ActiveRecordFixtures.handles_path?("test/fixtures/posts.yml.erb"))
              assert(ActiveRecordFixtures.handles_path?("test/fixtures/more/posts.yml"))
              refute(ActiveRecordFixtures.handles_path?("test/fixtures/posts.rb"))
              refute(ActiveRecordFixtures.handles_path?("test/elsewhere/posts.yml"))
            end
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
    end
  end
end
