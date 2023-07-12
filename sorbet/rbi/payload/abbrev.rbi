# typed: __STDLIB_INTERNAL

module Abbrev
  private

  def abbrev(words, pattern = T.unsafe(nil)); end

  class << self
    def abbrev(words, pattern = T.unsafe(nil)); end
  end
end
