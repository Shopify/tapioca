# typed: strict
# frozen_string_literal: true

require "etc"

module Tapioca
  class Executor
    extend T::Sig

    MINIMUM_ITEMS_PER_WORKER = T.let(2, Integer)

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

    sig do
      type_parameters(:T).params(
        block: T.proc.params(item: T.untyped).returns(T.type_parameter(:T))
      ).returns(T::Array[T.type_parameter(:T)])
    end
    def run_in_parallel(&block)
      # If we only have one worker selected, it's not worth forking, just run sequentially
      return @queue.map { |item| block.call(item) } if @number_of_workers == 1

      read_pipes = []
      write_pipes = []

      # If we have more than one worker, fork the pool by shifting the expected number of items per worker from the
      # queue
      workers = (0...@number_of_workers).map do
        items = @queue.shift(@items_per_worker)

        # Each worker has their own pair of pipes, so that we can read the result from each worker separately
        read, write = IO.pipe
        read_pipes << read
        write_pipes << write

        fork do
          read.close
          result = items.map { |item| block.call(item) }

          # Pack the result as a Base64 string of the Marshal dump of the array of values returned by the block that we
          # ran in parallel
          packed = [Marshal.dump(result)].pack("m")
          write.puts(packed)
          write.close
        end
      end

      # Close all the write pipes, then read and close from all the read pipes
      write_pipes.each(&:close)
      result = read_pipes.map do |pipe|
        content = pipe.read
        pipe.close
        content
      end

      # Wait until all the workers finish. Notice that waiting for the PIDs can only happen after we read and close the
      # pipe or else we may end up in a condition where writing to the pipe hangs indefinitely
      workers.each { |pid| Process.waitpid(pid) }

      # Decode the value back into the Ruby objects by doing the inverse of what each worker does
      result.flat_map { |item| T.unsafe(Marshal.load(item.unpack1("m"))) }
    end
  end
end
