# typed: __STDLIB_INTERNAL

class Addrinfo
  def initialize(*_arg0); end

  def afamily; end
  def bind; end
  def canonname; end
  def connect(timeout: T.unsafe(nil), &block); end
  def connect_from(*args, timeout: T.unsafe(nil), &block); end
  def connect_to(*args, timeout: T.unsafe(nil), &block); end
  def family_addrinfo(*args); end
  def getnameinfo(*_arg0); end
  def inspect; end
  def inspect_sockaddr; end
  def ip?; end
  def ip_address; end
  def ip_port; end
  def ip_unpack; end
  def ipv4?; end
  def ipv4_loopback?; end
  def ipv4_multicast?; end
  def ipv4_private?; end
  def ipv6?; end
  def ipv6_linklocal?; end
  def ipv6_loopback?; end
  def ipv6_mc_global?; end
  def ipv6_mc_linklocal?; end
  def ipv6_mc_nodelocal?; end
  def ipv6_mc_orglocal?; end
  def ipv6_mc_sitelocal?; end
  def ipv6_multicast?; end
  def ipv6_sitelocal?; end
  def ipv6_to_ipv4; end
  def ipv6_unique_local?; end
  def ipv6_unspecified?; end
  def ipv6_v4compat?; end
  def ipv6_v4mapped?; end
  def listen(backlog = T.unsafe(nil)); end
  def marshal_dump; end
  def marshal_load(_arg0); end
  def pfamily; end
  def protocol; end
  def socktype; end
  def to_s; end
  def to_sockaddr; end
  def unix?; end
  def unix_path; end

  protected

  def connect_internal(local_addrinfo, timeout = T.unsafe(nil)); end

  class << self
    def foreach(nodename, service, family = T.unsafe(nil), socktype = T.unsafe(nil), protocol = T.unsafe(nil), flags = T.unsafe(nil), timeout: T.unsafe(nil), &block); end
    def getaddrinfo(*_arg0); end
    def ip(_arg0); end
    def tcp(_arg0, _arg1); end
    def udp(_arg0, _arg1); end
    def unix(*_arg0); end
  end
end

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

module Digest
  private

  def hexencode(_arg0); end

  class << self
    def const_missing(name); end
    def hexencode(_arg0); end
  end
end

class Digest::Base < ::Digest::Class
  def <<(_arg0); end
  def block_length; end
  def digest_length; end
  def reset; end
  def update(_arg0); end

  private

  def finish; end
  def initialize_copy(_arg0); end
end

class Digest::Class
  include ::Digest::Instance

  def initialize; end

  class << self
    def base64digest(str, *args); end
    def digest(*_arg0); end
    def file(name, *args); end
    def hexdigest(*_arg0); end
  end
end

module Digest::Instance
  def <<(_arg0); end
  def ==(_arg0); end
  def base64digest(str = T.unsafe(nil)); end
  def base64digest!; end
  def block_length; end
  def digest(*_arg0); end
  def digest!; end
  def digest_length; end
  def file(name); end
  def hexdigest(*_arg0); end
  def hexdigest!; end
  def inspect; end
  def length; end
  def new; end
  def reset; end
  def size; end
  def to_s; end
  def update(_arg0); end

  private

  def finish; end
end

class Digest::SHA1 < ::Digest::Base; end

class Digest::SHA2 < ::Digest::Class
  def initialize(bitlen = T.unsafe(nil)); end

  def <<(str); end
  def block_length; end
  def digest_length; end
  def inspect; end
  def reset; end
  def update(str); end

  private

  def finish; end
  def initialize_copy(other); end
end

class Digest::SHA256 < ::Digest::Base; end
class Digest::SHA384 < ::Digest::Base; end
class Digest::SHA512 < ::Digest::Base; end
module IO::WaitReadable; end
module IO::WaitWritable; end

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

module Net; end

class Net::BufferedIO
  def initialize(io, read_timeout: T.unsafe(nil), write_timeout: T.unsafe(nil), continue_timeout: T.unsafe(nil), debug_output: T.unsafe(nil)); end

  def <<(*strs); end
  def close; end
  def closed?; end
  def continue_timeout; end
  def continue_timeout=(_arg0); end
  def debug_output; end
  def debug_output=(_arg0); end
  def eof?; end
  def inspect; end
  def io; end
  def read(len, dest = T.unsafe(nil), ignore_eof = T.unsafe(nil)); end
  def read_all(dest = T.unsafe(nil)); end
  def read_timeout; end
  def read_timeout=(_arg0); end
  def readline; end
  def readuntil(terminator, ignore_eof = T.unsafe(nil)); end
  def write(*strs); end
  def write_timeout; end
  def write_timeout=(_arg0); end
  def writeline(str); end

  private

  def LOG(msg); end
  def LOG_off; end
  def LOG_on; end
  def rbuf_consume(len = T.unsafe(nil)); end
  def rbuf_consume_all; end
  def rbuf_fill; end
  def rbuf_flush; end
  def rbuf_size; end
  def write0(*strs); end
  def writing; end
end

class Net::HTTP < ::Net::Protocol
  def initialize(address, port = T.unsafe(nil)); end

  def active?; end
  def address; end
  def ca_file; end
  def ca_file=(_arg0); end
  def ca_path; end
  def ca_path=(_arg0); end
  def cert; end
  def cert=(_arg0); end
  def cert_store; end
  def cert_store=(_arg0); end
  def ciphers; end
  def ciphers=(_arg0); end
  def close_on_empty_response; end
  def close_on_empty_response=(_arg0); end
  def continue_timeout; end
  def continue_timeout=(sec); end
  def copy(path, initheader = T.unsafe(nil)); end
  def delete(path, initheader = T.unsafe(nil)); end
  def extra_chain_cert; end
  def extra_chain_cert=(_arg0); end
  def finish; end
  def get(path, initheader = T.unsafe(nil), dest = T.unsafe(nil), &block); end
  def get2(path, initheader = T.unsafe(nil), &block); end
  def head(path, initheader = T.unsafe(nil)); end
  def head2(path, initheader = T.unsafe(nil), &block); end
  def ignore_eof; end
  def ignore_eof=(_arg0); end
  def inspect; end
  def ipaddr; end
  def ipaddr=(addr); end
  def keep_alive_timeout; end
  def keep_alive_timeout=(_arg0); end
  def key; end
  def key=(_arg0); end
  def local_host; end
  def local_host=(_arg0); end
  def local_port; end
  def local_port=(_arg0); end
  def lock(path, body, initheader = T.unsafe(nil)); end
  def max_retries; end
  def max_retries=(retries); end
  def max_version; end
  def max_version=(_arg0); end
  def min_version; end
  def min_version=(_arg0); end
  def mkcol(path, body = T.unsafe(nil), initheader = T.unsafe(nil)); end
  def move(path, initheader = T.unsafe(nil)); end
  def open_timeout; end
  def open_timeout=(_arg0); end
  def options(path, initheader = T.unsafe(nil)); end
  def patch(path, data, initheader = T.unsafe(nil), dest = T.unsafe(nil), &block); end
  def peer_cert; end
  def port; end
  def post(path, data, initheader = T.unsafe(nil), dest = T.unsafe(nil), &block); end
  def post2(path, data, initheader = T.unsafe(nil), &block); end
  def propfind(path, body = T.unsafe(nil), initheader = T.unsafe(nil)); end
  def proppatch(path, body, initheader = T.unsafe(nil)); end
  def proxy?; end
  def proxy_address; end
  def proxy_address=(_arg0); end
  def proxy_from_env=(_arg0); end
  def proxy_from_env?; end
  def proxy_pass; end
  def proxy_pass=(_arg0); end
  def proxy_port; end
  def proxy_port=(_arg0); end
  def proxy_uri; end
  def proxy_user; end
  def proxy_user=(_arg0); end
  def proxyaddr; end
  def proxyport; end
  def put(path, data, initheader = T.unsafe(nil)); end
  def put2(path, data, initheader = T.unsafe(nil), &block); end
  def read_timeout; end
  def read_timeout=(sec); end
  def request(req, body = T.unsafe(nil), &block); end
  def request_get(path, initheader = T.unsafe(nil), &block); end
  def request_head(path, initheader = T.unsafe(nil), &block); end
  def request_post(path, data, initheader = T.unsafe(nil), &block); end
  def request_put(path, data, initheader = T.unsafe(nil), &block); end
  def response_body_encoding; end
  def response_body_encoding=(value); end
  def send_request(name, path, data = T.unsafe(nil), header = T.unsafe(nil)); end
  def set_debug_output(output); end
  def ssl_timeout; end
  def ssl_timeout=(_arg0); end
  def ssl_version; end
  def ssl_version=(_arg0); end
  def start; end
  def started?; end
  def trace(path, initheader = T.unsafe(nil)); end
  def unlock(path, body, initheader = T.unsafe(nil)); end
  def use_ssl=(flag); end
  def use_ssl?; end
  def verify_callback; end
  def verify_callback=(_arg0); end
  def verify_depth; end
  def verify_depth=(_arg0); end
  def verify_hostname; end
  def verify_hostname=(_arg0); end
  def verify_mode; end
  def verify_mode=(_arg0); end
  def write_timeout; end
  def write_timeout=(sec); end

  private

  def D(msg); end
  def addr_port; end
  def begin_transport(req); end
  def conn_address; end
  def conn_port; end
  def connect; end
  def debug(msg); end
  def do_finish; end
  def do_start; end
  def edit_path(path); end
  def end_transport(req, res); end
  def keep_alive?(req, res); end
  def on_connect; end
  def send_entity(path, data, initheader, dest, type, &block); end
  def sspi_auth(req); end
  def sspi_auth?(res); end
  def transport_request(req); end
  def unescape(value); end

  class << self
    def Proxy(p_addr = T.unsafe(nil), p_port = T.unsafe(nil), p_user = T.unsafe(nil), p_pass = T.unsafe(nil)); end
    def default_port; end
    def get(uri_or_host, path_or_headers = T.unsafe(nil), port = T.unsafe(nil)); end
    def get_print(uri_or_host, path_or_headers = T.unsafe(nil), port = T.unsafe(nil)); end
    def get_response(uri_or_host, path_or_headers = T.unsafe(nil), port = T.unsafe(nil), &block); end
    def http_default_port; end
    def https_default_port; end
    def is_version_1_1?; end
    def is_version_1_2?; end
    def new(address, port = T.unsafe(nil), p_addr = T.unsafe(nil), p_port = T.unsafe(nil), p_user = T.unsafe(nil), p_pass = T.unsafe(nil), p_no_proxy = T.unsafe(nil)); end
    def newobj(*_arg0); end
    def post(url, data, header = T.unsafe(nil)); end
    def post_form(url, params); end
    def proxy_address; end
    def proxy_class?; end
    def proxy_pass; end
    def proxy_port; end
    def proxy_user; end
    def socket_type; end
    def start(address, *arg, &block); end
    def version_1_1?; end
    def version_1_2; end
    def version_1_2?; end
  end
