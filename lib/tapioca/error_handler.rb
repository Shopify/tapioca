# typed: strict
# frozen_string_literal: true

require "tapioca/ruby_ext/standard_error"

module Tapioca
  class Error < StandardError; end

  class ParsingError < Error; end

  class CompilationError < Error; end

  class ErrorHandler
    ERRORS = T.let([], T::Array[Tapioca::Error])

    class << self
      extend T::Sig

      sig { params(error: Tapioca::Error).void }
      def add(error)
        ERRORS.push(error)
      end

      sig { returns(T.nilable(Tapioca::Error)) }
      def remove
        ERRORS.pop
      end

      sig { void }
      def clear
        remove until ERRORS.empty?
      end

      sig { returns(T::Array[String]) }
      def formatted_messages
        buf = []
        ERRORS.each do |error|
          buf << error.formatted_message
        end
        buf
      end
    end
  end
end
