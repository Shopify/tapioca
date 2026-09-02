# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordFixturesSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveRecordFixtures" do
          #: -> void
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

              Tapioca::RailsSpecHelper.define_fake_rails_app(tmp_path("lib"))
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

            it "makes fixture class methods available when there are no fixtures" do
              expected = <<~RBI
                # typed: strong

                class ActiveSupport::TestCase
                  include ActiveRecord::TestFixtures
                end
              RBI

              generated_rbi = rbi_for("ActiveSupport::TestCase")
              dependencies_rbi = add_content_file("dependencies.rbi", <<~RBI)
                # typed: true

                module ActiveRecord::TestFixtures
                  mixes_in_class_methods ::ActiveRecord::TestFixtures::ClassMethods
                end

                module ActiveRecord::TestFixtures::ClassMethods
                  def fixtures(*fixture_set_names); end
                end

                class ActiveSupport::TestCase; end
              RBI
              generated_rbi_file = add_content_file("generated.rbi", generated_rbi)
              test_file = add_content_file("test_case.rb", <<~RUBY)
                # typed: true

                class PostTest < ActiveSupport::TestCase
                  fixtures :all
                end
              RUBY

              result = context.sorbet("--no-config", dependencies_rbi, generated_rbi_file, test_file)

              assert(result.status, result.err)
              assert_equal(expected, generated_rbi)
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
                  include ActiveRecord::TestFixtures

                  sig { returns(T::Array[Post]) }
                  sig { params(fixture_name: T.any(String, Symbol)).returns(Post) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: T.any(String, Symbol)).returns(T::Array[Post]) }
                  def posts(fixture_name = nil, *other_fixtures); end
                end
              RBI

              assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
            end

            it "generates only the include if no fixture has an associated model" do
              add_content_file("test/fixtures/serialized_data.yml", <<~YAML)
                ---
                field1: 123
                name: Hello
              YAML

              expected = <<~RBI
                # typed: strong

                class ActiveSupport::TestCase
                  include ActiveRecord::TestFixtures
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
                  include ActiveRecord::TestFixtures

                  sig { returns(T::Array[Post]) }
                  sig { params(fixture_name: T.any(String, Symbol)).returns(Post) }
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
                  include ActiveRecord::TestFixtures

                  sig { returns(T::Array[Blog::Post]) }
                  sig { params(fixture_name: T.any(String, Symbol)).returns(Blog::Post) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: T.any(String, Symbol)).returns(T::Array[Blog::Post]) }
                  def blog_posts(fixture_name = nil, *other_fixtures); end

                  sig { returns(T::Array[User]) }
                  sig { params(fixture_name: T.any(String, Symbol)).returns(User) }
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
                  include ActiveRecord::TestFixtures

                  sig { returns(T::Array[Post]) }
                  sig { params(fixture_name: T.any(String, Symbol)).returns(Post) }
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
                  include ActiveRecord::TestFixtures

                  sig { returns(T::Array[T.untyped]) }
                  sig { params(fixture_name: T.any(String, Symbol)).returns(T.untyped) }
                  sig { params(fixture_name: T.any(String, Symbol), other_fixtures: T.any(String, Symbol)).returns(T::Array[T.untyped]) }
                  def posts(fixture_name = nil, *other_fixtures); end
                end
              RBI

              assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
            end

            it "generates only the include for file fixtures" do
              add_content_file("test/fixtures/files/posts.yml", <<~YAML)
                super_post:
                  title: An incredible Ruby post
                  author: Johnny Developer
                  created_at: 2021-09-08 11:00:00
                  updated_at: 2021-09-08 11:00:00
              YAML

              expected = <<~RBI
                # typed: strong

                class ActiveSupport::TestCase
                  include ActiveRecord::TestFixtures
                end
              RBI

              assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
            end
          end
        end
      end
    end
  end
end
