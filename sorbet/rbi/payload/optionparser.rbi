# typed: __STDLIB_INTERNAL

class OptionParser
  def initialize(banner = T.unsafe(nil), width = T.unsafe(nil), indent = T.unsafe(nil)); end

  def abort(mesg = T.unsafe(nil)); end
  def accept(*args, &blk); end
  def add_officious; end
  def additional_message(typ, opt); end
  def banner; end
  def banner=(_arg0); end
  def base; end
  def candidate(word); end
  def compsys(to, name = T.unsafe(nil)); end
  def def_head_option(*opts, &block); end
  def def_option(*opts, &block); end
  def def_tail_option(*opts, &block); end
  def default_argv; end
  def default_argv=(_arg0); end
  def define(*opts, &block); end
  def define_head(*opts, &block); end
  def define_tail(*opts, &block); end
  def environment(env = T.unsafe(nil)); end
  def getopts(*args); end
  def help; end
  def inc(*args); end
  def inspect; end
  def load(filename = T.unsafe(nil), into: T.unsafe(nil)); end
  def make_switch(opts, block = T.unsafe(nil)); end
  def new; end
  def on(*opts, &block); end
  def on_head(*opts, &block); end
  def on_tail(*opts, &block); end
  def order(*argv, into: T.unsafe(nil), &nonopt); end
  def order!(argv = T.unsafe(nil), into: T.unsafe(nil), &nonopt); end
  def parse(*argv, into: T.unsafe(nil)); end
  def parse!(argv = T.unsafe(nil), into: T.unsafe(nil)); end
  def permute(*argv, into: T.unsafe(nil)); end
  def permute!(argv = T.unsafe(nil), into: T.unsafe(nil)); end
  def pretty_print(q); end
  def program_name; end
  def program_name=(_arg0); end
  def raise_unknown; end
  def raise_unknown=(_arg0); end
  def reject(*args, &blk); end
  def release; end
  def release=(_arg0); end
  def remove; end
  def require_exact; end
  def require_exact=(_arg0); end
  def separator(string); end
  def set_banner(_arg0); end
  def set_program_name(_arg0); end
  def set_summary_indent(_arg0); end
  def set_summary_width(_arg0); end
  def summarize(to = T.unsafe(nil), width = T.unsafe(nil), max = T.unsafe(nil), indent = T.unsafe(nil), &blk); end
  def summary_indent; end
  def summary_indent=(_arg0); end
  def summary_width; end
  def summary_width=(_arg0); end
  def terminate(arg = T.unsafe(nil)); end
  def to_a; end
  def to_s; end
  def top; end
  def ver; end
  def version; end
  def version=(_arg0); end
  def warn(mesg = T.unsafe(nil)); end

  private

  def complete(typ, opt, icase = T.unsafe(nil), *pat); end
  def notwice(obj, prv, msg); end
  def parse_in_order(argv = T.unsafe(nil), setter = T.unsafe(nil), &nonopt); end
  def search(id, key); end
  def visit(id, *args, &block); end

  class << self
    def accept(*args, &blk); end
    def getopts(*args); end
    def inc(arg, default = T.unsafe(nil)); end
    def reject(*args, &blk); end
    def terminate(arg = T.unsafe(nil)); end
    def top; end
    def with(*args, &block); end
  end
end

module OptionParser::Acceptables; end
class OptionParser::AmbiguousArgument < ::OptionParser::InvalidArgument; end
class OptionParser::AmbiguousOption < ::OptionParser::ParseError; end

module OptionParser::Arguable
  def initialize(*args); end

  def getopts(*args); end
  def options; end
  def options=(opt); end
  def order!(&blk); end
  def parse!; end
  def permute!; end

  class << self
    def extend_object(obj); end
  end
end

class OptionParser::CompletingHash < ::Hash
  def match(key); end
end

module OptionParser::Completion
  def candidate(key, icase = T.unsafe(nil), pat = T.unsafe(nil)); end
  def complete(key, icase = T.unsafe(nil), pat = T.unsafe(nil)); end
  def convert(opt = T.unsafe(nil), val = T.unsafe(nil), *_arg2); end

  class << self
    def candidate(key, icase = T.unsafe(nil), pat = T.unsafe(nil), &block); end
    def regexp(key, icase); end
  end
end

class OptionParser::InvalidArgument < ::OptionParser::ParseError; end
class OptionParser::InvalidOption < ::OptionParser::ParseError; end

class OptionParser::List
  def initialize; end

  def accept(t, pat = T.unsafe(nil), &block); end
  def add_banner(to); end
  def append(*args); end
  def atype; end
  def complete(id, opt, icase = T.unsafe(nil), *pat, &block); end
  def compsys(*args, &block); end
  def each_option(&block); end
  def get_candidates(id); end
  def list; end
  def long; end
  def prepend(*args); end
  def pretty_print(q); end
  def reject(t); end
  def search(id, key); end
  def short; end
  def summarize(*args, &block); end

  private

  def update(sw, sopts, lopts, nsw = T.unsafe(nil), nlopts = T.unsafe(nil)); end
end

class OptionParser::MissingArgument < ::OptionParser::ParseError; end
class OptionParser::NeedlessArgument < ::OptionParser::ParseError; end
class OptionParser::OptionMap < ::Hash; end

class OptionParser::ParseError < ::RuntimeError
  def initialize(*args, additional: T.unsafe(nil)); end

  def additional; end
  def additional=(_arg0); end
  def args; end
  def inspect; end
  def message; end
  def reason; end
  def reason=(_arg0); end
  def recover(argv); end
  def set_backtrace(array); end
  def set_option(opt, eq); end
  def to_s; end

  class << self
    def filter_backtrace(array); end
  end
end

class OptionParser::Switch
  def initialize(pattern = T.unsafe(nil), conv = T.unsafe(nil), short = T.unsafe(nil), long = T.unsafe(nil), arg = T.unsafe(nil), desc = T.unsafe(nil), block = T.unsafe(nil), &_block); end

  def add_banner(to); end
  def arg; end
  def block; end
  def compsys(sdone, ldone); end
  def conv; end
  def desc; end
  def long; end
  def match_nonswitch?(str); end
  def pattern; end
  def pretty_print(q); end
  def pretty_print_contents(q); end
  def short; end
  def summarize(sdone = T.unsafe(nil), ldone = T.unsafe(nil), width = T.unsafe(nil), max = T.unsafe(nil), indent = T.unsafe(nil)); end
  def switch_name; end

  private

  def conv_arg(arg, val = T.unsafe(nil)); end
  def parse_arg(arg); end

  class << self
    def guess(arg); end
    def incompatible_argument_styles(arg, t); end
    def pattern; end
  end
end

class OptionParser::Switch::NoArgument < ::OptionParser::Switch
  def parse(arg, argv); end
  def pretty_head; end

  class << self
    def incompatible_argument_styles(*_arg0); end
    def pattern; end
  end
end

class OptionParser::Switch::OptionalArgument < ::OptionParser::Switch
  def parse(arg, argv, &error); end
  def pretty_head; end
end

class OptionParser::Switch::PlacedArgument < ::OptionParser::Switch
  def parse(arg, argv, &error); end
  def pretty_head; end
end

class OptionParser::Switch::RequiredArgument < ::OptionParser::Switch
  def parse(arg, argv); end
  def pretty_head; end
end
