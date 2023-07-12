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

module DRb
  private

  def config; end
  def current_server; end
  def fetch_server(uri); end
  def front; end
  def here?(uri); end
  def install_acl(acl); end
  def install_id_conv(idconv); end
  def mutex; end
  def primary_server; end
  def primary_server=(_arg0); end
  def regist_server(server); end
  def remove_server(server); end
  def start_service(uri = T.unsafe(nil), front = T.unsafe(nil), config = T.unsafe(nil)); end
  def stop_service; end
  def thread; end
  def to_id(obj); end
  def to_obj(ref); end
  def uri; end

  class << self
    def config; end
    def current_server; end
    def fetch_server(uri); end
    def front; end
    def here?(uri); end
    def install_acl(acl); end
    def install_id_conv(idconv); end
    def mutex; end
    def primary_server; end
    def primary_server=(_arg0); end
    def regist_server(server); end
    def remove_server(server); end
    def start_service(uri = T.unsafe(nil), front = T.unsafe(nil), config = T.unsafe(nil)); end
    def stop_service; end
    def thread; end
    def to_id(obj); end
    def to_obj(ref); end
    def uri; end
  end
end

class DRb::DRbArray
  def initialize(ary); end

  def _dump(lv); end

  class << self
    def _load(s); end
  end
end

class DRb::DRbBadScheme < ::DRb::DRbError; end
class DRb::DRbBadURI < ::DRb::DRbError; end

class DRb::DRbConn
  def initialize(remote_uri); end

  def alive?; end
  def close; end
  def send_message(ref, msg_id, arg, block); end
  def uri; end

  class << self
    def make_pool; end
    def open(remote_uri); end
    def stop_pool; end
  end
end

class DRb::DRbConnError < ::DRb::DRbError; end
class DRb::DRbError < ::RuntimeError; end

class DRb::DRbIdConv
  def to_id(obj); end
  def to_obj(ref); end
end

class DRb::DRbMessage
  def initialize(config); end

  def dump(obj, error = T.unsafe(nil)); end
  def load(soc); end
  def recv_reply(stream); end
  def recv_request(stream); end
  def send_reply(stream, succ, result); end
  def send_request(stream, ref, msg_id, arg, b); end

  private

  def make_proxy(obj, error = T.unsafe(nil)); end
end

class DRb::DRbObject
  def initialize(obj, uri = T.unsafe(nil)); end

  def ==(other); end
  def __drbref; end
  def __drburi; end
  def _dump(lv); end
  def eql?(other); end
  def hash; end
  def method_missing(msg_id, *a, **_arg2, &b); end
  def pretty_print(q); end
  def pretty_print_cycle(q); end
  def respond_to?(msg_id, priv = T.unsafe(nil)); end

  class << self
    def _load(s); end
    def new_with(uri, ref); end
    def new_with_uri(uri); end
    def prepare_backtrace(uri, result); end
    def with_friend(uri); end
  end
end

module DRb::DRbObservable
  def notify_observers(*arg); end
end

module DRb::DRbProtocol
  private

  def add_protocol(prot); end
  def auto_load(uri); end
  def open(uri, config, first = T.unsafe(nil)); end
  def open_server(uri, config, first = T.unsafe(nil)); end
  def uri_option(uri, config, first = T.unsafe(nil)); end

  class << self
    def add_protocol(prot); end
    def auto_load(uri); end
    def open(uri, config, first = T.unsafe(nil)); end
    def open_server(uri, config, first = T.unsafe(nil)); end
    def uri_option(uri, config, first = T.unsafe(nil)); end
  end
end

class DRb::DRbRemoteError < ::DRb::DRbError
  def initialize(error); end

  def reason; end
end

class DRb::DRbSSLSocket < ::DRb::DRbTCPSocket
  def initialize(uri, soc, config, is_established); end

  def accept; end
  def close; end
  def stream; end

  class << self
    def open(uri, config); end
    def open_server(uri, config); end
    def parse_uri(uri); end
    def uri_option(uri, config); end
  end
