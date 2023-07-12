# typed: __STDLIB_INTERNAL

class StringScanner
  def initialize(*_arg0); end

  def <<(_arg0); end
  def [](_arg0); end
  def beginning_of_line?; end
  def bol?; end
  def captures; end
  def charpos; end
  def check(_arg0); end
  def check_until(_arg0); end
  def clear; end
  def concat(_arg0); end
  def empty?; end
  def eos?; end
  def exist?(_arg0); end
  def fixed_anchor?; end
  def get_byte; end
  def getbyte; end
  def getch; end
  def inspect; end
  def match?(_arg0); end
  def matched; end
  def matched?; end
  def matched_size; end
  def named_captures; end
  def peek(_arg0); end
  def peep(_arg0); end
  def pointer; end
  def pointer=(_arg0); end
  def pos; end
  def pos=(_arg0); end
  def post_match; end
  def pre_match; end
  def reset; end
  def rest; end
  def rest?; end
  def rest_size; end
  def restsize; end
  def scan(_arg0); end
  def scan_full(_arg0, _arg1, _arg2); end
  def scan_until(_arg0); end
  def search_full(_arg0, _arg1, _arg2); end
  def size; end
  def skip(_arg0); end
  def skip_until(_arg0); end
  def string; end
  def string=(_arg0); end
  def terminate; end
  def unscan; end
  def values_at(*_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def must_C_version; end
  end
end

class StringScanner::Error < ::StandardError; end
