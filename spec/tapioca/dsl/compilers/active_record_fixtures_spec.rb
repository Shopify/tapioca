# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveRecordFixturesSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveRecordFixtures" do
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
              require "active_record"
              require "rails"

              define_fake_rails_app
            end

            it "gathers only the ActiveSupport::TestCase base class" do
              require "active_record"
              require "rails"

              define_fake_rails_app

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

            it "generates methods for fixtures" do
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
                  sig { params(fixture_names: T.any(String, Symbol)).returns(T.untyped) }
                  def posts(*fixture_names); end
                end
              RBI

              assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
            end

            it "generates methods for fixtures from multiple sources" do
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
                  sig { params(fixture_names: T.any(String, Symbol)).returns(T.untyped) }
                  def posts(*fixture_names); end

                  sig { params(fixture_names: T.any(String, Symbol)).returns(T.untyped) }
                  def users(*fixture_names); end
                end
              RBI

              assert_equal(expected, rbi_for("ActiveSupport::TestCase"))
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
