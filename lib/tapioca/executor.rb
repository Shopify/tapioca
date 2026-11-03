# typed: strict
# frozen_string_literal: true

module Tapioca
  class Executor
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
    rescue Parallel::DeadWorker
      raise Tapioca::Error, dead_worker_message
    end

    private

    # A worker that raises sends its exception back to the parent, which re-raises it. `Parallel::DeadWorker` means one
    # exited without doing that: killed (often for running out of memory) or crashed in a native extension, which
    # prints its own crash report to stderr.
    #: -> String
    def dead_worker_message
      message = <<~MESSAGE
        A worker process exited before it finished. Tapioca forks #{@number_of_workers} worker processes, and a worker usually
        dies because the system ran out of memory, or because a native extension crashed in the forked process
        (look above for a crash report, such as `[BUG] Segmentation fault`).

        To do the work in a single process, which shows the error if there is one, run the command again with
        `--workers=1`.
      MESSAGE

      if pg_gssapi_crash_possible?
        message += <<~MESSAGE

          On macOS, a crash in the pg gem while it connects to PostgreSQL comes from libpq trying GSSAPI
          encryption. Turn it off with `PGGSSENCMODE=disable` in the environment, or with
          `gssencmode: disable` in config/database.yml.
        MESSAGE
      end

      message
    end

    # libpq tries GSSAPI encryption on each new connection by default, and on macOS the system's Kerberos library
    # crashes when it's used in a process forked after it was loaded.
    #: -> bool
    def pg_gssapi_crash_possible?
      !!defined?(::PG) && RUBY_PLATFORM.include?("darwin") && ENV["PGGSSENCMODE"].nil?
    end

    #: -> Integer
    def max_processors
      env_max_processors = ENV["PARALLEL_PROCESSOR_COUNT"].to_i
      env_max_processors.positive? ? env_max_processors : Etc.nprocessors
    end
  end
end
