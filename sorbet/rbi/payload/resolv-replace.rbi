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
  def initialize(host, serv, *rest); end

  private

  def original_resolv_initialize(*_arg0); end

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
