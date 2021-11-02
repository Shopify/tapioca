# typed: strict
# frozen_string_literal: true

module Forking
  extend T::Sig
  include Kernel

  sig { params(_blk: T.untyped).returns(String) }
  def run_in_isolation(&_blk)
    read, write = IO.pipe
    read.binmode
    write.binmode

    this = T.cast(self, Minitest::Test)
    pid = fork do
      read.close
      yield
      begin
        if this.error?
          this.failures.map! do |e|
            Marshal.dump(e)
            e
          rescue TypeError
            ex = Exception.new(e.message)
            ex.set_backtrace(e.backtrace)
            Minitest::UnexpectedError.new(ex)
          end
        end
        test_result = defined?(Minitest::Result) ? Minitest::Result.from(self) : this.dup
        result = Marshal.dump(test_result)
      end

      write.puts [result].pack("m")
      exit!(false)
    end

    write.close
    result = read.read
    Process.wait2(T.must(pid))
    T.must(result).unpack1("m")
  end
end