end

class DRb::DRbSSLSocket::SSLConfig
  def initialize(config); end

  def [](key); end
  def accept(tcp); end
  def connect(tcp); end
  def setup_certificate; end
  def setup_ssl_context; end
end

class DRb::DRbServer
  def initialize(uri = T.unsafe(nil), front = T.unsafe(nil), config_or_acl = T.unsafe(nil)); end

  def alive?; end
  def check_insecure_method(obj, msg_id); end
  def config; end
  def front; end
  def here?(uri); end
  def stop_service; end
  def thread; end
  def to_id(obj); end
  def to_obj(ref); end
  def uri; end
  def verbose; end
  def verbose=(v); end

  private

  def any_to_s(obj); end
  def error_print(exception); end
  def insecure_method?(msg_id); end
  def main_loop; end
  def run; end
  def shutdown; end

  class << self
    def default_acl(acl); end
    def default_argc_limit(argc); end
    def default_id_conv(idconv); end
    def default_load_limit(sz); end
    def make_config(hash = T.unsafe(nil)); end
    def verbose; end
    def verbose=(on); end
  end
end

class DRb::DRbServer::InvokeMethod
  def initialize(drb_server, client); end

  def perform; end

  private

  def check_insecure_method; end
  def init_with_client; end
  def perform_without_block; end
  def setup_message; end
end

module DRb::DRbServer::InvokeMethod18Mixin
  def block_yield(x); end
  def perform_with_block; end
end

class DRb::DRbServerNotFound < ::DRb::DRbError; end

class DRb::DRbTCPSocket
  def initialize(uri, soc, config = T.unsafe(nil)); end

  def accept; end
  def alive?; end
  def close; end
  def peeraddr; end
  def recv_reply; end
  def recv_request; end
  def send_reply(succ, result); end
  def send_request(ref, msg_id, arg, b); end
  def set_sockopt(soc); end
  def shutdown; end
  def stream; end
  def uri; end

  private

  def accept_or_shutdown; end
  def close_shutdown_pipe; end

  class << self
    def getservername; end
    def open(uri, config); end
    def open_server(uri, config); end
    def open_server_inaddr_any(host, port); end
    def parse_uri(uri); end
    def uri_option(uri, config); end
  end
end

class DRb::DRbUNIXSocket < ::DRb::DRbTCPSocket
  def initialize(uri, soc, config = T.unsafe(nil), server_mode = T.unsafe(nil)); end

  def accept; end
  def close; end
  def set_sockopt(soc); end

  class << self
    def open(uri, config); end
    def open_server(uri, config); end
    def parse_uri(uri); end
    def temp_server; end
    def uri_option(uri, config); end
  end
end

class DRb::DRbURIOption
  def initialize(option); end

  def ==(other); end
  def eql?(other); end
  def hash; end
  def option; end
  def to_s; end
end

module DRb::DRbUndumped
  def _dump(dummy); end
end

class DRb::DRbUnknown
  def initialize(err, buf); end

  def _dump(lv); end
  def buf; end
  def exception; end
  def name; end
  def reload; end

  class << self
    def _load(s); end
  end
end

class DRb::DRbUnknownError < ::DRb::DRbError
  def initialize(unknown); end

  def _dump(lv); end
  def unknown; end

  class << self
    def _load(s); end
  end
end

class DRb::ExtServ
  def initialize(there, name, server = T.unsafe(nil)); end

  def alive?; end
  def front; end
  def server; end
  def stop_service; end
end

class DRb::ExtServManager
  def initialize; end

  def regist(name, ro); end
  def register(name, ro); end
  def service(name); end
  def unregist(name); end
  def unregister(name); end
  def uri; end
  def uri=(_arg0); end

  private

  def invoke_service(name); end
  def invoke_service_command(name, command); end
  def invoke_thread; end

  class << self
    def command; end
    def command=(cmd); end
  end
end

class DRb::GW
  def initialize; end

  def [](key); end
  def []=(key, v); end
