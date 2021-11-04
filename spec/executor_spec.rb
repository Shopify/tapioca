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

    it "runs sequentially when the number of workers is one" do
      executor = Executor.new(@queue, number_of_workers: 1)
      parent_pid = Process.pid

      executor.run_in_parallel do |_|
        assert_equal(parent_pid, Process.pid)
      end
    end

    it "forks different processes if number of workers is greater than one" do
      executor = Executor.new(@queue, number_of_workers: 4)
      parent_pid = Process.pid

      executor.run_in_parallel do |_|
        refute_equal(parent_pid, Process.pid)
      end
    end

    it "can return a value from the parallelized block" do
      queue = @queue.dup
      executor = Executor.new(@queue, number_of_workers: 4)
      result = executor.run_in_parallel { |number| number }

      assert_equal(queue, result.sort)
    end
  end
end
