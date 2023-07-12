# typed: __STDLIB_INTERNAL

module Find
  private

  def find(*paths, ignore_error: T.unsafe(nil)); end
  def prune; end

  class << self
    def find(*paths, ignore_error: T.unsafe(nil)); end
    def prune; end
  end
end
