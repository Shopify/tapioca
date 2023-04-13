# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class ExecutorSpec < Minitest::Spec
    describe "Tapioca::Executor" do
      before do
        @queue = T.let((0...8).to_a, T::Array[Integer])
        @executor = T.let(Executor.new(@queue), Executor)
      end

      it "runs sequentially when the number of workers is one" do
        executor = Executor.new(@queue, number_of_workers: 1)
        parent_pid = Process.pid

        executor.run_in_parallel do
          assert_equal(parent_pid, Process.pid)
        end
      end

      it "forks different processes if number of workers is greater than one" do
        executor = Executor.new(@queue, number_of_workers: 4)
        parent_pid = Process.pid

        executor.run_in_parallel do
          refute_equal(parent_pid, Process.pid)
        end
      end

      it "can return a value from the parallelized block" do
        queue = @queue.dup
        executor = Executor.new(@queue, number_of_workers: 4)
        result = executor.run_in_parallel { |number| number }

        assert_equal(queue, result.sort)
      end

      it "limits_parallel_work_to_nprocessors_by_default" do
        ENV["PARALLEL_PROCESSOR_COUNT"] = nil
        nprocessors = 3

        T.unsafe(Etc).stub(:nprocessors, -> { nprocessors }) do
          T.unsafe(Parallel).stub(:map, assert_parallel_count(nprocessors)) do
            executor = Executor.new(@queue)
            executor.run_in_parallel {}
          end
        end
      end

      it "limits_parallel_work_to_PARALLEL_PROCESS_COUNT" do
        env_limit = 2
        ENV["PARALLEL_PROCESSOR_COUNT"] = env_limit.to_s

        T.unsafe(Etc).stub(:nprocessors, -> { env_limit + 1 }) do
          T.unsafe(Parallel).stub(:map, assert_parallel_count(env_limit)) do
            executor = Executor.new(@queue)
            executor.run_in_parallel {}
          end
        end
      end

      sig do
        params(expected_count: Integer).returns(T.proc.params(
          _arg1: T.untyped,
          _arg2: T.untyped,
        ).returns(T::Array[Integer]))
      end
      def assert_parallel_count(expected_count)
        ->(_, options) {
          assert_equal(expected_count, options[:in_processes])
          []
        }
      end
    end
  end
end
