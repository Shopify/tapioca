# typed: __STDLIB_INTERNAL

class BasicSocket < ::IO
  def close_read; end
  def close_write; end
  def connect_address; end
  def do_not_reverse_lookup; end
  def do_not_reverse_lookup=(_arg0); end
  def getpeereid; end
  def getpeername; end
  def getsockname; end
  def getsockopt(_arg0, _arg1); end
  def local_address; end
  def recv(*_arg0); end
  def recv_nonblock(len, flag = T.unsafe(nil), str = T.unsafe(nil), exception: T.unsafe(nil)); end
  def recvmsg(dlen = T.unsafe(nil), flags = T.unsafe(nil), clen = T.unsafe(nil), scm_rights: T.unsafe(nil)); end
  def recvmsg_nonblock(dlen = T.unsafe(nil), flags = T.unsafe(nil), clen = T.unsafe(nil), scm_rights: T.unsafe(nil), exception: T.unsafe(nil)); end
  def remote_address; end
  def send(*_arg0); end
  def sendmsg(mesg, flags = T.unsafe(nil), dest_sockaddr = T.unsafe(nil), *controls); end
  def sendmsg_nonblock(mesg, flags = T.unsafe(nil), dest_sockaddr = T.unsafe(nil), *controls, exception: T.unsafe(nil)); end
  def setsockopt(*_arg0); end
  def shutdown(*_arg0); end

  private

  def __recv_nonblock(_arg0, _arg1, _arg2, _arg3); end
  def __recvmsg(_arg0, _arg1, _arg2, _arg3); end
  def __recvmsg_nonblock(_arg0, _arg1, _arg2, _arg3, _arg4); end
  def __sendmsg(_arg0, _arg1, _arg2, _arg3); end
  def __sendmsg_nonblock(_arg0, _arg1, _arg2, _arg3, _arg4); end

  class << self
    def do_not_reverse_lookup; end
    def do_not_reverse_lookup=(_arg0); end
    def for_fd(_arg0); end
  end
end

class Date
  include ::Comparable

  def initialize(*_arg0); end

  def +(_arg0); end
  def -(_arg0); end
  def <<(_arg0); end
  def <=>(_arg0); end
  def ===(_arg0); end
  def >>(_arg0); end
  def ajd; end
  def amjd; end
  def asctime; end
  def ctime; end
  def cwday; end
  def cweek; end
  def cwyear; end
  def day; end
  def day_fraction; end
  def deconstruct_keys(_arg0); end
  def downto(_arg0); end
  def england; end
  def eql?(_arg0); end
  def friday?; end
  def gregorian; end
  def gregorian?; end
  def hash; end
  def httpdate; end
  def infinite?; end
  def inspect; end
  def iso8601; end
  def italy; end
  def jd; end
  def jisx0301; end
  def julian; end
  def julian?; end
  def ld; end
  def leap?; end
  def marshal_dump; end
  def marshal_load(_arg0); end
  def mday; end
  def mjd; end
  def mon; end
  def monday?; end
  def month; end
  def new_start(*_arg0); end
  def next; end
  def next_day(*_arg0); end
  def next_month(*_arg0); end
  def next_year(*_arg0); end
  def prev_day(*_arg0); end
  def prev_month(*_arg0); end
  def prev_year(*_arg0); end
  def rfc2822; end
  def rfc3339; end
  def rfc822; end
  def saturday?; end
  def start; end
  def step(*_arg0); end
  def strftime(*_arg0); end
  def succ; end
  def sunday?; end
  def thursday?; end
  def to_date; end
  def to_datetime; end
  def to_s; end
  def to_time; end
  def tuesday?; end
  def upto(_arg0); end
  def wday; end
  def wednesday?; end
  def xmlschema; end
  def yday; end
  def year; end

  private

  def hour; end
  def initialize_copy(_arg0); end
  def min; end
  def minute; end
  def sec; end
  def second; end

  class << self
    def _httpdate(*_arg0); end
    def _iso8601(*_arg0); end
    def _jisx0301(*_arg0); end
    def _load(_arg0); end
    def _parse(*_arg0); end
    def _rfc2822(*_arg0); end
    def _rfc3339(*_arg0); end
    def _rfc822(*_arg0); end
    def _strptime(*_arg0); end
    def _xmlschema(*_arg0); end
    def civil(*_arg0); end
    def commercial(*_arg0); end
    def gregorian_leap?(_arg0); end
    def httpdate(*_arg0); end
    def iso8601(*_arg0); end
    def jd(*_arg0); end
    def jisx0301(*_arg0); end
    def julian_leap?(_arg0); end
    def leap?(_arg0); end
    def ordinal(*_arg0); end
    def parse(*_arg0); end
    def rfc2822(*_arg0); end
    def rfc3339(*_arg0); end
    def rfc822(*_arg0); end
    def strptime(*_arg0); end
    def today(*_arg0); end
    def valid_civil?(*_arg0); end
    def valid_commercial?(*_arg0); end
    def valid_date?(*_arg0); end
    def valid_jd?(*_arg0); end
    def valid_ordinal?(*_arg0); end
    def xmlschema(*_arg0); end
  end
