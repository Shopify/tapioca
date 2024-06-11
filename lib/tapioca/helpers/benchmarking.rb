# frozen_string_literal: true

module Tapioca
  module Benchmarking
    extend T::Sig

    sig do
      type_parameters(:R)
        .params(label: String, block: T.proc.returns(T.type_parameter(:R)))
        .returns(T.type_parameter(:R))
    end
    def benchmark(label, &block)
      return yield unless @benchmark

      begin
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
        yield
      ensure
        stop = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
        elapsed = stop - start

        if 1000 < elapsed
          elapsed /= 1000
          $stderr.puts("ℹ️ ########## Benchmark - #{label} took #{elapsed.round(1)}s")
        else
          $stderr.puts("ℹ️ ########## Benchmark - #{label} took #{elapsed.round(1)}ms")
        end
      end
    end
  end
end
