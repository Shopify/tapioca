# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class ErrorHandlerSpec < ::Minitest::HooksSpec
    class TestClass
      extend T::Sig

      class DummyError < Tapioca::Error; end

      sig { void }
      def raise_tapioca_error
        raise DummyError, "fake"
      end
    end

    before do
      add_error_to_buffer
    end

    after do
      Tapioca::ErrorHandler.clear
    end

    it ".add inserts errors into the error buffer" do
      assert_equal Tapioca::ErrorHandler::ERRORS.size, 1
    end

    it ".remove removes errors from the error buffer" do
      assert_equal Tapioca::ErrorHandler::ERRORS.size, 1

      Tapioca::ErrorHandler.remove

      assert_predicate Tapioca::ErrorHandler::ERRORS, :empty?
    end

    it ".clear removes ALL errors from the error buffer" do
      add_error_to_buffer

      assert_equal Tapioca::ErrorHandler::ERRORS.size, 2

      Tapioca::ErrorHandler.clear

      assert_predicate Tapioca::ErrorHandler::ERRORS, :empty?
    end

    it ".formatted_messages returns an array of properly formatted messages" do
      error_message = Tapioca::ErrorHandler.formatted_messages.first

      assert_includes error_message, <<~RUBY
        #{__FILE__}:15: Tapioca::ErrorHandlerSpec::TestClass::DummyError
      RUBY
    end

    private

    sig { void }
    def add_error_to_buffer
      error = assert_raises(Tapioca::Error) do
        TestClass.new.raise_tapioca_error
      end

      Tapioca::ErrorHandler.add(error)
    end
  end
end
