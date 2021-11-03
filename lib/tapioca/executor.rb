# typed: strict
# frozen_string_literal: true

require "etc"

module Tapioca
  class Executor
    MINIMUM_ITEMS_PER_WORKER = T.let(2, Integer)

    # The separator is used to divide Base64 values, because `-` is not a valid Base64 character
    SEPARATOR = T.let("-", String)
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

    sig do
      type_parameters(:T).params(
        block: T.proc.params(item: T.untyped).returns(T.type_parameter(:T))
      ).returns(T.nilable(T::Array[T.type_parameter(:T)]))
    end
    def run_in_parallel(&block)
      # If we only have one worker selected, it's not worth forking, just run sequentially
      return @queue.map { |item| block.call(item) }.compact if @number_of_workers == 1

      # Create an IO pipe to communicate the return value of the parallelized block back from the workers to the main
      # process. It's important to only create pipes if we're running with more than one worker, otherwise the tests
      # fail with a "too many open files" error.
      read, write = IO.pipe

      # If we have more than one worker, fork the pool by shifting the expected number of items per worker from the
      # queue
      workers = (0...@number_of_workers).map do
        items = @queue.shift(@items_per_worker)

        fork do
          read.close
          result = items.map { |item| block.call(item) }.compact

          # We mapped the result of invoking the parallelized block into an array. In order to return the array from the
          # worker back to the main process, we encode it in Base64, append a separator in the beginning and write it to
          # the pipe. The separator helps us split the results that are coming from the multiple workers. It looks
          # something like this:
          # -absbasd13231-asbasd123123
          # ^^^^^^^^^^^^^ encoded result from first worker
          #              ^^^^^^^^^^^^^ encoded result from second worker
          packed = [Marshal.dump(result)].pack("m")
          write.puts("#{SEPARATOR}#{packed}") unless result.empty?
          write.close
        end
      end

      write.close
      result = read.read
      read.close

      # Wait until all the workers finish. Notice that waiting for the PIDs can only happen after we read and close the
      # pipe or else we may end up in a condition where writing to the pipe hangs indefinitely
      workers.each { |pid| Process.waitpid(pid) }

      # Here we need to do the opposite of what the workers are doing. We read from the pipe a Base64 string with
      # separators e.g.: -absbasd13231-asbasd123123 and need to get back the Ruby object from it. In order, we
      # 1. split the results based on the separator
      # 2. drop the first item of the split array. It will always be an empty string since even the first worker has the
      # appended separator
      # 3. Map back the objects by decoding them from Base64 and loading with Marshal
      if result
        result
          .split(SEPARATOR)
          .drop(1)
          .flat_map { |item| T.unsafe(Marshal.load(item.unpack1("m"))) }
      end
    end
  end
end
