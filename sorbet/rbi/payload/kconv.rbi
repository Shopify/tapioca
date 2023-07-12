# typed: __STDLIB_INTERNAL

module Kconv
  private

  def guess(str); end
  def iseuc(str); end
  def isjis(str); end
  def issjis(str); end
  def isutf8(str); end
  def kconv(str, to_enc, from_enc = T.unsafe(nil)); end
  def toeuc(str); end
  def tojis(str); end
  def tolocale(str); end
  def tosjis(str); end
  def toutf16(str); end
  def toutf32(str); end
  def toutf8(str); end

  class << self
    def guess(str); end
    def iseuc(str); end
    def isjis(str); end
    def issjis(str); end
    def isutf8(str); end
    def kconv(str, to_enc, from_enc = T.unsafe(nil)); end
    def toeuc(str); end
    def tojis(str); end
    def tolocale(str); end
    def tosjis(str); end
    def toutf16(str); end
    def toutf32(str); end
    def toutf8(str); end
  end
end

module NKF
  private

  def guess(_arg0); end
  def nkf(_arg0, _arg1); end

  class << self
    def guess(_arg0); end
    def nkf(_arg0, _arg1); end
  end
end
