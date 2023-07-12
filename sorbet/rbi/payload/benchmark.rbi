# typed: __STDLIB_INTERNAL

module Benchmark
  private

  def benchmark(caption = T.unsafe(nil), label_width = T.unsafe(nil), format = T.unsafe(nil), *labels); end
  def bm(label_width = T.unsafe(nil), *labels, &blk); end
  def bmbm(width = T.unsafe(nil)); end
  def measure(label = T.unsafe(nil)); end
  def realtime; end

  class << self
    def benchmark(caption = T.unsafe(nil), label_width = T.unsafe(nil), format = T.unsafe(nil), *labels); end
    def bm(label_width = T.unsafe(nil), *labels, &blk); end
    def bmbm(width = T.unsafe(nil)); end
    def measure(label = T.unsafe(nil)); end
    def realtime; end
  end
end

class Benchmark::Job
  def initialize(width); end

  def item(label = T.unsafe(nil), &blk); end
  def list; end
  def report(label = T.unsafe(nil), &blk); end
  def width; end
end

class Benchmark::Report
  def initialize(width = T.unsafe(nil), format = T.unsafe(nil)); end

  def item(label = T.unsafe(nil), *format, &blk); end
  def list; end
  def report(label = T.unsafe(nil), *format, &blk); end
end

class Benchmark::Tms
  def initialize(utime = T.unsafe(nil), stime = T.unsafe(nil), cutime = T.unsafe(nil), cstime = T.unsafe(nil), real = T.unsafe(nil), label = T.unsafe(nil)); end

  def *(x); end
  def +(other); end
  def -(other); end
  def /(x); end
  def add(&blk); end
  def add!(&blk); end
  def cstime; end
  def cutime; end
  def format(format = T.unsafe(nil), *args); end
  def label; end
  def real; end
  def stime; end
  def to_a; end
  def to_h; end
  def to_s; end
  def total; end
  def utime; end

  protected

  def memberwise(op, x); end
end
