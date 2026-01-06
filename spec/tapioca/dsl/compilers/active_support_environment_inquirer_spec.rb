# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveSupportEnvironmentInquirerSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveSupportEnvironmentInquirer" do
          describe "without a Rails app" do
            it "gathers nothing if not in a Rails application" do
              add_default_environment_files

              assert_empty(gathered_constants)
            end
          end

          describe "with a Rails app" do
            before do
              require "rails"
              Tapioca::RailsSpecHelper.define_fake_rails_app(tmp_path("lib"))
              add_default_environment_files
            end

            describe "gather_constants" do
              it "gathers only `ActiveSupport::EnvironmentInquirer` as a constant" do
                assert_equal(["ActiveSupport::EnvironmentInquirer"], gathered_constants)
              end
            end

            describe "decorate" do
              it "generates nothing if there are only default environments" do
                expected = <<~RBI
                  # typed: strong
                RBI

                assert_equal(expected, rbi_for("ActiveSupport::EnvironmentInquirer"))
              end

              it "generates boolean predicate methods for non-default environments" do
                add_content_file("config/environments/staging.rb", "")
                add_content_file("config/environments/demo.rb", "")

                expected = <<~RBI
                  # typed: strong

                  class ActiveSupport::EnvironmentInquirer
                    sig { returns(T::Boolean) }
                    def demo?; end

                    sig { returns(T::Boolean) }
                    def staging?; end
                  end
                RBI

                assert_equal(expected, rbi_for("ActiveSupport::EnvironmentInquirer"))
              end
            end
          end
        end

        private

        #: -> void
        def add_default_environment_files
          add_content_file("config/environments/development.rb", "")
          add_content_file("config/environments/test.rb", "")
          add_content_file("config/environments/production.rb", "")
        end
      end
    end
  end
end
