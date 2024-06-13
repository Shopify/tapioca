# typed: true
# frozen_string_literal: true

module Tapioca
  module Benchmarking
    extend T::Sig

    AttributePrimitive = T.type_alias { T.any(String, Integer, Float, T::Boolean) }
    AttributeValue = T.type_alias do
      T.any(
        AttributePrimitive,
        T::Array[String],
        T::Array[T::Boolean],
        T::Array[Integer],
        T::Array[Float],
      )
    end

    sig do
      type_parameters(:R)
        .params(label: String, tags: T::Hash[Symbol, AttributeValue], block: T.proc.returns(T.type_parameter(:R)))
        .returns(T.type_parameter(:R))
    end
    def benchmark(label, tags: {}, &block)
      raise "Calling the old impl for label: #{label}"

      # return yield unless @benchmark

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