end

class Date::Error < ::ArgumentError; end

class Date::Infinity < ::Numeric
  def initialize(d = T.unsafe(nil)); end

  def +@; end
  def -@; end
  def <=>(other); end
  def abs; end
  def coerce(other); end
  def finite?; end
  def infinite?; end
  def nan?; end
  def to_f; end
  def zero?; end

  protected

  def d; end
end

class DateTime < ::Date
  def deconstruct_keys(_arg0); end
  def hour; end
  def iso8601(*_arg0); end
  def jisx0301(*_arg0); end
  def min; end
  def minute; end
  def new_offset(*_arg0); end
  def offset; end
  def rfc3339(*_arg0); end
  def sec; end
  def sec_fraction; end
  def second; end
  def second_fraction; end
  def strftime(*_arg0); end
  def to_date; end
  def to_datetime; end
  def to_s; end
  def to_time; end
  def xmlschema(*_arg0); end
  def zone; end

  class << self
    def _strptime(*_arg0); end
    def civil(*_arg0); end
    def commercial(*_arg0); end
    def httpdate(*_arg0); end
    def iso8601(*_arg0); end
    def jd(*_arg0); end
    def jisx0301(*_arg0); end
    def new(*_arg0); end
    def now(*_arg0); end
    def ordinal(*_arg0); end
    def parse(*_arg0); end
    def rfc2822(*_arg0); end
    def rfc3339(*_arg0); end
    def rfc822(*_arg0); end
    def strptime(*_arg0); end
    def xmlschema(*_arg0); end
  end
end

class IPAddr
  def initialize(addr = T.unsafe(nil), family = T.unsafe(nil)); end

  def &(other); end
  def <<(num); end
  def <=>(other); end
  def ==(other); end
  def ===(other); end
  def >>(num); end
  def eql?(other); end
  def family; end
  def hash; end
  def hton; end
  def include?(other); end
  def inspect; end
  def ip6_arpa; end
  def ip6_int; end
  def ipv4?; end
  def ipv4_compat; end
  def ipv4_compat?; end
  def ipv4_mapped; end
  def ipv4_mapped?; end
  def ipv6?; end
  def link_local?; end
  def loopback?; end
  def mask(prefixlen); end
  def native; end
  def netmask; end
  def prefix; end
  def prefix=(prefix); end
  def private?; end
  def reverse; end
  def succ; end
  def to_i; end
  def to_range; end
  def to_s; end
  def to_string; end
  def zone_id; end
  def zone_id=(zid); end
  def |(other); end
  def ~; end

  protected

  def mask!(mask); end
  def set(addr, *family); end

  private

  def _ipv4_compat?; end
  def _reverse; end
  def _to_string(addr); end
  def addr_mask(addr); end
  def coerce_other(other); end
  def in6_addr(left); end
  def in_addr(addr); end

  class << self
    def new_ntoh(addr); end
    def ntop(addr); end
  end
end

class IPAddr::AddressFamilyError < ::IPAddr::Error; end
class IPAddr::Error < ::ArgumentError; end
class IPAddr::InvalidAddressError < ::IPAddr::Error; end
class IPAddr::InvalidPrefixError < ::IPAddr::InvalidAddressError; end

class IPSocket < ::BasicSocket
  def addr(*_arg0); end
  def inspect; end
  def peeraddr(*_arg0); end
  def recvfrom(*_arg0); end

  class << self
    def getaddress(_arg0); end
  end