end

class Net::HTTP::Copy < ::Net::HTTPRequest; end
class Net::HTTP::Delete < ::Net::HTTPRequest; end
class Net::HTTP::Get < ::Net::HTTPRequest; end
class Net::HTTP::Head < ::Net::HTTPRequest; end
class Net::HTTP::Lock < ::Net::HTTPRequest; end
class Net::HTTP::Mkcol < ::Net::HTTPRequest; end
class Net::HTTP::Move < ::Net::HTTPRequest; end
class Net::HTTP::Options < ::Net::HTTPRequest; end
class Net::HTTP::Patch < ::Net::HTTPRequest; end
class Net::HTTP::Post < ::Net::HTTPRequest; end
class Net::HTTP::Propfind < ::Net::HTTPRequest; end
class Net::HTTP::Proppatch < ::Net::HTTPRequest; end

module Net::HTTP::ProxyDelta
  private

  def conn_address; end
  def conn_port; end
  def edit_path(path); end
end

class Net::HTTP::Put < ::Net::HTTPRequest; end
class Net::HTTP::Trace < ::Net::HTTPRequest; end
class Net::HTTP::Unlock < ::Net::HTTPRequest; end
class Net::HTTPAccepted < ::Net::HTTPSuccess; end
class Net::HTTPAlreadyReported < ::Net::HTTPSuccess; end
class Net::HTTPBadGateway < ::Net::HTTPServerError; end
class Net::HTTPBadRequest < ::Net::HTTPClientError; end
class Net::HTTPBadResponse < ::StandardError; end
class Net::HTTPClientError < ::Net::HTTPResponse; end
class Net::HTTPClientException < ::Net::ProtoServerError; end
class Net::HTTPConflict < ::Net::HTTPClientError; end
class Net::HTTPContinue < ::Net::HTTPInformation; end
class Net::HTTPCreated < ::Net::HTTPSuccess; end
class Net::HTTPEarlyHints < ::Net::HTTPInformation; end
class Net::HTTPError < ::Net::ProtocolError; end

module Net::HTTPExceptions
  def initialize(msg, res); end

  def data; end
  def response; end
end

class Net::HTTPExpectationFailed < ::Net::HTTPClientError; end
class Net::HTTPFailedDependency < ::Net::HTTPClientError; end
class Net::HTTPFatalError < ::Net::ProtoFatalError; end
class Net::HTTPForbidden < ::Net::HTTPClientError; end
class Net::HTTPFound < ::Net::HTTPRedirection; end
class Net::HTTPGatewayTimeout < ::Net::HTTPServerError; end

class Net::HTTPGenericRequest
  def initialize(m, reqbody, resbody, uri_or_path, initheader = T.unsafe(nil)); end

  def []=(key, val); end
  def body; end
  def body=(str); end
  def body_exist?; end
  def body_stream; end
  def body_stream=(input); end
  def decode_content; end
  def exec(sock, ver, path); end
  def inspect; end
  def method; end
  def path; end
  def request_body_permitted?; end
  def response_body_permitted?; end
  def set_body_internal(str); end
  def update_uri(addr, port, ssl); end
  def uri; end

  private

  def encode_multipart_form_data(out, params, opt); end
  def flush_buffer(out, buf, chunked_p); end
  def quote_string(str, charset); end
  def send_request_with_body(sock, ver, path, body); end
  def send_request_with_body_data(sock, ver, path, params); end
  def send_request_with_body_stream(sock, ver, path, f); end
  def supply_default_content_type; end
  def wait_for_continue(sock, ver); end
  def write_header(sock, ver, path); end
end

class Net::HTTPGenericRequest::Chunker
  def initialize(sock); end

  def finish; end
  def write(buf); end
end

class Net::HTTPGone < ::Net::HTTPClientError; end

module Net::HTTPHeader
  def [](key); end
  def []=(key, val); end
  def add_field(key, val); end
  def basic_auth(account, password); end
  def canonical_each; end
  def chunked?; end
  def connection_close?; end
  def connection_keep_alive?; end
  def content_length; end
  def content_length=(len); end
  def content_range; end
  def content_type; end
  def content_type=(type, params = T.unsafe(nil)); end
  def delete(key); end
  def each; end
  def each_capitalized; end
  def each_capitalized_name; end
  def each_header; end
  def each_key(&block); end
  def each_name(&block); end
  def each_value; end
  def fetch(key, *args, &block); end
  def form_data=(params, sep = T.unsafe(nil)); end
  def get_fields(key); end
  def initialize_http_header(initheader); end
  def key?(key); end
  def length; end
  def main_type; end
  def proxy_basic_auth(account, password); end
  def range; end
  def range=(r, e = T.unsafe(nil)); end
  def range_length; end
  def set_content_type(type, params = T.unsafe(nil)); end
  def set_form(params, enctype = T.unsafe(nil), formopt = T.unsafe(nil)); end
  def set_form_data(params, sep = T.unsafe(nil)); end
  def set_range(r, e = T.unsafe(nil)); end
  def size; end
  def sub_type; end
  def to_hash; end
  def type_params; end

  private

  def append_field_value(ary, val); end
  def basic_encode(account, password); end
  def capitalize(name); end
  def set_field(key, val); end
end

class Net::HTTPHeaderSyntaxError < ::StandardError; end
class Net::HTTPIMUsed < ::Net::HTTPSuccess; end
class Net::HTTPInformation < ::Net::HTTPResponse; end
class Net::HTTPInsufficientStorage < ::Net::HTTPServerError; end
class Net::HTTPInternalServerError < ::Net::HTTPServerError; end
class Net::HTTPLengthRequired < ::Net::HTTPClientError; end
class Net::HTTPLocked < ::Net::HTTPClientError; end
class Net::HTTPLoopDetected < ::Net::HTTPServerError; end
class Net::HTTPMethodNotAllowed < ::Net::HTTPClientError; end
class Net::HTTPMisdirectedRequest < ::Net::HTTPClientError; end
class Net::HTTPMovedPermanently < ::Net::HTTPRedirection; end
class Net::HTTPMultiStatus < ::Net::HTTPSuccess; end
class Net::HTTPMultipleChoices < ::Net::HTTPRedirection; end
class Net::HTTPNetworkAuthenticationRequired < ::Net::HTTPServerError; end
class Net::HTTPNoContent < ::Net::HTTPSuccess; end
class Net::HTTPNonAuthoritativeInformation < ::Net::HTTPSuccess; end
class Net::HTTPNotAcceptable < ::Net::HTTPClientError; end
class Net::HTTPNotExtended < ::Net::HTTPServerError; end
class Net::HTTPNotFound < ::Net::HTTPClientError; end
class Net::HTTPNotImplemented < ::Net::HTTPServerError; end
class Net::HTTPNotModified < ::Net::HTTPRedirection; end
class Net::HTTPOK < ::Net::HTTPSuccess; end
class Net::HTTPPartialContent < ::Net::HTTPSuccess; end
class Net::HTTPPayloadTooLarge < ::Net::HTTPClientError; end
class Net::HTTPPaymentRequired < ::Net::HTTPClientError; end
class Net::HTTPPermanentRedirect < ::Net::HTTPRedirection; end
class Net::HTTPPreconditionFailed < ::Net::HTTPClientError; end
class Net::HTTPPreconditionRequired < ::Net::HTTPClientError; end
class Net::HTTPProcessing < ::Net::HTTPInformation; end
class Net::HTTPProxyAuthenticationRequired < ::Net::HTTPClientError; end
class Net::HTTPRangeNotSatisfiable < ::Net::HTTPClientError; end
class Net::HTTPRedirection < ::Net::HTTPResponse; end

class Net::HTTPRequest < ::Net::HTTPGenericRequest
  def initialize(path, initheader = T.unsafe(nil)); end
end

class Net::HTTPRequestHeaderFieldsTooLarge < ::Net::HTTPClientError; end
class Net::HTTPRequestTimeout < ::Net::HTTPClientError; end
class Net::HTTPResetContent < ::Net::HTTPSuccess; end

class Net::HTTPResponse
  def initialize(httpv, code, msg); end

  def body; end
  def body=(value); end
  def body_encoding; end
  def body_encoding=(value); end
  def code; end
  def code_type; end
  def decode_content; end
  def decode_content=(_arg0); end
  def entity; end
  def error!; end
  def error_type; end
  def header; end
  def http_version; end
  def ignore_eof; end
  def ignore_eof=(_arg0); end
  def inspect; end
  def message; end
  def msg; end
  def read_body(dest = T.unsafe(nil), &block); end
  def read_header; end
  def reading_body(sock, reqmethodallowbody); end
  def response; end
  def uri; end
  def uri=(uri); end
  def value; end

  private

  def check_bom(str); end
  def detect_encoding(str, encoding = T.unsafe(nil)); end
  def extracting_encodings_from_meta_elements(value); end
  def get_attribute(ss); end
  def inflater; end
  def procdest(dest, block); end
  def read_body_0(dest); end
  def read_chunked(dest, chunk_data_io); end
  def scanning_meta(str); end
  def sniff_encoding(str, encoding = T.unsafe(nil)); end
  def stream_check; end

  class << self
    def body_permitted?; end
    def exception_type; end
    def read_new(sock); end

    private

    def each_response_header(sock); end
    def read_status_line(sock); end
    def response_class(code); end
  end
end

class Net::HTTPResponse::Inflater
  def initialize(socket); end

  def bytes_inflated; end
  def finish; end
  def inflate_adapter(dest); end
  def read(clen, dest, ignore_eof = T.unsafe(nil)); end
  def read_all(dest); end
end

