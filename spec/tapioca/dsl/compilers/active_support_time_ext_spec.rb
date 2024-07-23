# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveSupportTimeExtSpec < ::DslSpec
        sig { void }
        def before_setup
          require "active_support/core_ext/time"
        end

        describe "Tapioca::Dsl::Compilers::ActiveSupportTimeExt" do
          describe "gather_constants" do
            it "gathers only `Time` as a constant" do
              assert_equal(["Time"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates a Time.current that returns Time if Time.zone isn't defined" do
              expected = <<~RBI
                # typed: strong

                class Time
                  class << self
                    sig { returns(::Time) }
                    def current; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Time))
            end

            it "generates a Time.current that returns ActiveSupport::TimeWithZone if Time.zone is defined" do
              add_ruby_file("time_zone.rb", <<~RUBY)
                Time.zone = "UTC"
              RUBY

              expected = <<~RBI
                # typed: strong

                class Time
                  class << self
                    sig { returns(::ActiveSupport::TimeWithZone) }
                    def current; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Time))
            end
          end
        end
      end
    end
  end
end