end

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
  def define_by_keywords(options, meth, **opts); end
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
    def each_const(path, base = T.unsafe(nil)); end
    def getopts(*args); end
    def inc(arg, default = T.unsafe(nil)); end
    def reject(*args, &blk); end
    def search_const(klass, name); end
    def show_version(*pkgs); end
    def terminate(arg = T.unsafe(nil)); end
    def top; end
    def with(*args, &block); end
  end
end

class OptionParser::AC < ::OptionParser
  def ac_arg_disable(name, help_string, &block); end
  def ac_arg_enable(name, help_string, &block); end
  def ac_arg_with(name, help_string, &block); end

  private

  def _ac_arg_enable(prefix, name, help_string, block); end
  def _check_ac_args(name, block); end
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

module URI
  include ::URI::RFC2396_REGEXP

  class << self
    def decode_uri_component(str, enc = T.unsafe(nil)); end
    def decode_www_form(str, enc = T.unsafe(nil), separator: T.unsafe(nil), use__charset_: T.unsafe(nil), isindex: T.unsafe(nil)); end
    def decode_www_form_component(str, enc = T.unsafe(nil)); end
    def encode_uri_component(str, enc = T.unsafe(nil)); end
    def encode_www_form(enum, enc = T.unsafe(nil)); end
    def encode_www_form_component(str, enc = T.unsafe(nil)); end
    def extract(str, schemes = T.unsafe(nil), &block); end
    def for(scheme, *arguments, default: T.unsafe(nil)); end
    def get_encoding(label); end
    def join(*str); end
    def open(name, *rest, &block); end
    def parse(uri); end
    def regexp(schemes = T.unsafe(nil)); end
    def register_scheme(scheme, klass); end
    def scheme_list; end
    def split(uri); end

    private

    def _decode_uri_component(regexp, str, enc); end
    def _encode_uri_component(regexp, table, str, enc); end
  end
end

class URI::BadURIError < ::URI::Error; end
class URI::Error < ::StandardError; end

class URI::FTP < ::URI::Generic
  def initialize(scheme, userinfo, host, port, registry, path, opaque, query, fragment, parser = T.unsafe(nil), arg_check = T.unsafe(nil)); end

  def buffer_open(buf, proxy, options); end
  def merge(oth); end
  def path; end
  def to_s; end
  def typecode; end
  def typecode=(typecode); end

  protected

  def set_path(v); end
  def set_typecode(v); end

  private

  def check_typecode(v); end

  class << self
    def build(args); end
    def new2(user, password, host, port, path, typecode = T.unsafe(nil), arg_check = T.unsafe(nil)); end
  end
end

class URI::File < ::URI::Generic
  def check_password(user); end
  def check_user(user); end
  def check_userinfo(user); end
  def set_host(v); end
  def set_password(v); end
  def set_port(v); end
  def set_user(v); end
  def set_userinfo(v); end

  class << self
    def build(args); end
  end
end

class URI::Generic
  include ::URI::RFC2396_REGEXP
  include ::URI

  def initialize(scheme, userinfo, host, port, registry, path, opaque, query, fragment, parser = T.unsafe(nil), arg_check = T.unsafe(nil)); end

  def +(oth); end
  def -(oth); end
  def ==(oth); end
  def absolute; end
  def absolute?; end
  def coerce(oth); end
  def component; end
  def decoded_password; end
  def decoded_user; end
  def default_port; end
  def eql?(oth); end
  def find_proxy(env = T.unsafe(nil)); end
  def fragment; end
  def fragment=(v); end
  def hash; end
  def hierarchical?; end
  def host; end
  def host=(v); end
  def hostname; end
  def hostname=(v); end
  def inspect; end
  def merge(oth); end
  def merge!(oth); end
  def normalize; end
  def normalize!; end
  def opaque; end
  def opaque=(v); end
  def parser; end
  def password; end
  def password=(password); end
  def path; end
  def path=(v); end
  def port; end
  def port=(v); end
  def query; end
  def query=(v); end
  def registry; end
  def registry=(v); end
  def relative?; end
  def route_from(oth); end
  def route_to(oth); end
  def scheme; end
  def scheme=(v); end
  def select(*components); end
  def to_s; end
  def user; end
  def user=(user); end
  def userinfo; end
  def userinfo=(userinfo); end

  protected

  def component_ary; end
  def set_host(v); end
  def set_opaque(v); end
  def set_password(v); end
  def set_path(v); end
  def set_port(v); end
  def set_registry(v); end
  def set_scheme(v); end
  def set_user(v); end
  def set_userinfo(user, password = T.unsafe(nil)); end

  private

  def check_host(v); end
  def check_opaque(v); end
  def check_password(v, user = T.unsafe(nil)); end
  def check_path(v); end
  def check_port(v); end
  def check_registry(v); end
  def check_scheme(v); end
  def check_user(v); end
  def check_userinfo(user, password = T.unsafe(nil)); end
  def escape_userpass(v); end
  def merge_path(base, rel); end
  def replace!(oth); end
  def route_from0(oth); end
  def route_from_path(src, dst); end
  def split_path(path); end
  def split_userinfo(ui); end

  class << self
    def build(args); end
    def build2(args); end
    def component; end
    def default_port; end
    def use_proxy?(hostname, addr, port, no_proxy); end
    def use_registry; end
  end
