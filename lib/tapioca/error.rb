# typed: strict
# frozen_string_literal: true

module Tapioca
  class Error < StandardError
    extend T::Sig

    sig { returns(T.nilable(Class)) }
    attr_reader :generator

    sig { returns(T.nilable(String)) }
    attr_reader :help_message

    sig do
      params(
        msg: String,
        generator: Class,
        help_message: T.nilable(String),
      ).void
    end
    def initialize(msg, generator, help_message = nil)
      @generator = generator
      @help_message = help_message

      super(msg)
    end

    sig { returns(T.nilable(String)) }
    def exception_location
      "#{file_path}:#{line_number}"
    end

    sig { params(with_backtrace: T::Boolean).returns(String) }
    def formatted_message(with_backtrace: false)
      output = String.new("#{exception_location}: #{generator}\n")
      output << "  #{help_message}\n" unless help_message.nil?
      output << "  #{T.must(backtrace).join("\n  ")}\n" if with_backtrace
      output
    end

    private

    sig { returns(T::Array[String]) }
    def file_info
      full_message.split(":").take(2)
    end

    sig { returns(String) }
    def line_number
      T.must(file_info.last)
    end

    sig { returns(String) }
    def file_path
      file = T.must(file_info.first)
      Pathname.new(file).to_s
    end
  end
end
