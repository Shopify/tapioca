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

module OpenURI
  class << self
    def check_options(options); end
    def open_http(buf, target, proxy, options); end
    def open_loop(uri, options); end
    def open_uri(name, *rest); end
    def redirectable?(uri1, uri2); end
    def scan_open_optional_arguments(*rest); end
  end
end

class OpenURI::Buffer
  def initialize; end

  def <<(str); end
  def io; end
  def size; end
end

class OpenURI::HTTPError < ::StandardError
  def initialize(message, io); end

  def io; end
end

class OpenURI::HTTPRedirect < ::OpenURI::HTTPError
  def initialize(message, io, uri); end

  def uri; end
end

module OpenURI::Meta
  def base_uri; end
  def base_uri=(_arg0); end
  def charset; end
  def content_encoding; end
  def content_type; end
  def content_type_parse; end
  def last_modified; end
  def meta; end
  def meta_add_field(name, value); end
  def meta_add_field2(name, values); end
  def meta_setup_encoding; end
  def metas; end
  def status; end
  def status=(_arg0); end

  class << self
    def init(obj, src = T.unsafe(nil)); end
  end
end

module OpenURI::OpenRead
  def open(*rest, &block); end
  def read(options = T.unsafe(nil)); end
end

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