end

class DRb::GWIdConv < ::DRb::DRbIdConv
  def to_obj(ref); end
end

class DRb::ThreadObject
  def initialize(&blk); end

  def _execute; end
  def alive?; end
  def kill; end
  def method_missing(msg, *arg, &blk); end
end

class DRb::TimerIdConv < ::DRb::DRbIdConv
  def initialize(keeping = T.unsafe(nil)); end

  def to_id(obj); end
  def to_obj(ref); end
end

class DRb::TimerIdConv::TimerHolder2
  def initialize(keeping = T.unsafe(nil)); end

  def add(obj); end
  def fetch(key); end

  private

  def invoke_keeper; end
  def on_gc; end
  def peek(key); end
  def rotate; end
end

class DRb::TimerIdConv::TimerHolder2::InvalidIndexError < ::RuntimeError; end

class DRb::WeakIdConv < ::DRb::DRbIdConv
  def initialize; end

  def to_id(obj); end
  def to_obj(ref); end
end

class DRb::WeakIdConv::WeakSet
  def initialize; end

  def add(obj); end
  def fetch(ref); end
end

module Forwardable
  def def_delegator(accessor, method, ali = T.unsafe(nil)); end
  def def_delegators(accessor, *methods); end
  def def_instance_delegator(accessor, method, ali = T.unsafe(nil)); end
  def def_instance_delegators(accessor, *methods); end
  def delegate(hash); end
  def instance_delegate(hash); end

  class << self
    def _compile_method(src, file, line); end
    def _delegator_method(obj, accessor, method, ali); end
    def _valid_method?(method); end
    def debug; end
    def debug=(_arg0); end
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
    def getaddress(host); end
    def original_resolv_getaddress(_arg0); end
  end
end

module Rinda; end

class Rinda::DRbObjectTemplate
  def initialize(uri = T.unsafe(nil), ref = T.unsafe(nil)); end

  def ===(ro); end
end

class Rinda::InvalidHashTupleKey < ::Rinda::RindaError; end

class Rinda::NotifyTemplateEntry < ::Rinda::TemplateEntry
  def initialize(place, event, tuple, expires = T.unsafe(nil)); end

  def each; end
  def notify(ev); end
  def pop; end
end

class Rinda::RequestCanceledError < ::ThreadError; end
class Rinda::RequestExpiredError < ::ThreadError; end
class Rinda::RindaError < ::RuntimeError; end

class Rinda::RingFinger
  def initialize(broadcast_list = T.unsafe(nil), port = T.unsafe(nil)); end

  def broadcast_list; end
  def broadcast_list=(_arg0); end
  def each; end
  def lookup_ring(timeout = T.unsafe(nil), &block); end
  def lookup_ring_any(timeout = T.unsafe(nil)); end
  def make_socket(address); end
  def multicast_hops; end
  def multicast_hops=(_arg0); end
  def multicast_interface; end
  def multicast_interface=(_arg0); end
  def port; end
  def port=(_arg0); end
  def primary; end
  def primary=(_arg0); end
  def send_message(address, message); end
  def to_a; end

  class << self
    def finger; end
    def primary; end
    def to_a; end
  end
end

class Rinda::RingProvider
  def initialize(klass, front, desc, renewer = T.unsafe(nil)); end

  def provide; end
end

class Rinda::RingServer
  def initialize(ts, addresses = T.unsafe(nil), port = T.unsafe(nil)); end

  def do_reply; end
  def do_write(msg); end
  def make_socket(address, interface_address = T.unsafe(nil), multicast_interface = T.unsafe(nil)); end
  def reply_service; end
  def shutdown; end
  def write_services; end
end

class Rinda::RingServer::Renewer
  def initialize; end

  def renew; end
  def renew=(_arg0); end
end

class Rinda::SimpleRenewer
  def initialize(sec = T.unsafe(nil)); end

  def renew; end
end

class Rinda::Template < ::Rinda::Tuple
  def ===(tuple); end
  def match(tuple); end
end

