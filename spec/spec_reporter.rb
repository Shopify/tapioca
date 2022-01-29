# typed: true
# frozen_string_literal: true

class SpecReporter < Minitest::Reporters::SpecReporter
  def before_suite(suite)
    suite.name.split("::").reduce(0) do |padding, name|
      puts pad(name, padding)
      padding + TEST_PADDING
    end
  end

  def record(test)
    # Trim leading "test_dddd_" and replace it with "it "
    test.name.gsub!(/^test_\d{4}_/, "it ")
    @test_padding = test.class_name.split("::").size * TEST_PADDING
    super
  end

  def pad_test(str)
    pad(format("%-#{TEST_SIZE}s", str), @test_padding)
  end
end
