# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class ExecutorSpec < Minitest::Spec
    before do
      @queue = T.let((0...8).to_a, T::Array[Integer])
      @executor = T.let(Executor.new(@queue), Executor)
    end

    it "splits the queue into a group per worker" do
      received_numbers = []

      @executor.run_in_parallel do |number|
        received_numbers << number
      end

      assert_equal(@queue.length, received_numbers.length)
      assert_equal(@queue, received_numbers.sort)
    end
  end
end
