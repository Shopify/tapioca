# typed: strict
# frozen_string_literal: true

module Tapioca
  class Executor
    extend T::Sig

    MINIMUM_ITEMS_PER_WORKER = 2 #: Integer

    #: (Array[untyped] queue, ?number_of_workers: Integer?) -> void
    def initialize(queue, number_of_workers: nil)
      @queue = queue

      # Forking workers is expensive and not worth it for a low number of gems. Here we assign the number of workers to
      # be the minimum between the number of available processors (max) or the number of workers to make sure that each
      # one has at least 4 items to process
      @number_of_workers = number_of_workers ||
        [max_processors, (queue.length.to_f / MINIMUM_ITEMS_PER_WORKER).ceil].min #: Integer
    end

    #: [T] { (untyped item) -> T } -> Array[T]
    def run_in_parallel(&block)
      # To have the parallel gem run jobs in the parent process, you must pass 0 as the number of processes
      number_of_processes = @number_of_workers == 1 ? 0 : @number_of_workers
      Parallel.map(@queue, { in_processes: number_of_processes }, &block)
    end

    private

    #: -> Integer
    def max_processors
      env_max_processors = ENV["PARALLEL_PROCESSOR_COUNT"].to_i
      env_max_processors.positive? ? env_max_processors : Etc.nprocessors
    end
  end
end