end

class URI::HTTP < ::URI::Generic
  def authority; end
  def buffer_open(buf, proxy, options); end
  def origin; end
  def request_uri; end

  class << self
    def build(args); end
  end
end

class URI::HTTPS < ::URI::HTTP; end
class URI::InvalidComponentError < ::URI::Error; end
class URI::InvalidURIError < ::URI::Error; end

class URI::LDAP < ::URI::Generic
  def initialize(*arg); end

  def attributes; end
  def attributes=(val); end
  def dn; end
  def dn=(val); end
  def extensions; end
  def extensions=(val); end
  def filter; end
  def filter=(val); end
  def hierarchical?; end
  def scope; end
  def scope=(val); end

  protected

  def set_attributes(val); end
  def set_dn(val); end
  def set_extensions(val); end
  def set_filter(val); end
  def set_scope(val); end

  private

  def build_path_query; end
  def parse_dn; end
  def parse_query; end

  class << self
    def build(args); end
  end
end

class URI::LDAPS < ::URI::LDAP; end

class URI::MailTo < ::URI::Generic
  def initialize(*arg); end

  def headers; end
  def headers=(v); end
  def to; end
  def to=(v); end
  def to_mailtext; end
  def to_rfc822text; end
  def to_s; end

  protected

  def set_headers(v); end
  def set_to(v); end

  private

  def check_headers(v); end
  def check_to(v); end

  class << self
    def build(args); end
  end
end

class URI::RFC2396_Parser
  include ::URI::RFC2396_REGEXP

  def initialize(opts = T.unsafe(nil)); end

  def escape(str, unsafe = T.unsafe(nil)); end
  def extract(str, schemes = T.unsafe(nil)); end
  def inspect; end
  def join(*uris); end
  def make_regexp(schemes = T.unsafe(nil)); end
  def parse(uri); end
  def pattern; end
  def regexp; end
  def split(uri); end
  def unescape(str, escaped = T.unsafe(nil)); end

  private

  def convert_to_uri(uri); end
  def initialize_pattern(opts = T.unsafe(nil)); end
  def initialize_regexp(pattern); end
end

module URI::RFC2396_REGEXP; end
module URI::RFC2396_REGEXP::PATTERN; end

class URI::RFC3986_Parser
  def initialize; end

  def inspect; end
  def join(*uris); end
  def parse(uri); end
  def regexp; end
  def split(uri); end

  private

  def convert_to_uri(uri); end
  def default_regexp; end
end

class URI::Source < ::URI::File
  sig { params(v: T.nilable(::String)).returns(T::Boolean) }
  def check_host(v); end

  def gem_name; end

  sig { returns(T.nilable(::String)) }
  def gem_version; end

  def line_number; end

  sig { params(v: T.nilable(::String)).void }
  def set_path(v); end

  sig { returns(::String) }
  def to_s; end

  class << self
    sig { params(gem_name: ::String, gem_version: T.nilable(::String), path: ::String, line_number: T.nilable(::String)).returns(::URI::Source) }
    def build(gem_name:, gem_version:, path:, line_number:); end
  end
end

module URI::Util
  private

  def make_components_hash(klass, array_hash); end

  class << self
    def make_components_hash(klass, array_hash); end
  end
end

class URI::WS < ::URI::Generic
  def request_uri; end

  class << self
    def build(args); end
  end
end

class URI::WSS < ::URI::WS; end
