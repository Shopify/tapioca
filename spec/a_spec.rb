# typed: true
# frozen_string_literal: true

require "spec_helper"

class MyTest < Minitest::Spec
  it "is able to return a value" do
    mock = mock()
    mock.expects(:foo).returns(:bar)
    assert_equal :bar, mock.foo
  end
end