class Net::HTTPRetriableError < ::Net::ProtoRetriableError; end
class Net::HTTPSeeOther < ::Net::HTTPRedirection; end
class Net::HTTPServerError < ::Net::HTTPResponse; end
class Net::HTTPServiceUnavailable < ::Net::HTTPServerError; end
class Net::HTTPSuccess < ::Net::HTTPResponse; end
class Net::HTTPSwitchProtocol < ::Net::HTTPInformation; end
class Net::HTTPTemporaryRedirect < ::Net::HTTPRedirection; end
class Net::HTTPTooManyRequests < ::Net::HTTPClientError; end
class Net::HTTPURITooLong < ::Net::HTTPClientError; end
class Net::HTTPUnauthorized < ::Net::HTTPClientError; end
class Net::HTTPUnavailableForLegalReasons < ::Net::HTTPClientError; end
class Net::HTTPUnknownResponse < ::Net::HTTPResponse; end
class Net::HTTPUnprocessableEntity < ::Net::HTTPClientError; end
class Net::HTTPUnsupportedMediaType < ::Net::HTTPClientError; end
class Net::HTTPUpgradeRequired < ::Net::HTTPClientError; end
class Net::HTTPUseProxy < ::Net::HTTPRedirection; end
class Net::HTTPVariantAlsoNegotiates < ::Net::HTTPServerError; end
class Net::HTTPVersionNotSupported < ::Net::HTTPServerError; end

class Net::InternetMessageIO < ::Net::BufferedIO
  def initialize(*_arg0, **_arg1); end

  def each_list_item; end
  def each_message_chunk; end
  def write_message(src); end
  def write_message_0(src); end
  def write_message_by_block(&block); end

  private

  def buffer_filling(buf, src); end
  def dot_stuff(s); end
  def each_crlf_line(src); end
  def using_each_crlf_line; end
end

module Net::NetPrivate; end
class Net::OpenTimeout < ::Timeout::Error; end
class Net::ProtoAuthError < ::Net::ProtocolError; end
class Net::ProtoCommandError < ::Net::ProtocolError; end
class Net::ProtoFatalError < ::Net::ProtocolError; end
class Net::ProtoRetriableError < ::Net::ProtocolError; end
class Net::ProtoServerError < ::Net::ProtocolError; end
class Net::ProtoSyntaxError < ::Net::ProtocolError; end
class Net::ProtoUnknownError < ::Net::ProtocolError; end

class Net::Protocol
  private

  def ssl_socket_connect(s, timeout); end

  class << self
    def protocol_param(name, val); end
  end
end

class Net::ProtocolError < ::StandardError; end

class Net::ReadAdapter
  def initialize(block); end

  def <<(str); end
  def inspect; end

  private

  def call_block(str); end
end

class Net::ReadTimeout < ::Timeout::Error
  def initialize(io = T.unsafe(nil)); end

  def io; end
  def message; end
end

class Net::WriteAdapter
  def initialize(writer); end

  def <<(str); end
  def inspect; end
  def print(str); end
  def printf(*args); end
  def puts(str = T.unsafe(nil)); end
  def write(str); end
end

class Net::WriteTimeout < ::Timeout::Error
  def initialize(io = T.unsafe(nil)); end

  def io; end
  def message; end
end

module OpenSSL
  private

  def Digest(name); end
  def debug; end
  def debug=(_arg0); end
  def errors; end
  def fips_mode; end
  def fips_mode=(_arg0); end

  class << self
    def Digest(name); end
    def debug; end
    def debug=(_arg0); end
    def errors; end
    def fips_mode; end
    def fips_mode=(_arg0); end
    def fixed_length_secure_compare(_arg0, _arg1); end
    def secure_compare(a, b); end
  end
end

module OpenSSL::ASN1
  private

  def BMPString(*_arg0); end
  def BitString(*_arg0); end
  def Boolean(*_arg0); end
  def EndOfContent(*_arg0); end
  def Enumerated(*_arg0); end
  def GeneralString(*_arg0); end
  def GeneralizedTime(*_arg0); end
  def GraphicString(*_arg0); end
  def IA5String(*_arg0); end
  def ISO64String(*_arg0); end
  def Integer(*_arg0); end
  def Null(*_arg0); end
  def NumericString(*_arg0); end
  def ObjectId(*_arg0); end
  def OctetString(*_arg0); end
  def PrintableString(*_arg0); end
  def Sequence(*_arg0); end
  def Set(*_arg0); end
  def T61String(*_arg0); end
  def UTCTime(*_arg0); end
  def UTF8String(*_arg0); end
  def UniversalString(*_arg0); end
  def VideotexString(*_arg0); end
  def decode(_arg0); end
  def decode_all(_arg0); end
  def traverse(_arg0); end

  class << self
    def BMPString(*_arg0); end
    def BitString(*_arg0); end
    def Boolean(*_arg0); end
    def EndOfContent(*_arg0); end
    def Enumerated(*_arg0); end
    def GeneralString(*_arg0); end
    def GeneralizedTime(*_arg0); end
    def GraphicString(*_arg0); end
    def IA5String(*_arg0); end
    def ISO64String(*_arg0); end
    def Integer(*_arg0); end
    def Null(*_arg0); end
    def NumericString(*_arg0); end
    def ObjectId(*_arg0); end
    def OctetString(*_arg0); end
    def PrintableString(*_arg0); end
    def Sequence(*_arg0); end
    def Set(*_arg0); end
    def T61String(*_arg0); end
    def UTCTime(*_arg0); end
    def UTF8String(*_arg0); end
    def UniversalString(*_arg0); end
    def VideotexString(*_arg0); end
    def decode(_arg0); end
    def decode_all(_arg0); end
    def traverse(_arg0); end
  end
end

class OpenSSL::ASN1::ASN1Data
  def initialize(_arg0, _arg1, _arg2); end

  def indefinite_length; end
  def indefinite_length=(_arg0); end
  def infinite_length; end
  def infinite_length=(_arg0); end
  def tag; end
  def tag=(_arg0); end
  def tag_class; end
  def tag_class=(_arg0); end
  def to_der; end
  def value; end
  def value=(_arg0); end
end

class OpenSSL::ASN1::ASN1Error < ::OpenSSL::OpenSSLError; end
class OpenSSL::ASN1::BMPString < ::OpenSSL::ASN1::Primitive; end

class OpenSSL::ASN1::BitString < ::OpenSSL::ASN1::Primitive
  def unused_bits; end
  def unused_bits=(_arg0); end
end

class OpenSSL::ASN1::Boolean < ::OpenSSL::ASN1::Primitive; end

class OpenSSL::ASN1::Constructive < ::OpenSSL::ASN1::ASN1Data
  include ::Enumerable

  def initialize(*_arg0); end

  def each; end
  def tagging; end
  def tagging=(_arg0); end
  def to_der; end
end

class OpenSSL::ASN1::EndOfContent < ::OpenSSL::ASN1::ASN1Data
  def initialize; end

  def to_der; end
end

class OpenSSL::ASN1::Enumerated < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::GeneralString < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::GeneralizedTime < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::GraphicString < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::IA5String < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::ISO64String < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::Integer < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::Null < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::NumericString < ::OpenSSL::ASN1::Primitive; end

class OpenSSL::ASN1::ObjectId < ::OpenSSL::ASN1::Primitive
  def ==(_arg0); end
  def ln; end
  def long_name; end
  def oid; end
  def short_name; end
  def sn; end

  class << self
    def register(_arg0, _arg1, _arg2); end
  end
end

class OpenSSL::ASN1::OctetString < ::OpenSSL::ASN1::Primitive; end

class OpenSSL::ASN1::Primitive < ::OpenSSL::ASN1::ASN1Data
  def initialize(*_arg0); end

  def tagging; end
  def tagging=(_arg0); end
  def to_der; end
end

class OpenSSL::ASN1::PrintableString < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::Sequence < ::OpenSSL::ASN1::Constructive; end
class OpenSSL::ASN1::Set < ::OpenSSL::ASN1::Constructive; end
class OpenSSL::ASN1::T61String < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::UTCTime < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::UTF8String < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::UniversalString < ::OpenSSL::ASN1::Primitive; end
class OpenSSL::ASN1::VideotexString < ::OpenSSL::ASN1::Primitive; end

class OpenSSL::BN
  def initialize(*_arg0); end

  def %(_arg0); end
  def *(_arg0); end
  def **(_arg0); end
  def +(_arg0); end
  def +@; end
  def -(_arg0); end
  def -@; end
  def /(_arg0); end
  def <<(_arg0); end
  def <=>(_arg0); end
  def ==(_arg0); end
  def ===(_arg0); end
  def >>(_arg0); end
  def abs; end
  def bit_set?(_arg0); end
  def clear_bit!(_arg0); end
  def cmp(_arg0); end
  def coerce(_arg0); end
  def copy(_arg0); end
  def eql?(_arg0); end
  def gcd(_arg0); end
  def get_flags(_arg0); end
  def hash; end
  def lshift!(_arg0); end
  def mask_bits!(_arg0); end
  def mod_add(_arg0, _arg1); end
  def mod_exp(_arg0, _arg1); end
  def mod_inverse(_arg0); end
  def mod_mul(_arg0, _arg1); end
  def mod_sqr(_arg0); end
  def mod_sqrt(_arg0); end
  def mod_sub(_arg0, _arg1); end
  def negative?; end
  def num_bits; end
  def num_bytes; end
  def odd?; end
  def one?; end
  def pretty_print(q); end
  def prime?(*_arg0); end
  def prime_fasttest?(*_arg0); end
  def rshift!(_arg0); end
  def set_bit!(_arg0); end
  def set_flags(_arg0); end
  def sqr; end
  def to_bn; end
  def to_i; end
  def to_int; end
  def to_s(*_arg0); end
  def ucmp(_arg0); end
  def zero?; end

  private

  def initialize_copy(_arg0); end

  class << self
    def generate_prime(*_arg0); end
    def pseudo_rand(*_arg0); end
    def pseudo_rand_range(_arg0); end
    def rand(*_arg0); end
    def rand_range(_arg0); end
  end
end

class OpenSSL::BNError < ::OpenSSL::OpenSSLError; end

module OpenSSL::Buffering
  def initialize(*_arg0); end

  def <<(s); end
  def close; end
  def each(eol = T.unsafe(nil)); end
  def each_byte; end
  def each_line(eol = T.unsafe(nil)); end
  def eof; end
  def eof?; end
  def flush; end
  def getbyte; end
  def getc; end
  def gets(eol = T.unsafe(nil), limit = T.unsafe(nil)); end
  def print(*args); end
  def printf(s, *args); end
  def puts(*args); end
  def read(size = T.unsafe(nil), buf = T.unsafe(nil)); end
  def read_nonblock(maxlen, buf = T.unsafe(nil), exception: T.unsafe(nil)); end
  def readchar; end
  def readline(eol = T.unsafe(nil)); end
  def readlines(eol = T.unsafe(nil)); end
  def readpartial(maxlen, buf = T.unsafe(nil)); end
  def sync; end
  def sync=(_arg0); end
  def ungetc(c); end
  def write(*s); end
  def write_nonblock(s, exception: T.unsafe(nil)); end

  private

  def consume_rbuff(size = T.unsafe(nil)); end
  def do_write(s); end
  def fill_rbuff; end
