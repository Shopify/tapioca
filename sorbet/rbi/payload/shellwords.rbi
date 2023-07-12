# typed: __STDLIB_INTERNAL

module Shellwords
  private

  def shellescape(str); end
  def shelljoin(array); end
  def shellsplit(line); end
  def shellwords(line); end

  class << self
    def escape(str); end
    def join(array); end
    def shellescape(str); end
    def shelljoin(array); end
    def shellsplit(line); end
    def shellwords(line); end
    def split(line); end
  end
end
