# typed: true
# frozen_string_literal: true

require "spec_helper"
require "tapioca/error"

module Tapioca
  class WithoutHelp < Tapioca::Generators::Base
    sig { override.void }
    def generate
      raise Tapioca::Error.new("stubbed", self.class)
    end
  end

  class WithHelp < Tapioca::Generators::Base
    sig { override.void }
    def generate
      raise Tapioca::Error.new("stubbed", self.class, "describe solution")
    end
  end

  class ErrorSpec < ::Minitest::Spec
    describe(:exception) do
      describe(:without_help) do
        before(:each) do
          @generator_klass = Tapioca::WithoutHelp.new(default_command: "bin/tapioca dsl")
        end

        it "contains the correct message" do
          error = assert_raises(Tapioca::Error) do
            @generator_klass.generate
          end
          assert_equal(error.message, "stubbed")
        end

        it "contains the correct generator" do
          error = assert_raises(Tapioca::Error) do
            @generator_klass.generate
          end
          assert_equal(error.generator, Tapioca::WithoutHelp)
        end

        it "contains the correct exception_location" do
          error = assert_raises(Tapioca::Error) do
            @generator_klass.generate
          end
          assert_equal(error.exception_location, "#{__FILE__}:11")
        end

        it "does not contain a help_message" do
          error = assert_raises(Tapioca::Error) do
            @generator_klass.generate
          end
          assert_nil(error.help_message)
        end

        it "contains the correct formatted_message without a backtrace" do
          error = assert_raises(Tapioca::Error) do
            @generator_klass.generate
          end
          assert_equal(error.formatted_message, <<~MSG)
            #{__FILE__}:11: Tapioca::WithoutHelp
          MSG
        end

        it "contains the correct formatted_message with a backtrace" do
          error = assert_raises(Tapioca::Error) do
            @generator_klass.generate
          end
          # TODO: This is testing with a backtrace, determine a cleaner way of dealing with this.
          assert_includes(error.formatted_message(with_backtrace: true), <<~MSG)
            #{__FILE__}:11: Tapioca::WithoutHelp
          MSG
        end
      end

      describe(:with_help) do
        before(:each) do
          @generator_klass = Tapioca::WithHelp.new(default_command: "bin/tapioca dsl")
        end

        it "contains the correct message" do
          error = assert_raises(Tapioca::Error) do
            @generator_klass.generate
          end
          assert_equal(error.message, "stubbed")
        end

        it "contains the correct generator" do
          error = assert_raises(Tapioca::Error) do
            @generator_klass.generate
          end
          assert_equal(error.generator, Tapioca::WithHelp)
        end

        it "contains the correct exception_location" do
          error = assert_raises(Tapioca::Error) do
            @generator_klass.generate
          end
          assert_equal(error.exception_location, "#{__FILE__}:18")
        end

        it "contains the correct help_message" do
          error = assert_raises(Tapioca::Error) do
            @generator_klass.generate
          end
          assert_equal(error.help_message, "describe solution")
        end

        it "contains the correct formatted_message without a backtrace" do
          error = assert_raises(Tapioca::Error) do
            @generator_klass.generate
          end
          assert_equal(error.formatted_message, <<~MSG)
            #{__FILE__}:18: Tapioca::WithHelp
              describe solution
          MSG
        end

        it "contains the correct formatted_message with a backtrace" do
          error = assert_raises(Tapioca::Error) do
            @generator_klass.generate
          end
          # TODO: This is testing with a backtrace, determine a cleaner way of dealing with this.
          assert_includes(error.formatted_message(with_backtrace: true), <<~MSG)
            #{__FILE__}:18: Tapioca::WithHelp
              describe solution
          MSG
        end
      end
    end
  end
end
