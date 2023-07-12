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
    def getaddress(_arg0); end
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