class Rinda::TemplateEntry < ::Rinda::TupleEntry
  def ===(tuple); end
  def make_tuple(ary); end
  def match(tuple); end
end

class Rinda::Tuple
  def initialize(ary_or_hash); end

  def [](k); end
  def each; end
  def fetch(k); end
  def size; end
  def value; end

  private

  def hash?(ary_or_hash); end
  def init_with_ary(ary); end
  def init_with_hash(hash); end
end

class Rinda::TupleBag
  def initialize; end

  def delete(tuple); end
  def delete_unless_alive; end
  def find(template); end
  def find_all(template); end
  def find_all_template(tuple); end
  def has_expires?; end
  def push(tuple); end

  private

  def bin_for_find(template); end
  def bin_key(tuple); end
  def each_entry(&blk); end
end

class Rinda::TupleBag::TupleBin
  def initialize; end

  def add(tuple); end
  def delete(tuple); end
  def delete_if(*args, **_arg1, &block); end
  def each(*args, **_arg1, &block); end
  def empty?(*args, **_arg1, &block); end
  def find; end
  def find_all(*args, **_arg1, &block); end
end

class Rinda::TupleEntry
  def initialize(ary, sec = T.unsafe(nil)); end

  def [](key); end
  def alive?; end
  def cancel; end
  def canceled?; end
  def expired?; end
  def expires; end
  def expires=(_arg0); end
  def fetch(key); end
  def make_expires(sec = T.unsafe(nil)); end
  def make_tuple(ary); end
  def renew(sec_or_renewer); end
  def size; end
  def value; end

  private

  def get_renewer(it); end
end

class Rinda::TupleSpace
  def initialize(period = T.unsafe(nil)); end

  def move(port, tuple, sec = T.unsafe(nil)); end
  def notify(event, tuple, sec = T.unsafe(nil)); end
  def read(tuple, sec = T.unsafe(nil)); end
  def read_all(tuple); end
  def take(tuple, sec = T.unsafe(nil), &block); end
  def write(tuple, sec = T.unsafe(nil)); end

  private

  def create_entry(tuple, sec); end
  def keep_clean; end
  def need_keeper?; end
  def notify_event(event, tuple); end
  def start_keeper; end
end

class Rinda::TupleSpaceProxy
  def initialize(ts); end

  def notify(ev, tuple, sec = T.unsafe(nil)); end
  def read(tuple, sec = T.unsafe(nil), &block); end
  def read_all(tuple); end
  def take(tuple, sec = T.unsafe(nil), &block); end
  def write(tuple, sec = T.unsafe(nil)); end
end

class Rinda::TupleSpaceProxy::Port
  def initialize; end

  def close; end
  def push(value); end
  def value; end

  class << self
    def deliver; end
  end
end

class Rinda::WaitTemplateEntry < ::Rinda::TemplateEntry
  def initialize(place, ary, expires = T.unsafe(nil)); end

  def cancel; end
  def found; end
  def read(tuple); end
  def signal; end
  def wait; end
end

module SingleForwardable
  def def_delegator(accessor, method, ali = T.unsafe(nil)); end
  def def_delegators(accessor, *methods); end
  def def_single_delegator(accessor, method, ali = T.unsafe(nil)); end
  def def_single_delegators(accessor, *methods); end
  def delegate(hash); end
  def single_delegate(hash); end
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
  def initialize(host, serv, *rest); end

  private

  def original_resolv_initialize(*_arg0); end

  class << self
    def gethostbyname(_arg0); end
  end
end

class UDPSocket < ::IPSocket
  def initialize(*_arg0); end

  def bind(host, port); end
  def connect(host, port); end
  def original_resolv_bind(_arg0, _arg1); end
  def original_resolv_connect(_arg0, _arg1); end
  def original_resolv_send(*_arg0); end
  def recvfrom_nonblock(len, flag = T.unsafe(nil), outbuf = T.unsafe(nil), exception: T.unsafe(nil)); end
  def send(mesg, flags, *rest); end

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
