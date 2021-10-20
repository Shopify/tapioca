# typed: strict
# frozen_string_literal: true

require "pathname"

class StandardError
  extend T::Sig

  sig { returns(T.nilable(String)) }
  attr_accessor :explanation

  sig { returns(T::Array[String]) }
  def extracted_file_info
    full_message.split(":").take(2)
  end

  sig { returns(String) }
  def filename
    filepath = T.must(extracted_file_info.first)
    filepath = Pathname.new(filepath)
    filepath.to_s
  end

  sig { returns(String) }
  def line_no
    T.must(extracted_file_info.last)
  end

  sig { returns(String) }
  def formatted_exception_loc
    "#{filename}:#{line_no}"
  end

  sig { returns(String) }
  def formatted_message
    output = String.new("#{formatted_exception_loc}: #{self.class.name}")
    output << "\n  #{explanation}" unless explanation.nil?
    output << "\n  #{T.must(backtrace).take(5).join("\n  ")}" unless backtrace.nil?
    output
  end
end
