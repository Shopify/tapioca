# typed: true
# frozen_string_literal: true

class SpecReporter < Minitest::Reporters::SpecReporter
  def record(test)
    # Trim leading "test_dddd_" and replace it with "it "
    test.name.gsub!(/^test_\d{4}_/, "it ")
    super
  end
end
