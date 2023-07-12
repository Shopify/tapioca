# typed: __STDLIB_INTERNAL

class PP < ::PrettyPrint
  include ::PP::PPMethods

  class << self
    def mcall(obj, mod, meth, *args, &block); end
    def pp(obj, out = T.unsafe(nil), width = T.unsafe(nil)); end
    def sharing_detection; end
    def sharing_detection=(b); end
    def singleline_pp(obj, out = T.unsafe(nil)); end
    def width_for(out); end
  end
end

module PP::ObjectMixin
  def pretty_print(q); end
  def pretty_print_cycle(q); end
  def pretty_print_inspect; end
  def pretty_print_instance_variables; end
end

module PP::PPMethods
  def check_inspect_key(id); end
  def comma_breakable; end
  def guard_inspect_key; end
  def object_address_group(obj, &block); end
  def object_group(obj, &block); end
  def pop_inspect_key(id); end
  def pp(obj); end
  def pp_hash(obj); end
  def pp_object(obj); end
  def push_inspect_key(id); end
  def seplist(list, sep = T.unsafe(nil), iter_method = T.unsafe(nil)); end
end

class PP::SingleLine < ::PrettyPrint::SingleLine
  include ::PP::PPMethods
end

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
