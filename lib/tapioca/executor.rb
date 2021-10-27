# typed: strict
# frozen_string_literal: true

require "etc"

module Tapioca
  class Executor
    MINIMUM_ITEMS_PER_WORKER = T.let(2, Integer)
    extend T::Sig

    sig { params(queue: T::Array[T.untyped], number_of_workers: T.nilable(Integer)).void }
    def initialize(queue, number_of_workers: nil)
      @queue = queue

      # Forking workers is expensive and not worth it for a low number of gems. Here we assign the number of workers to
      # be the minimum between the number of available processors (max) or the number of workers to make sure that each
      # one has at least 4 items to process
      @number_of_workers = T.let(
        number_of_workers || [Etc.nprocessors, (queue.length.to_f / MINIMUM_ITEMS_PER_WORKER).ceil].min,
        Integer
      )

      # The number of items that will be processed per worker, so that we can split the queue into groups and assign
      # them to each one of the workers
      @items_per_worker = T.let((queue.length.to_f / @number_of_workers).ceil, Integer)
    end

    sig { params(block: T.proc.params(item: T.untyped).void).void }
    def run_in_parallel(&block)
      # If we only have one worker selected, it's not worth forking, just run sequentially
      if @number_of_workers == 1
        block.call(@queue.shift) until @queue.empty?
        return
      end

      # If we have more than one worker, fork the pool by shifting the expected number of items per worker from the
      # queue
      workers = (0...@number_of_workers).map do
        items = @queue.shift(@items_per_worker)

        fork { block.call(items.shift) until items.empty? }
      end

      # Wait until all the workers finish
      workers.each { |pid| Process.waitpid(pid) }
    end
  end
end
