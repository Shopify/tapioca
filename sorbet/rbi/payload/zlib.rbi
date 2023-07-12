# typed: __STDLIB_INTERNAL

module Zlib
  private

  def adler32(*_arg0); end
  def adler32_combine(_arg0, _arg1, _arg2); end
  def crc32(*_arg0); end
  def crc32_combine(_arg0, _arg1, _arg2); end
  def crc_table; end
  def zlib_version; end

  class << self
    def adler32(*_arg0); end
    def adler32_combine(_arg0, _arg1, _arg2); end
    def crc32(*_arg0); end
    def crc32_combine(_arg0, _arg1, _arg2); end
    def crc_table; end
    def deflate(*_arg0); end
    def gunzip(_arg0); end
    def gzip(*_arg0); end
    def inflate(_arg0); end
    def zlib_version; end
  end
end

class Zlib::BufError < ::Zlib::Error; end
class Zlib::DataError < ::Zlib::Error; end

class Zlib::Deflate < ::Zlib::ZStream
  def initialize(*_arg0); end

  def <<(_arg0); end
  def deflate(*_arg0); end
  def flush(*_arg0); end
  def params(_arg0, _arg1); end
  def set_dictionary(_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def deflate(*_arg0); end
  end
end

class Zlib::Error < ::StandardError; end

class Zlib::GzipFile
  def close; end
  def closed?; end
  def comment; end
  def crc; end
  def finish; end
  def level; end
  def mtime; end
  def orig_name; end
  def os_code; end
  def sync; end
  def sync=(_arg0); end
  def to_io; end

  class << self
    def wrap(*_arg0); end
  end
end

class Zlib::GzipFile::CRCError < ::Zlib::GzipFile::Error; end

class Zlib::GzipFile::Error < ::Zlib::Error
  def input; end
  def inspect; end
end

class Zlib::GzipFile::LengthError < ::Zlib::GzipFile::Error; end
class Zlib::GzipFile::NoFooter < ::Zlib::GzipFile::Error; end

class Zlib::GzipReader < ::Zlib::GzipFile
  include ::Enumerable

  def initialize(*_arg0); end

  def each(*_arg0); end
  def each_byte; end
  def each_char; end
  def each_line(*_arg0); end
  def eof; end
  def eof?; end
  def external_encoding; end
  def getbyte; end
  def getc; end
  def gets(*_arg0); end
  def lineno; end
  def lineno=(_arg0); end
  def pos; end
  def read(*_arg0); end
  def readbyte; end
  def readchar; end
  def readline(*_arg0); end
  def readlines(*_arg0); end
  def readpartial(*_arg0); end
  def rewind; end
  def tell; end
  def ungetbyte(_arg0); end
  def ungetc(_arg0); end
  def unused; end

  class << self
    def open(*_arg0); end
    def zcat(*_arg0); end
  end
end

class Zlib::GzipWriter < ::Zlib::GzipFile
  def initialize(*_arg0); end

  def <<(_arg0); end
  def comment=(_arg0); end
  def flush(*_arg0); end
  def mtime=(_arg0); end
  def orig_name=(_arg0); end
  def pos; end
  def print(*_arg0); end
  def printf(*_arg0); end
  def putc(_arg0); end
  def puts(*_arg0); end
  def tell; end
  def write(*_arg0); end

  class << self
    def open(*_arg0); end
  end
end

class Zlib::InProgressError < ::Zlib::Error; end

class Zlib::Inflate < ::Zlib::ZStream
  def initialize(*_arg0); end

  def <<(_arg0); end
  def add_dictionary(_arg0); end
  def inflate(*_arg0); end
  def set_dictionary(_arg0); end
  def sync(_arg0); end
  def sync_point?; end

  class << self
    def inflate(_arg0); end
  end
end

class Zlib::MemError < ::Zlib::Error; end
class Zlib::NeedDict < ::Zlib::Error; end
class Zlib::StreamEnd < ::Zlib::Error; end
class Zlib::StreamError < ::Zlib::Error; end
class Zlib::VersionError < ::Zlib::Error; end

class Zlib::ZStream
  def adler; end
  def avail_in; end
  def avail_out; end
  def avail_out=(_arg0); end
  def close; end
  def closed?; end
  def data_type; end
  def end; end
  def ended?; end
  def finish; end
  def finished?; end
  def flush_next_in; end
  def flush_next_out; end
  def reset; end
  def stream_end?; end
  def total_in; end
  def total_out; end
end
