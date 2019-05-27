# frozen_string_literal: true

require "test_helper"

class TapiocaTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil(::Tapioca::VERSION)
  end
end
