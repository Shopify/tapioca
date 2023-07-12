# typed: __STDLIB_INTERNAL

class PrettyPrint
  def initialize(output = T.unsafe(nil), maxwidth = T.unsafe(nil), newline = T.unsafe(nil), &genspace); end

  def break_outmost_groups; end
  def breakable(sep = T.unsafe(nil), width = T.unsafe(nil)); end
  def current_group; end
  def fill_breakable(sep = T.unsafe(nil), width = T.unsafe(nil)); end
  def flush; end
  def genspace; end
  def group(indent = T.unsafe(nil), open_obj = T.unsafe(nil), close_obj = T.unsafe(nil), open_width = T.unsafe(nil), close_width = T.unsafe(nil)); end
  def group_queue; end
  def group_sub; end
  def indent; end
  def maxwidth; end
  def nest(indent); end
  def newline; end
  def output; end
  def text(obj, width = T.unsafe(nil)); end

  class << self
    def format(output = T.unsafe(nil), maxwidth = T.unsafe(nil), newline = T.unsafe(nil), genspace = T.unsafe(nil)); end
    def singleline_format(output = T.unsafe(nil), maxwidth = T.unsafe(nil), newline = T.unsafe(nil), genspace = T.unsafe(nil)); end
  end
end

class PrettyPrint::Breakable
  def initialize(sep, width, q); end

  def indent; end
  def obj; end
  def output(out, output_width); end
  def width; end
end

class PrettyPrint::Group
  def initialize(depth); end

  def break; end
  def break?; end
  def breakables; end
  def depth; end
  def first?; end
end

class PrettyPrint::GroupQueue
  def initialize(*groups); end

  def delete(group); end
  def deq; end
  def enq(group); end
end

class PrettyPrint::SingleLine
  def initialize(output, maxwidth = T.unsafe(nil), newline = T.unsafe(nil)); end

  def breakable(sep = T.unsafe(nil), width = T.unsafe(nil)); end
  def first?; end
  def flush; end
  def group(indent = T.unsafe(nil), open_obj = T.unsafe(nil), close_obj = T.unsafe(nil), open_width = T.unsafe(nil), close_width = T.unsafe(nil)); end
  def nest(indent); end
  def text(obj, width = T.unsafe(nil)); end
end

class PrettyPrint::Text
  def initialize; end

  def add(obj, width); end
  def output(out, output_width); end
  def width; end
end