end

class OpenSSL::Buffering::Buffer < ::String
  def initialize; end

  def <<(string); end
  def concat(string); end
end

class OpenSSL::Cipher
  def initialize(_arg0); end

  def auth_data=(_arg0); end
  def auth_tag(*_arg0); end
  def auth_tag=(_arg0); end
  def auth_tag_len=(_arg0); end
  def authenticated?; end
  def block_size; end
  def ccm_data_len=(_arg0); end
  def decrypt(*_arg0); end
  def encrypt(*_arg0); end
  def final; end
  def iv=(_arg0); end
  def iv_len; end
  def iv_len=(_arg0); end
  def key=(_arg0); end
  def key_len; end
  def key_len=(_arg0); end
  def name; end
  def padding=(_arg0); end
  def pkcs5_keyivgen(*_arg0); end
  def random_iv; end
  def random_key; end
  def reset; end
  def update(*_arg0); end

  private

  def ciphers; end
  def initialize_copy(_arg0); end

  class << self
    def ciphers; end
  end
end

class OpenSSL::Cipher::AES < ::OpenSSL::Cipher
  def initialize(*args); end
end

class OpenSSL::Cipher::AES128 < ::OpenSSL::Cipher
  def initialize(mode = T.unsafe(nil)); end
end

class OpenSSL::Cipher::AES192 < ::OpenSSL::Cipher
  def initialize(mode = T.unsafe(nil)); end
end

class OpenSSL::Cipher::AES256 < ::OpenSSL::Cipher
  def initialize(mode = T.unsafe(nil)); end
end

class OpenSSL::Cipher::BF < ::OpenSSL::Cipher
  def initialize(*args); end
end

class OpenSSL::Cipher::CAST5 < ::OpenSSL::Cipher
  def initialize(*args); end
end

class OpenSSL::Cipher::Cipher < ::OpenSSL::Cipher; end
class OpenSSL::Cipher::CipherError < ::OpenSSL::OpenSSLError; end

class OpenSSL::Cipher::DES < ::OpenSSL::Cipher
  def initialize(*args); end
end

class OpenSSL::Cipher::IDEA < ::OpenSSL::Cipher
  def initialize(*args); end
end

class OpenSSL::Cipher::RC2 < ::OpenSSL::Cipher
  def initialize(*args); end
end

class OpenSSL::Cipher::RC4 < ::OpenSSL::Cipher
  def initialize(*args); end
end

class OpenSSL::Cipher::RC5 < ::OpenSSL::Cipher
  def initialize(*args); end
end

class OpenSSL::Config
  include ::Enumerable

  def initialize(*_arg0); end

  def [](_arg0); end
  def each; end
  def get_value(_arg0, _arg1); end
  def inspect; end
  def sections; end
  def to_s; end

  private

  def initialize_copy(_arg0); end

  class << self
    def load(*_arg0); end
    def parse(_arg0); end
    def parse_config(_arg0); end
  end
end

class OpenSSL::ConfigError < ::OpenSSL::OpenSSLError; end

class OpenSSL::Digest < ::Digest::Class
  def initialize(*_arg0); end

  def <<(_arg0); end
  def block_length; end
  def digest_length; end
  def name; end
  def reset; end
  def update(_arg0); end

  private

  def finish(*_arg0); end
  def initialize_copy(_arg0); end

  class << self
    def digest(name, data); end
  end
end

class OpenSSL::Digest::Digest < ::OpenSSL::Digest; end
class OpenSSL::Digest::DigestError < ::OpenSSL::OpenSSLError; end

class OpenSSL::Digest::MD4 < ::OpenSSL::Digest
  def initialize(data = T.unsafe(nil)); end

  class << self
    def digest(data); end
    def hexdigest(data); end
  end
end

class OpenSSL::Digest::MD5 < ::OpenSSL::Digest
  def initialize(data = T.unsafe(nil)); end

  class << self
    def digest(data); end
    def hexdigest(data); end
  end
end

class OpenSSL::Digest::RIPEMD160 < ::OpenSSL::Digest
  def initialize(data = T.unsafe(nil)); end

  class << self
    def digest(data); end
    def hexdigest(data); end
  end
end

class OpenSSL::Digest::SHA1 < ::OpenSSL::Digest
  def initialize(data = T.unsafe(nil)); end

  class << self
    def digest(data); end
    def hexdigest(data); end
  end
end

class OpenSSL::Digest::SHA224 < ::OpenSSL::Digest
  def initialize(data = T.unsafe(nil)); end

  class << self
    def digest(data); end
    def hexdigest(data); end
  end
end

class OpenSSL::Digest::SHA256 < ::OpenSSL::Digest
  def initialize(data = T.unsafe(nil)); end

  class << self
    def digest(data); end
    def hexdigest(data); end
  end
end

class OpenSSL::Digest::SHA384 < ::OpenSSL::Digest
  def initialize(data = T.unsafe(nil)); end

  class << self
    def digest(data); end
    def hexdigest(data); end
  end
end

class OpenSSL::Digest::SHA512 < ::OpenSSL::Digest
  def initialize(data = T.unsafe(nil)); end

  class << self
    def digest(data); end
    def hexdigest(data); end
  end
end

class OpenSSL::Engine
  def cipher(_arg0); end
  def cmds; end
  def ctrl_cmd(*_arg0); end
  def digest(_arg0); end
  def finish; end
  def id; end
  def inspect; end
  def load_private_key(*_arg0); end
  def load_public_key(*_arg0); end
  def name; end
  def set_default(_arg0); end

  class << self
    def by_id(_arg0); end
    def cleanup; end
    def engines; end
    def load(*_arg0); end
  end
end

class OpenSSL::Engine::EngineError < ::OpenSSL::OpenSSLError; end

