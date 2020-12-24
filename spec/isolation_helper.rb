# typed: true
# frozen_string_literal: true

# Copied from ActiveSupport::Testing::Isolation since we cannot require
# constants from ActiveSupport without polluting the global namespace.
module IsolationHelper
  require "thread"

  def self.forking_env?
    !ENV["NO_FORK"] && Process.respond_to?(:fork)
  end

  def run
    serialized = T.unsafe(self).run_in_isolation do
      super
    end

    Marshal.load(serialized)
  end

  module Forking
    include Kernel

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
              begin
                Marshal.dump(e)
                e
              rescue TypeError
                ex = Exception.new(e.message)
                ex.set_backtrace(e.backtrace)
                Minitest::UnexpectedError.new(ex)
              end
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

  module Subprocess
    include Kernel
    ORIG_ARGV = ARGV.dup unless defined?(ORIG_ARGV)

    # Crazy H4X to get this working in windows / jruby with
    # no forking.
    def run_in_isolation(&_blk)
      this = T.cast(self, Minitest::Test)
      require "tempfile"

      if ENV["ISOLATION_TEST"]
        yield
        test_result = defined?(Minitest::Result) ? Minitest::Result.from(self) : this.dup
        File.open(T.must(ENV["ISOLATION_OUTPUT"]), "w") do |file|
          file.puts [Marshal.dump(test_result)].pack("m")
        end
        exit!(false)
      else
        Tempfile.open("isolation") do |tmpfile|
          env = {
            "ISOLATION_TEST" => this.class.name,
            "ISOLATION_OUTPUT" => tmpfile.path,
          }

          test_opts = "-n#{this.class.name}##{this.name}"

          load_path_args = []
          $-I.each do |p|
            load_path_args << "-I"
            load_path_args << File.expand_path(p)
          end

          child = IO.popen([env, Gem.ruby, *load_path_args, $PROGRAM_NAME, *ORIG_ARGV, test_opts])

          begin
            Process.wait(child.pid)
          rescue Errno::ECHILD # The child process may exit before we wait
            nil
          end

          return T.must(tmpfile.read).unpack1("m")
        end
      end
    end
  end

  if forking_env?
    include(Forking)
  else
    include(Subprocess)
  end
end
