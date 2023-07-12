# typed: __STDLIB_INTERNAL

class StringIO
  include ::Enumerable

  def initialize(*_arg0); end

  def binmode; end
  def close; end
  def close_read; end
  def close_write; end
  def closed?; end
  def closed_read?; end
  def closed_write?; end
  def each(*_arg0); end
  def each_byte; end
  def each_char; end
  def each_codepoint; end
  def each_line(*_arg0); end
  def eof; end
  def eof?; end
  def external_encoding; end
  def fcntl(*_arg0); end
  def fileno; end
  def flush; end
  def fsync; end
  def getbyte; end
  def getc; end
  def gets(*_arg0); end
  def internal_encoding; end
  def isatty; end
  def length; end
  def lineno; end
  def lineno=(_arg0); end
  def pid; end
  def pos; end
  def pos=(_arg0); end
  def putc(_arg0); end
  def read(*_arg0); end
  def readlines(*_arg0); end
  def reopen(*_arg0); end
  def rewind; end
  def seek(*_arg0); end
  def set_encoding(*_arg0); end
  def set_encoding_by_bom; end
  def size; end
  def string; end
  def string=(_arg0); end
  def sync; end
  def sync=(_arg0); end
  def tell; end
  def truncate(_arg0); end
  def tty?; end
  def ungetbyte(_arg0); end
  def ungetc(_arg0); end
  def write(*_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def new(*_arg0); end
    def open(*_arg0); end
  end
end