class OpenSSL::HMAC
  def initialize(_arg0, _arg1); end

  def <<(_arg0); end
  def ==(other); end
  def base64digest; end
  def digest; end
  def hexdigest; end
  def inspect; end
  def reset; end
  def to_s; end
  def update(_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def base64digest(digest, key, data); end
    def digest(digest, key, data); end
    def hexdigest(digest, key, data); end
  end
end

class OpenSSL::HMACError < ::OpenSSL::OpenSSLError; end

module OpenSSL::KDF
  private

  def hkdf(*_arg0); end
  def pbkdf2_hmac(*_arg0); end
  def scrypt(*_arg0); end

  class << self
    def hkdf(*_arg0); end
    def pbkdf2_hmac(*_arg0); end
    def scrypt(*_arg0); end
  end
end

class OpenSSL::KDF::KDFError < ::OpenSSL::OpenSSLError; end

module OpenSSL::Marshal
  mixes_in_class_methods ::OpenSSL::Marshal::ClassMethods

  def _dump(_level); end

  class << self
    def included(base); end
  end
end

module OpenSSL::Marshal::ClassMethods
  def _load(string); end
end

module OpenSSL::Netscape; end

class OpenSSL::Netscape::SPKI
  def initialize(*_arg0); end

  def challenge; end
  def challenge=(_arg0); end
  def public_key; end
  def public_key=(_arg0); end
  def sign(_arg0, _arg1); end
  def to_der; end
  def to_pem; end
  def to_s; end
  def to_text; end
  def verify(_arg0); end
end

class OpenSSL::Netscape::SPKIError < ::OpenSSL::OpenSSLError; end
module OpenSSL::OCSP; end

class OpenSSL::OCSP::BasicResponse
  def initialize(*_arg0); end

  def add_nonce(*_arg0); end
  def add_status(_arg0, _arg1, _arg2, _arg3, _arg4, _arg5, _arg6); end
  def copy_nonce(_arg0); end
  def find_response(_arg0); end
  def responses; end
  def sign(*_arg0); end
  def status; end
  def to_der; end
  def verify(*_arg0); end

  private

  def initialize_copy(_arg0); end
end

class OpenSSL::OCSP::CertificateId
  def initialize(*_arg0); end

  def cmp(_arg0); end
  def cmp_issuer(_arg0); end
  def hash_algorithm; end
  def issuer_key_hash; end
  def issuer_name_hash; end
  def serial; end
  def to_der; end

  private

  def initialize_copy(_arg0); end
end

class OpenSSL::OCSP::OCSPError < ::OpenSSL::OpenSSLError; end

class OpenSSL::OCSP::Request
  def initialize(*_arg0); end

  def add_certid(_arg0); end
  def add_nonce(*_arg0); end
  def certid; end
  def check_nonce(_arg0); end
  def sign(*_arg0); end
  def signed?; end
  def to_der; end
  def verify(*_arg0); end

  private

  def initialize_copy(_arg0); end
end

class OpenSSL::OCSP::Response
  def initialize(*_arg0); end

  def basic; end
  def status; end
  def status_string; end
  def to_der; end

  private

  def initialize_copy(_arg0); end

  class << self
    def create(_arg0, _arg1); end
  end
end

class OpenSSL::OCSP::SingleResponse
  def initialize(_arg0); end

  def cert_status; end
  def certid; end
  def check_validity(*_arg0); end
  def extensions; end
  def next_update; end
  def revocation_reason; end
  def revocation_time; end
  def this_update; end
  def to_der; end

  private

  def initialize_copy(_arg0); end
end

class OpenSSL::OpenSSLError < ::StandardError; end

class OpenSSL::PKCS12
  def initialize(*_arg0); end

  def ca_certs; end
  def certificate; end
  def key; end
  def to_der; end

  private

  def initialize_copy(_arg0); end

  class << self
    def create(*_arg0); end
  end
end

class OpenSSL::PKCS12::PKCS12Error < ::OpenSSL::OpenSSLError; end

module OpenSSL::PKCS5
  private

  def pbkdf2_hmac(pass, salt, iter, keylen, digest); end
  def pbkdf2_hmac_sha1(pass, salt, iter, keylen); end

  class << self
    def pbkdf2_hmac(pass, salt, iter, keylen, digest); end
    def pbkdf2_hmac_sha1(pass, salt, iter, keylen); end
  end
end

class OpenSSL::PKCS7
  def initialize(*_arg0); end

  def add_certificate(_arg0); end
  def add_crl(_arg0); end
  def add_data(_arg0); end
  def add_recipient(_arg0); end
  def add_signer(_arg0); end
  def certificates; end
  def certificates=(_arg0); end
  def cipher=(_arg0); end
  def crls; end
  def crls=(_arg0); end
  def data; end
  def data=(_arg0); end
  def decrypt(*_arg0); end
  def detached; end
  def detached=(_arg0); end
  def detached?; end
  def error_string; end
  def error_string=(_arg0); end
  def recipients; end
  def signers; end
  def to_der; end
  def to_pem; end
  def to_s; end
  def type; end
  def type=(_arg0); end
  def verify(*_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def encrypt(*_arg0); end
    def read_smime(_arg0); end
    def sign(*_arg0); end
    def write_smime(*_arg0); end
  end
end

class OpenSSL::PKCS7::PKCS7Error < ::OpenSSL::OpenSSLError; end

class OpenSSL::PKCS7::RecipientInfo
  def initialize(_arg0); end

  def enc_key; end
  def issuer; end
  def serial; end
end

class OpenSSL::PKCS7::SignerInfo
  def initialize(_arg0, _arg1, _arg2); end

  def issuer; end
  def serial; end
  def signed_time; end
end

module OpenSSL::PKey
  private

  def generate_key(*_arg0); end
  def generate_parameters(*_arg0); end
  def read(*_arg0); end

  class << self
    def generate_key(*_arg0); end
    def generate_parameters(*_arg0); end
    def read(*_arg0); end
  end
end

class OpenSSL::PKey::DH < ::OpenSSL::PKey::PKey
  def initialize(*_arg0); end

  def compute_key(pub_bn); end
  def export; end
  def g; end
  def generate_key!; end
  def p; end
  def params; end
  def params_ok?; end
  def priv_key; end
  def private?; end
  def pub_key; end
  def public?; end
  def public_key; end
  def q; end
  def set_key(_arg0, _arg1); end
  def set_pqg(_arg0, _arg1, _arg2); end
  def to_der; end
  def to_pem; end
  def to_s; end

  private

  def initialize_copy(_arg0); end

  class << self
    def generate(size, generator = T.unsafe(nil), &blk); end
    def new(*args, &blk); end
  end
end

class OpenSSL::PKey::DHError < ::OpenSSL::PKey::PKeyError; end

class OpenSSL::PKey::DSA < ::OpenSSL::PKey::PKey
  def initialize(*_arg0); end

  def export(*_arg0); end
  def g; end
  def p; end
  def params; end
  def priv_key; end
  def private?; end
  def pub_key; end
  def public?; end
  def public_key; end
  def q; end
  def set_key(_arg0, _arg1); end
  def set_pqg(_arg0, _arg1, _arg2); end
  def syssign(string); end
  def sysverify(digest, sig); end
  def to_der; end
  def to_pem(*_arg0); end
  def to_s(*_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def generate(size, &blk); end
    def new(*args, &blk); end
  end
end

class OpenSSL::PKey::DSAError < ::OpenSSL::PKey::PKeyError; end

class OpenSSL::PKey::EC < ::OpenSSL::PKey::PKey
  def initialize(*_arg0); end

  def check_key; end
  def dh_compute_key(pubkey); end
  def dsa_sign_asn1(data); end
  def dsa_verify_asn1(data, sig); end
  def export(*_arg0); end
  def generate_key; end
  def generate_key!; end
  def group; end
  def group=(_arg0); end
  def private?; end
  def private_key; end
  def private_key=(_arg0); end
  def private_key?; end
  def public?; end
  def public_key; end
  def public_key=(_arg0); end
  def public_key?; end
  def to_der; end
  def to_pem(*_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def builtin_curves; end
    def generate(_arg0); end
  end
end

class OpenSSL::PKey::EC::Group
  def initialize(*_arg0); end

  def ==(_arg0); end
  def asn1_flag; end
  def asn1_flag=(_arg0); end
  def cofactor; end
  def curve_name; end
  def degree; end
  def eql?(_arg0); end
  def generator; end
  def order; end
  def point_conversion_form; end
  def point_conversion_form=(_arg0); end
  def seed; end
  def seed=(_arg0); end
  def set_generator(_arg0, _arg1, _arg2); end
  def to_der; end
  def to_pem; end
  def to_text; end

  private

  def initialize_copy(_arg0); end
end

class OpenSSL::PKey::EC::Group::Error < ::OpenSSL::OpenSSLError; end

class OpenSSL::PKey::EC::Point
  def initialize(*_arg0); end

  def ==(_arg0); end
  def add(_arg0); end
  def eql?(_arg0); end
  def group; end
  def infinity?; end
  def invert!; end
  def make_affine!; end
  def mul(*_arg0); end
  def on_curve?; end
  def set_to_infinity!; end
  def to_bn(conversion_form = T.unsafe(nil)); end
  def to_octet_string(_arg0); end

  private

  def initialize_copy(_arg0); end
end

class OpenSSL::PKey::EC::Point::Error < ::OpenSSL::OpenSSLError; end
class OpenSSL::PKey::ECError < ::OpenSSL::PKey::PKeyError; end

class OpenSSL::PKey::PKey
  def initialize; end

  def compare?(_arg0); end
  def decrypt(*_arg0); end
  def derive(*_arg0); end
  def encrypt(*_arg0); end
  def inspect; end
  def oid; end
  def private_to_der(*_arg0); end
  def private_to_pem(*_arg0); end
  def public_to_der; end
  def public_to_pem; end
  def sign(*_arg0); end
  def sign_raw(*_arg0); end
  def to_text; end
  def verify(*_arg0); end
  def verify_raw(*_arg0); end
  def verify_recover(*_arg0); end
end

class OpenSSL::PKey::PKeyError < ::OpenSSL::OpenSSLError; end

class OpenSSL::PKey::RSA < ::OpenSSL::PKey::PKey
  def initialize(*_arg0); end

  def d; end
  def dmp1; end
  def dmq1; end
  def e; end
  def export(*_arg0); end
  def iqmp; end
  def n; end
  def p; end
  def params; end
  def private?; end
  def private_decrypt(data, padding = T.unsafe(nil)); end
  def private_encrypt(string, padding = T.unsafe(nil)); end
  def public?; end
  def public_decrypt(string, padding = T.unsafe(nil)); end
  def public_encrypt(data, padding = T.unsafe(nil)); end
  def public_key; end
  def q; end
  def set_crt_params(_arg0, _arg1, _arg2); end
  def set_factors(_arg0, _arg1); end
  def set_key(_arg0, _arg1, _arg2); end
  def sign_pss(*_arg0); end
  def to_der; end
  def to_pem(*_arg0); end
  def to_s(*_arg0); end
  def verify_pss(*_arg0); end

  private

  def initialize_copy(_arg0); end
  def translate_padding_mode(num); end

  class << self
    def generate(size, exp = T.unsafe(nil), &blk); end
    def new(*args, &blk); end
  end
end

class OpenSSL::PKey::RSAError < ::OpenSSL::PKey::PKeyError; end

module OpenSSL::Random
  private

  def load_random_file(_arg0); end
  def random_add(_arg0, _arg1); end
  def random_bytes(_arg0); end
  def seed(_arg0); end
  def status?; end
  def write_random_file(_arg0); end

  class << self
    def load_random_file(_arg0); end
    def random_add(_arg0, _arg1); end
    def random_bytes(_arg0); end
    def seed(_arg0); end
    def status?; end
    def write_random_file(_arg0); end
  end
end

class OpenSSL::Random::RandomError < ::OpenSSL::OpenSSLError; end

module OpenSSL::SSL
  private

  def verify_certificate_identity(cert, hostname); end
  def verify_hostname(hostname, san); end
  def verify_wildcard(domain_component, san_component); end

  class << self
    def verify_certificate_identity(cert, hostname); end
    def verify_hostname(hostname, san); end
    def verify_wildcard(domain_component, san_component); end
  end
end

class OpenSSL::SSL::SSLContext
  def initialize(version = T.unsafe(nil)); end

  def add_certificate(*_arg0); end
  def alpn_protocols; end
  def alpn_protocols=(_arg0); end
  def alpn_select_cb; end
  def alpn_select_cb=(_arg0); end
  def ca_file; end
  def ca_file=(_arg0); end
  def ca_path; end
  def ca_path=(_arg0); end
  def cert; end
  def cert=(_arg0); end
  def cert_store; end
  def cert_store=(_arg0); end
  def ciphers; end
  def ciphers=(_arg0); end
  def ciphersuites=(_arg0); end
  def client_ca; end
  def client_ca=(_arg0); end
  def client_cert_cb; end
  def client_cert_cb=(_arg0); end
  def ecdh_curves=(_arg0); end
  def enable_fallback_scsv; end
  def extra_chain_cert; end
  def extra_chain_cert=(_arg0); end
  def flush_sessions(*_arg0); end
  def freeze; end
  def key; end
  def key=(_arg0); end
  def keylog_cb; end
  def keylog_cb=(_arg0); end
  def max_version=(version); end
  def min_version=(version); end
  def npn_protocols; end
  def npn_protocols=(_arg0); end
  def npn_select_cb; end
  def npn_select_cb=(_arg0); end
  def options; end
  def options=(_arg0); end
  def renegotiation_cb; end
  def renegotiation_cb=(_arg0); end
  def security_level; end
  def security_level=(_arg0); end
  def servername_cb; end
  def servername_cb=(_arg0); end
  def session_add(_arg0); end
  def session_cache_mode; end
  def session_cache_mode=(_arg0); end
  def session_cache_size; end
  def session_cache_size=(_arg0); end
  def session_cache_stats; end
  def session_get_cb; end
  def session_get_cb=(_arg0); end
  def session_id_context; end
  def session_id_context=(_arg0); end
  def session_new_cb; end
  def session_new_cb=(_arg0); end
  def session_remove(_arg0); end
  def session_remove_cb; end
  def session_remove_cb=(_arg0); end
  def set_params(params = T.unsafe(nil)); end
  def setup; end
  def ssl_timeout; end
  def ssl_timeout=(_arg0); end
  def ssl_version=(meth); end
  def timeout; end
  def timeout=(_arg0); end
  def tmp_dh=(_arg0); end
  def tmp_dh_callback; end
  def tmp_dh_callback=(_arg0); end
  def verify_callback; end
  def verify_callback=(_arg0); end
  def verify_depth; end
  def verify_depth=(_arg0); end
  def verify_hostname; end
  def verify_hostname=(_arg0); end
  def verify_mode; end
  def verify_mode=(_arg0); end

  private

  def set_minmax_proto_version(_arg0, _arg1); end
end

class OpenSSL::SSL::SSLError < ::OpenSSL::OpenSSLError; end

class OpenSSL::SSL::SSLErrorWaitReadable < ::OpenSSL::SSL::SSLError
  include ::IO::WaitReadable
end

class OpenSSL::SSL::SSLErrorWaitWritable < ::OpenSSL::SSL::SSLError
  include ::IO::WaitWritable
end

class OpenSSL::SSL::SSLServer
  def initialize(svr, ctx); end

  def accept; end
  def close; end
  def listen(backlog = T.unsafe(nil)); end
  def shutdown(how = T.unsafe(nil)); end
  def start_immediately; end
  def start_immediately=(_arg0); end
  def to_io; end
end

class OpenSSL::SSL::SSLSocket
  include ::Enumerable

  def initialize(*_arg0); end

  def accept; end
  def accept_nonblock(*_arg0); end
  def alpn_protocol; end
  def cert; end
  def cipher; end
  def client_ca; end
  def connect; end
  def connect_nonblock(*_arg0); end
  def context; end
  def export_keying_material(*_arg0); end
  def finished_message; end
  def hostname; end
  def hostname=(_arg0); end
  def io; end
  def npn_protocol; end
  def peer_cert; end
  def peer_cert_chain; end
  def peer_finished_message; end
  def pending; end
  def post_connection_check(hostname); end
  def session; end
  def session=(_arg0); end
  def session_reused?; end
  def ssl_version; end
  def state; end
  def sync_close; end
  def sync_close=(_arg0); end
  def sysclose; end
  def sysread(*_arg0); end
  def syswrite(_arg0); end
  def tmp_key; end
  def to_io; end
  def verify_result; end

  private

  def client_cert_cb; end
  def session_get_cb; end
  def session_new_cb; end
  def stop; end
  def sysread_nonblock(*_arg0); end
  def syswrite_nonblock(*_arg0); end
  def tmp_dh_callback; end
  def using_anon_cipher?; end

  class << self
    def open(remote_host, remote_port, local_host = T.unsafe(nil), local_port = T.unsafe(nil), context: T.unsafe(nil)); end
  end
end

class OpenSSL::SSL::Session
  def initialize(_arg0); end

  def ==(_arg0); end
  def id; end
  def time; end
  def time=(_arg0); end
  def timeout; end
  def timeout=(_arg0); end
  def to_der; end
  def to_pem; end
  def to_text; end

  private

  def initialize_copy(_arg0); end
end

class OpenSSL::SSL::Session::SessionError < ::OpenSSL::OpenSSLError; end

module OpenSSL::SSL::SocketForwarder
  def addr; end
  def closed?; end
  def do_not_reverse_lookup=(flag); end
  def fcntl(*args); end
  def fileno; end
  def getsockopt(level, optname); end
  def peeraddr; end
  def setsockopt(level, optname, optval); end
end

module OpenSSL::Timestamp; end

class OpenSSL::Timestamp::Factory
  def additional_certs; end
  def additional_certs=(_arg0); end
  def allowed_digests; end
  def allowed_digests=(_arg0); end
  def create_timestamp(_arg0, _arg1, _arg2); end
  def default_policy_id; end
  def default_policy_id=(_arg0); end
  def gen_time; end
  def gen_time=(_arg0); end
  def serial_number; end
  def serial_number=(_arg0); end
end

class OpenSSL::Timestamp::Request
  def initialize(*_arg0); end

  def algorithm; end
  def algorithm=(_arg0); end
  def cert_requested=(_arg0); end
  def cert_requested?; end
  def message_imprint; end
  def message_imprint=(_arg0); end
  def nonce; end
  def nonce=(_arg0); end
  def policy_id; end
  def policy_id=(_arg0); end
  def to_der; end
  def version; end
  def version=(_arg0); end
end

class OpenSSL::Timestamp::Response
  def initialize(_arg0); end

  def failure_info; end
  def status; end
  def status_text; end
  def to_der; end
  def token; end
  def token_info; end
  def tsa_certificate; end
  def verify(*_arg0); end
end

class OpenSSL::Timestamp::TimestampError < ::OpenSSL::OpenSSLError; end

class OpenSSL::Timestamp::TokenInfo
  def initialize(_arg0); end

  def algorithm; end
  def gen_time; end
  def message_imprint; end
  def nonce; end
  def ordering; end
  def policy_id; end
  def serial_number; end
  def to_der; end
  def version; end
end

module OpenSSL::X509; end

class OpenSSL::X509::Attribute
  def initialize(*_arg0); end

  def ==(other); end
  def oid; end
  def oid=(_arg0); end
  def to_der; end
  def value; end
  def value=(_arg0); end

  private

  def initialize_copy(_arg0); end
end

class OpenSSL::X509::AttributeError < ::OpenSSL::OpenSSLError; end

class OpenSSL::X509::CRL
  include ::OpenSSL::X509::Extension::Helpers

  def initialize(*_arg0); end

  def ==(other); end
  def add_extension(_arg0); end
  def add_revoked(_arg0); end
  def extensions; end
  def extensions=(_arg0); end
  def issuer; end
  def issuer=(_arg0); end
  def last_update; end
  def last_update=(_arg0); end
  def next_update; end
  def next_update=(_arg0); end
  def revoked; end
  def revoked=(_arg0); end
  def sign(_arg0, _arg1); end
  def signature_algorithm; end
  def to_der; end
  def to_pem; end
  def to_s; end
  def to_text; end
  def verify(_arg0); end
  def version; end
  def version=(_arg0); end

  private

  def initialize_copy(_arg0); end
end

class OpenSSL::X509::CRLError < ::OpenSSL::OpenSSLError; end

class OpenSSL::X509::Certificate
  include ::OpenSSL::X509::Extension::Helpers

  def initialize(*_arg0); end

  def ==(_arg0); end
  def add_extension(_arg0); end
  def check_private_key(_arg0); end
  def extensions; end
  def extensions=(_arg0); end
  def inspect; end
  def issuer; end
  def issuer=(_arg0); end
  def not_after; end
  def not_after=(_arg0); end
  def not_before; end
  def not_before=(_arg0); end
  def pretty_print(q); end
  def public_key; end
  def public_key=(_arg0); end
  def serial; end
  def serial=(_arg0); end
  def sign(_arg0, _arg1); end
  def signature_algorithm; end
  def subject; end
  def subject=(_arg0); end
  def to_der; end
  def to_pem; end
  def to_s; end
  def to_text; end
  def verify(_arg0); end
  def version; end
  def version=(_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def load(_arg0); end
    def load_file(path); end
  end
end

class OpenSSL::X509::CertificateError < ::OpenSSL::OpenSSLError; end

class OpenSSL::X509::Extension
  def initialize(*_arg0); end

  def ==(other); end
  def critical=(_arg0); end
  def critical?; end
  def oid; end
  def oid=(_arg0); end
  def to_a; end
  def to_der; end
  def to_h; end
  def to_s; end
  def value; end
  def value=(_arg0); end
  def value_der; end

  private

  def initialize_copy(_arg0); end
end

module OpenSSL::X509::Extension::AuthorityInfoAccess
  def ca_issuer_uris; end
  def ocsp_uris; end

  private

  def parse_aia_asn1; end
end

module OpenSSL::X509::Extension::AuthorityKeyIdentifier
  def authority_key_identifier; end
end

module OpenSSL::X509::Extension::CRLDistributionPoints
  def crl_uris; end
end

module OpenSSL::X509::Extension::Helpers
  def find_extension(oid); end
end

module OpenSSL::X509::Extension::SubjectKeyIdentifier
  def subject_key_identifier; end
end

class OpenSSL::X509::ExtensionError < ::OpenSSL::OpenSSLError; end

class OpenSSL::X509::ExtensionFactory
  def initialize(*_arg0); end

  def config; end
  def config=(_arg0); end
  def create_ext(*_arg0); end
  def create_ext_from_array(ary); end
  def create_ext_from_hash(hash); end
  def create_ext_from_string(str); end
  def create_extension(*arg); end
  def crl; end
  def crl=(_arg0); end
  def issuer_certificate; end
  def issuer_certificate=(_arg0); end
  def subject_certificate; end
  def subject_certificate=(_arg0); end
  def subject_request; end
  def subject_request=(_arg0); end
end

class OpenSSL::X509::Name
  include ::Comparable

  def initialize(*_arg0); end

  def <=>(_arg0); end
  def add_entry(*_arg0); end
  def cmp(_arg0); end
  def eql?(_arg0); end
  def hash; end
  def hash_old; end
  def inspect; end
  def pretty_print(q); end
  def to_a; end
  def to_der; end
  def to_s(*_arg0); end
  def to_utf8; end

  private

  def initialize_copy(_arg0); end

  class << self
    def parse(str, template = T.unsafe(nil)); end
    def parse_openssl(str, template = T.unsafe(nil)); end
    def parse_rfc2253(str, template = T.unsafe(nil)); end
  end
end

module OpenSSL::X509::Name::RFC2253DN
  private

  def expand_hexstring(str); end
  def expand_pair(str); end
  def expand_value(str1, str2, str3); end
  def scan(dn); end

  class << self
    def expand_hexstring(str); end
    def expand_pair(str); end
    def expand_value(str1, str2, str3); end
    def scan(dn); end
  end
end

class OpenSSL::X509::NameError < ::OpenSSL::OpenSSLError; end

class OpenSSL::X509::Request
  def initialize(*_arg0); end

  def ==(other); end
  def add_attribute(_arg0); end
  def attributes; end
  def attributes=(_arg0); end
  def public_key; end
  def public_key=(_arg0); end
  def sign(_arg0, _arg1); end
  def signature_algorithm; end
  def subject; end
  def subject=(_arg0); end
  def to_der; end
  def to_pem; end
  def to_s; end
  def to_text; end
  def verify(_arg0); end
  def version; end
  def version=(_arg0); end

  private

  def initialize_copy(_arg0); end
end

class OpenSSL::X509::RequestError < ::OpenSSL::OpenSSLError; end

class OpenSSL::X509::Revoked
  def initialize(*_arg0); end

  def ==(other); end
  def add_extension(_arg0); end
  def extensions; end
  def extensions=(_arg0); end
  def serial; end
  def serial=(_arg0); end
  def time; end
  def time=(_arg0); end
  def to_der; end

  private

  def initialize_copy(_arg0); end
end

class OpenSSL::X509::RevokedError < ::OpenSSL::OpenSSLError; end

class OpenSSL::X509::Store
  def initialize(*_arg0); end

  def add_cert(_arg0); end
  def add_crl(_arg0); end
  def add_file(_arg0); end
  def add_path(_arg0); end
  def chain; end
  def error; end
  def error_string; end
  def flags=(_arg0); end
  def purpose=(_arg0); end
  def set_default_paths; end
  def time=(_arg0); end
  def trust=(_arg0); end
  def verify(*_arg0); end
  def verify_callback; end
  def verify_callback=(_arg0); end
end

class OpenSSL::X509::StoreContext
  def initialize(*_arg0); end

  def chain; end
  def cleanup; end
  def current_cert; end
  def current_crl; end
  def error; end
  def error=(_arg0); end
  def error_depth; end
  def error_string; end
  def flags=(_arg0); end
  def purpose=(_arg0); end
  def time=(_arg0); end
  def trust=(_arg0); end
  def verify; end
end

class OpenSSL::X509::StoreError < ::OpenSSL::OpenSSLError; end

class Resolv
  def initialize(resolvers = T.unsafe(nil)); end

  def each_address(name); end
  def each_name(address); end
  def getaddress(name); end
  def getaddresses(name); end
  def getname(address); end
  def getnames(address); end

  class << self
    def each_address(name, &block); end
    def each_name(address, &proc); end
    def getaddress(name); end
    def getaddresses(name); end
    def getname(address); end
    def getnames(address); end
  end
end

class Resolv::DNS
  def initialize(config_info = T.unsafe(nil)); end

  def close; end
  def each_address(name); end
  def each_name(address); end
  def each_resource(name, typeclass, &proc); end
  def extract_resources(msg, name, typeclass); end
  def fetch_resource(name, typeclass); end
  def getaddress(name); end
  def getaddresses(name); end
  def getname(address); end
  def getnames(address); end
  def getresource(name, typeclass); end
  def getresources(name, typeclass); end
  def lazy_initialize; end
  def make_tcp_requester(host, port); end
  def make_udp_requester; end
  def timeouts=(values); end

  private

  def use_ipv6?; end

  class << self
    def allocate_request_id(host, port); end
    def bind_random_port(udpsock, bind_host = T.unsafe(nil)); end
    def free_request_id(host, port, id); end
    def open(*args); end
    def random(arg); end
  end
end

class Resolv::DNS::Config
  def initialize(config_info = T.unsafe(nil)); end

  def generate_candidates(name); end
  def generate_timeouts; end
  def lazy_initialize; end
  def nameserver_port; end
  def resolv(name); end
  def single?; end
  def timeouts=(values); end

  class << self
    def default_config_hash(filename = T.unsafe(nil)); end
    def parse_resolv_conf(filename); end
  end
end

class Resolv::DNS::Config::NXDomain < ::Resolv::ResolvError; end
class Resolv::DNS::Config::OtherResolvError < ::Resolv::ResolvError; end
class Resolv::DNS::DecodeError < ::StandardError; end
class Resolv::DNS::EncodeError < ::StandardError; end

module Resolv::DNS::Label
  class << self
    def split(arg); end
  end
end

class Resolv::DNS::Label::Str
  def initialize(string); end

  def ==(other); end
  def downcase; end
  def eql?(other); end
  def hash; end
  def inspect; end
  def string; end
  def to_s; end
end

class Resolv::DNS::Message
  def initialize(id = T.unsafe(nil)); end

  def ==(other); end
  def aa; end
  def aa=(_arg0); end
  def add_additional(name, ttl, data); end
  def add_answer(name, ttl, data); end
  def add_authority(name, ttl, data); end
  def add_question(name, typeclass); end
  def additional; end
  def answer; end
  def authority; end
  def each_additional; end
  def each_answer; end
  def each_authority; end
  def each_question; end
  def each_resource; end
  def encode; end
  def id; end
  def id=(_arg0); end
  def opcode; end
  def opcode=(_arg0); end
  def qr; end
  def qr=(_arg0); end
  def question; end
  def ra; end
  def ra=(_arg0); end
  def rcode; end
  def rcode=(_arg0); end
  def rd; end
  def rd=(_arg0); end
  def tc; end
  def tc=(_arg0); end

  class << self
    def decode(m); end
  end
end

class Resolv::DNS::Message::MessageDecoder
  def initialize(data); end

  def get_bytes(len = T.unsafe(nil)); end
  def get_label; end
  def get_labels; end
  def get_length16; end
  def get_name; end
  def get_question; end
  def get_rr; end
  def get_string; end
  def get_string_list; end
  def get_unpack(template); end
  def inspect; end
end

class Resolv::DNS::Message::MessageEncoder
  def initialize; end

  def put_bytes(d); end
  def put_label(d); end
  def put_labels(d); end
  def put_length16; end
  def put_name(d); end
  def put_pack(template, *d); end
  def put_string(d); end
  def put_string_list(ds); end
  def to_s; end
end

class Resolv::DNS::Name
  def initialize(labels, absolute = T.unsafe(nil)); end

  def ==(other); end
  def [](i); end
  def absolute?; end
  def eql?(other); end
  def hash; end
  def inspect; end
  def length; end
  def subdomain_of?(other); end
  def to_a; end
  def to_s; end

  class << self
    def create(arg); end
  end
end

module Resolv::DNS::OpCode; end

class Resolv::DNS::Query
  def encode_rdata(msg); end

  class << self
    def decode_rdata(msg); end
  end
end

module Resolv::DNS::RCode; end

class Resolv::DNS::Requester
  def initialize; end

  def close; end
  def request(sender, tout); end
  def sender_for(addr, msg); end
end

class Resolv::DNS::Requester::ConnectedUDP < ::Resolv::DNS::Requester
  def initialize(host, port = T.unsafe(nil)); end

  def close; end
  def lazy_initialize; end
  def recv_reply(readable_socks); end
  def sender(msg, data, host = T.unsafe(nil), port = T.unsafe(nil)); end
end

class Resolv::DNS::Requester::ConnectedUDP::Sender < ::Resolv::DNS::Requester::Sender
  def data; end
  def send; end
end

class Resolv::DNS::Requester::MDNSOneShot < ::Resolv::DNS::Requester::UnconnectedUDP
  def sender(msg, data, host, port = T.unsafe(nil)); end
  def sender_for(addr, msg); end
end

class Resolv::DNS::Requester::RequestError < ::StandardError; end

class Resolv::DNS::Requester::Sender
  def initialize(msg, data, sock); end
end

class Resolv::DNS::Requester::TCP < ::Resolv::DNS::Requester
  def initialize(host, port = T.unsafe(nil)); end

  def close; end
  def recv_reply(readable_socks); end
  def sender(msg, data, host = T.unsafe(nil), port = T.unsafe(nil)); end
end

class Resolv::DNS::Requester::TCP::Sender < ::Resolv::DNS::Requester::Sender
  def data; end
  def send; end
end

class Resolv::DNS::Requester::UnconnectedUDP < ::Resolv::DNS::Requester
  def initialize(*nameserver_port); end

  def close; end
  def lazy_initialize; end
  def recv_reply(readable_socks); end
  def sender(msg, data, host, port = T.unsafe(nil)); end
end

class Resolv::DNS::Requester::UnconnectedUDP::Sender < ::Resolv::DNS::Requester::Sender
  def initialize(msg, data, sock, host, port); end

  def data; end
  def send; end
end

class Resolv::DNS::Resource < ::Resolv::DNS::Query
  def ==(other); end
  def encode_rdata(msg); end
  def eql?(other); end
  def hash; end
  def ttl; end

  class << self
    def decode_rdata(msg); end
    def get_class(type_value, class_value); end
  end
end

class Resolv::DNS::Resource::ANY < ::Resolv::DNS::Query; end
class Resolv::DNS::Resource::CNAME < ::Resolv::DNS::Resource::DomainName; end

class Resolv::DNS::Resource::DomainName < ::Resolv::DNS::Resource
  def initialize(name); end

  def encode_rdata(msg); end
  def name; end

  class << self
    def decode_rdata(msg); end
  end
end

class Resolv::DNS::Resource::Generic < ::Resolv::DNS::Resource
  def initialize(data); end

  def data; end
  def encode_rdata(msg); end

  class << self
    def create(type_value, class_value); end
    def decode_rdata(msg); end
  end
end

class Resolv::DNS::Resource::HINFO < ::Resolv::DNS::Resource
  def initialize(cpu, os); end

  def cpu; end
  def encode_rdata(msg); end
  def os; end

  class << self
    def decode_rdata(msg); end
  end
end

module Resolv::DNS::Resource::IN; end

class Resolv::DNS::Resource::IN::A < ::Resolv::DNS::Resource
  def initialize(address); end

  def address; end
  def encode_rdata(msg); end

  class << self
    def decode_rdata(msg); end
  end
end

class Resolv::DNS::Resource::IN::AAAA < ::Resolv::DNS::Resource
  def initialize(address); end

  def address; end
  def encode_rdata(msg); end

  class << self
    def decode_rdata(msg); end
  end
end

class Resolv::DNS::Resource::IN::ANY < ::Resolv::DNS::Resource::ANY; end
class Resolv::DNS::Resource::IN::CNAME < ::Resolv::DNS::Resource::CNAME; end
class Resolv::DNS::Resource::IN::HINFO < ::Resolv::DNS::Resource::HINFO; end
class Resolv::DNS::Resource::IN::LOC < ::Resolv::DNS::Resource::LOC; end
class Resolv::DNS::Resource::IN::MINFO < ::Resolv::DNS::Resource::MINFO; end
class Resolv::DNS::Resource::IN::MX < ::Resolv::DNS::Resource::MX; end
class Resolv::DNS::Resource::IN::NS < ::Resolv::DNS::Resource::NS; end
class Resolv::DNS::Resource::IN::PTR < ::Resolv::DNS::Resource::PTR; end
class Resolv::DNS::Resource::IN::SOA < ::Resolv::DNS::Resource::SOA; end

class Resolv::DNS::Resource::IN::SRV < ::Resolv::DNS::Resource
  def initialize(priority, weight, port, target); end

  def encode_rdata(msg); end
  def port; end
  def priority; end
  def target; end
  def weight; end

  class << self
    def decode_rdata(msg); end
  end
end

class Resolv::DNS::Resource::IN::TXT < ::Resolv::DNS::Resource::TXT; end

class Resolv::DNS::Resource::IN::WKS < ::Resolv::DNS::Resource
  def initialize(address, protocol, bitmap); end

  def address; end
  def bitmap; end
  def encode_rdata(msg); end
  def protocol; end

  class << self
    def decode_rdata(msg); end
  end
end

class Resolv::DNS::Resource::LOC < ::Resolv::DNS::Resource
  def initialize(version, ssize, hprecision, vprecision, latitude, longitude, altitude); end

  def altitude; end
  def encode_rdata(msg); end
  def hprecision; end
  def latitude; end
  def longitude; end
  def ssize; end
  def version; end
  def vprecision; end

  class << self
    def decode_rdata(msg); end
  end
end

class Resolv::DNS::Resource::MINFO < ::Resolv::DNS::Resource
  def initialize(rmailbx, emailbx); end

  def emailbx; end
  def encode_rdata(msg); end
  def rmailbx; end

  class << self
    def decode_rdata(msg); end
  end
end

class Resolv::DNS::Resource::MX < ::Resolv::DNS::Resource
  def initialize(preference, exchange); end

  def encode_rdata(msg); end
  def exchange; end
  def preference; end

  class << self
    def decode_rdata(msg); end
  end
end

class Resolv::DNS::Resource::NS < ::Resolv::DNS::Resource::DomainName; end
class Resolv::DNS::Resource::PTR < ::Resolv::DNS::Resource::DomainName; end

class Resolv::DNS::Resource::SOA < ::Resolv::DNS::Resource
  def initialize(mname, rname, serial, refresh, retry_, expire, minimum); end

  def encode_rdata(msg); end
  def expire; end
  def minimum; end
  def mname; end
  def refresh; end
  def retry; end
  def rname; end
  def serial; end

  class << self
    def decode_rdata(msg); end
  end
end

class Resolv::DNS::Resource::TXT < ::Resolv::DNS::Resource
  def initialize(first_string, *rest_strings); end

  def data; end
  def encode_rdata(msg); end
  def strings; end

  class << self
    def decode_rdata(msg); end
  end
end

class Resolv::Hosts
  def initialize(filename = T.unsafe(nil)); end

  def each_address(name, &proc); end
  def each_name(address, &proc); end
  def getaddress(name); end
  def getaddresses(name); end
  def getname(address); end
  def getnames(address); end
  def lazy_initialize; end
end

class Resolv::IPv4
  def initialize(address); end

  def ==(other); end
  def address; end
  def eql?(other); end
  def hash; end
  def inspect; end
  def to_name; end
  def to_s; end

  class << self
    def create(arg); end
  end
end

class Resolv::IPv6
  def initialize(address); end

  def ==(other); end
  def address; end
  def eql?(other); end
  def hash; end
  def inspect; end
  def to_name; end
  def to_s; end

  class << self
    def create(arg); end
  end
end

module Resolv::LOC; end

class Resolv::LOC::Alt
  def initialize(altitude); end

  def ==(other); end
  def altitude; end
  def eql?(other); end
  def hash; end
  def inspect; end
  def to_s; end

  class << self
    def create(arg); end
  end
end

class Resolv::LOC::Coord
  def initialize(coordinates, orientation); end

  def ==(other); end
  def coordinates; end
  def eql?(other); end
  def hash; end
  def inspect; end
  def orientation; end
  def to_s; end

  class << self
    def create(arg); end
  end
end

class Resolv::LOC::Size
  def initialize(scalar); end

  def ==(other); end
  def eql?(other); end
  def hash; end
  def inspect; end
  def scalar; end
  def to_s; end

  class << self
    def create(arg); end
  end
end

class Resolv::MDNS < ::Resolv::DNS
  def initialize(config_info = T.unsafe(nil)); end

  def each_address(name); end
  def make_udp_requester; end
end

class Resolv::ResolvError < ::StandardError; end
class Resolv::ResolvTimeout < ::Timeout::Error; end

module SecureRandom
  class << self
    def bytes(n); end
    def gen_random(n); end

    private

    def gen_random_openssl(n); end
    def gen_random_urandom(n); end
  end
end

class Socket < ::BasicSocket
  def initialize(*_arg0); end

  def accept; end
  def accept_nonblock(exception: T.unsafe(nil)); end
  def bind(_arg0); end
  def connect(_arg0); end
  def connect_nonblock(addr, exception: T.unsafe(nil)); end
  def ipv6only!; end
  def listen(_arg0); end
  def recvfrom(*_arg0); end
  def recvfrom_nonblock(len, flag = T.unsafe(nil), str = T.unsafe(nil), exception: T.unsafe(nil)); end
  def sysaccept; end

  private

  def __accept_nonblock(_arg0); end
  def __connect_nonblock(_arg0, _arg1); end
  def __recvfrom_nonblock(_arg0, _arg1, _arg2, _arg3); end

  class << self
    def accept_loop(*sockets); end
    def getaddrinfo(*_arg0); end
    def gethostbyaddr(*_arg0); end
    def gethostbyname(_arg0); end
    def gethostname; end
    def getifaddrs; end
    def getnameinfo(*_arg0); end
    def getservbyname(*_arg0); end
    def getservbyport(*_arg0); end
    def ip_address_list; end
    def pack_sockaddr_in(_arg0, _arg1); end
    def pack_sockaddr_un(_arg0); end
    def pair(*_arg0); end
    def sockaddr_in(_arg0, _arg1); end
    def sockaddr_un(_arg0); end
    def socketpair(*_arg0); end
    def tcp(host, port, local_host = T.unsafe(nil), local_port = T.unsafe(nil), connect_timeout: T.unsafe(nil), resolv_timeout: T.unsafe(nil)); end
    def tcp_server_loop(host = T.unsafe(nil), port, &b); end
    def tcp_server_sockets(host = T.unsafe(nil), port); end
    def udp_server_loop(host = T.unsafe(nil), port, &b); end
    def udp_server_loop_on(sockets, &b); end
    def udp_server_recv(sockets); end
    def udp_server_sockets(host = T.unsafe(nil), port); end
    def unix(path); end
    def unix_server_loop(path, &b); end
    def unix_server_socket(path); end
    def unpack_sockaddr_in(_arg0); end
    def unpack_sockaddr_un(_arg0); end

    private

    def ip_sockets_port0(ai_list, reuseaddr); end
    def tcp_server_sockets_port0(host); end
    def unix_socket_abstract_name?(path); end
  end
end

class Socket::AncillaryData
  def initialize(_arg0, _arg1, _arg2, _arg3); end

  def cmsg_is?(_arg0, _arg1); end
  def data; end
  def family; end
  def inspect; end
  def int; end
  def ip_pktinfo; end
  def ipv6_pktinfo; end
  def ipv6_pktinfo_addr; end
  def ipv6_pktinfo_ifindex; end
  def level; end
  def timestamp; end
  def type; end
  def unix_rights; end

  class << self
    def int(_arg0, _arg1, _arg2, _arg3); end
    def ip_pktinfo(*_arg0); end
    def ipv6_pktinfo(_arg0, _arg1); end
    def unix_rights(*_arg0); end
  end
end

module Socket::Constants; end

class Socket::Ifaddr
  def addr; end
  def broadaddr; end
  def dstaddr; end
  def flags; end
  def ifindex; end
  def inspect; end
  def name; end
  def netmask; end
end

class Socket::Option
  def initialize(_arg0, _arg1, _arg2, _arg3); end

  def bool; end
  def byte; end
  def data; end
  def family; end
  def inspect; end
  def int; end
  def ipv4_multicast_loop; end
  def ipv4_multicast_ttl; end
  def level; end
  def linger; end
  def optname; end
  def to_s; end
  def unpack(_arg0); end

  class << self
    def bool(_arg0, _arg1, _arg2, _arg3); end
    def byte(_arg0, _arg1, _arg2, _arg3); end
    def int(_arg0, _arg1, _arg2, _arg3); end
    def ipv4_multicast_loop(_arg0); end
    def ipv4_multicast_ttl(_arg0); end
    def linger(_arg0, _arg1); end
  end
end

class Socket::UDPSource
  def initialize(remote_address, local_address, &reply_proc); end

  def inspect; end
  def local_address; end
  def remote_address; end
  def reply(msg); end
end

class SocketError < ::StandardError; end

class TCPServer < ::TCPSocket
  def initialize(*_arg0); end

  def accept; end
  def accept_nonblock(exception: T.unsafe(nil)); end
  def listen(_arg0); end
  def sysaccept; end

  private

  def __accept_nonblock(_arg0); end
end

class TCPSocket < ::IPSocket
  def initialize(*_arg0); end

  class << self
    def gethostbyname(_arg0); end
  end
end

module Timeout
  private

  def timeout(sec, klass = T.unsafe(nil), message = T.unsafe(nil), &block); end

  class << self
    def ensure_timeout_thread_created; end
    def timeout(sec, klass = T.unsafe(nil), message = T.unsafe(nil), &block); end

    private

    def create_timeout_thread; end
  end
end

class Timeout::Error < ::RuntimeError
  class << self
    def handle_timeout(message); end
  end
end

class Timeout::ExitException < ::Exception
  def exception(*_arg0); end
end

class UDPSocket < ::IPSocket
  def initialize(*_arg0); end

  def bind(_arg0, _arg1); end
  def connect(_arg0, _arg1); end
  def recvfrom_nonblock(len, flag = T.unsafe(nil), outbuf = T.unsafe(nil), exception: T.unsafe(nil)); end
  def send(*_arg0); end

  private

  def __recvfrom_nonblock(_arg0, _arg1, _arg2, _arg3); end
end

class UNIXServer < ::UNIXSocket
  def initialize(_arg0); end

  def accept; end
  def accept_nonblock(exception: T.unsafe(nil)); end
  def listen(_arg0); end
  def sysaccept; end

  private

  def __accept_nonblock(_arg0); end
end

class UNIXSocket < ::BasicSocket
  def initialize(_arg0); end

  def addr; end
  def path; end
  def peeraddr; end
  def recv_io(*_arg0); end
  def recvfrom(*_arg0); end
  def send_io(_arg0); end

  class << self
    def pair(*_arg0); end
    def socketpair(*_arg0); end
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
