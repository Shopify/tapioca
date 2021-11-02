# typed: strict
# frozen_string_literal: true

require "minitest"

module Subprocess
  extend T::Sig
  include Kernel
  ORIG_ARGV = T.let(ARGV.dup, T::Array[T.untyped]) unless defined?(ORIG_ARGV)

  # Crazy H4X to get this working in windows / jruby with
  # no forking.
  sig { params(_blk: T.untyped).returns(String) }
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
