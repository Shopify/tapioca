# typed: __STDLIB_INTERNAL

module Timeout
  private

  def timeout(sec, klass = T.unsafe(nil), message = T.unsafe(nil), &block); end

  class << self
    def ensure_timeout_thread_created; end
    def timeout(sec, klass = T.unsafe(nil), message = T.unsafe(nil), &block); end

    private

    def create_timeout_thread; end
  end
end

class Timeout::Error < ::RuntimeError
  class << self
    def handle_timeout(message); end
  end
end

class Timeout::ExitException < ::Exception
  def exception(*_arg0); end
end
