# typed: __STDLIB_INTERNAL

module PTY
  private

  def getpty(*_arg0); end
  def spawn(*_arg0); end

  class << self
    def check(*_arg0); end
    def getpty(*_arg0); end
    def open; end
    def spawn(*_arg0); end
  end
end

class PTY::ChildExited < ::RuntimeError
  def status; end
end
