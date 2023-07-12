# typed: __STDLIB_INTERNAL

class ACL
  def initialize(list = T.unsafe(nil), order = T.unsafe(nil)); end

  def allow_addr?(addr); end
  def allow_socket?(soc); end
  def install_list(list); end
end

class ACL::ACLEntry
  def initialize(str); end

  def match(addr); end

  private

  def dot_pat(str); end
  def dot_pat_str(str); end
end

class ACL::ACLList
  def initialize; end

  def add(str); end
  def match(addr); end
end

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

module Etc
  private

  def confstr(_arg0); end
  def endgrent; end
  def endpwent; end
  def getgrent; end
  def getgrgid(*_arg0); end
  def getgrnam(_arg0); end
  def getlogin; end
  def getpwent; end
  def getpwnam(_arg0); end
  def getpwuid(*_arg0); end
  def group; end
  def nprocessors; end
  def passwd; end
  def setgrent; end
  def setpwent; end
  def sysconf(_arg0); end
  def sysconfdir; end
  def systmpdir; end
  def uname; end

  class << self
    def confstr(_arg0); end
    def endgrent; end
    def endpwent; end
    def getgrent; end
    def getgrgid(*_arg0); end
    def getgrnam(_arg0); end
    def getlogin; end
    def getpwent; end
    def getpwnam(_arg0); end
    def getpwuid(*_arg0); end
    def group; end
    def nprocessors; end
    def passwd; end
    def setgrent; end
    def setpwent; end
    def sysconf(_arg0); end
    def sysconfdir; end
    def systmpdir; end
    def uname; end
  end
end

class Etc::Group < ::Struct
  extend ::Enumerable

  def gid; end
  def gid=(_); end
  def mem; end
  def mem=(_); end
  def name; end
  def name=(_); end
  def passwd; end
  def passwd=(_); end

  class << self
    def [](*_arg0); end
    def each; end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

class Etc::Passwd < ::Struct
  extend ::Enumerable

  def change; end
  def change=(_); end
  def dir; end
  def dir=(_); end
  def expire; end
  def expire=(_); end
  def gecos; end
  def gecos=(_); end
  def gid; end
  def gid=(_); end
  def name; end
  def name=(_); end
  def passwd; end
  def passwd=(_); end
  def shell; end
  def shell=(_); end
  def uclass; end
  def uclass=(_); end
  def uid; end
  def uid=(_); end

  class << self
    def [](*_arg0); end
    def each; end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

module FileUtils
  private

  def apply_mask(mode, user_mask, op, mode_mask); end
  def cd(dir, verbose: T.unsafe(nil), &block); end
  def chdir(dir, verbose: T.unsafe(nil), &block); end
  def chmod(mode, list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def chmod_R(mode, list, noop: T.unsafe(nil), verbose: T.unsafe(nil), force: T.unsafe(nil)); end
  def chown(user, group, list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def chown_R(user, group, list, noop: T.unsafe(nil), verbose: T.unsafe(nil), force: T.unsafe(nil)); end
  def cmp(a, b); end
  def compare_file(a, b); end
  def compare_stream(a, b); end
  def copy(src, dest, preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def copy_entry(src, dest, preserve = T.unsafe(nil), dereference_root = T.unsafe(nil), remove_destination = T.unsafe(nil)); end
  def copy_file(src, dest, preserve = T.unsafe(nil), dereference = T.unsafe(nil)); end
  def copy_stream(src, dest); end
  def cp(src, dest, preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def cp_lr(src, dest, noop: T.unsafe(nil), verbose: T.unsafe(nil), dereference_root: T.unsafe(nil), remove_destination: T.unsafe(nil)); end
  def cp_r(src, dest, preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), dereference_root: T.unsafe(nil), remove_destination: T.unsafe(nil)); end
  def fu_clean_components(*comp); end
  def fu_each_src_dest(src, dest); end
  def fu_each_src_dest0(src, dest, target_directory = T.unsafe(nil)); end
  def fu_get_gid(group); end
  def fu_get_uid(user); end
  def fu_have_symlink?; end
  def fu_list(arg); end
  def fu_mkdir(path, mode); end
  def fu_mode(mode, path); end
  def fu_output_message(msg); end
  def fu_relative_components_from(target, base); end
  def fu_same?(a, b); end
  def fu_split_path(path); end
  def fu_starting_path?(path); end
  def fu_stat_identical_entry?(a, b); end
  def getwd; end
  def identical?(a, b); end
  def install(src, dest, mode: T.unsafe(nil), owner: T.unsafe(nil), group: T.unsafe(nil), preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def link(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def link_entry(src, dest, dereference_root = T.unsafe(nil), remove_destination = T.unsafe(nil)); end
  def ln(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def ln_s(src, dest, force: T.unsafe(nil), relative: T.unsafe(nil), target_directory: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def ln_sf(src, dest, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def ln_sr(src, dest, target_directory: T.unsafe(nil), force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def makedirs(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def mkdir(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def mkdir_p(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def mkpath(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def mode_to_s(mode); end
  def move(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
  def mv(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
  def pwd; end
  def remove(list, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def remove_dir(path, force = T.unsafe(nil)); end
  def remove_entry(path, force = T.unsafe(nil)); end
  def remove_entry_secure(path, force = T.unsafe(nil)); end
  def remove_file(path, force = T.unsafe(nil)); end
  def remove_trailing_slash(dir); end
  def rm(list, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def rm_f(list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def rm_r(list, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
  def rm_rf(list, noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
  def rmdir(list, parents: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def rmtree(list, noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
  def safe_unlink(list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def symbolic_modes_to_i(mode_sym, path); end
  def symlink(src, dest, force: T.unsafe(nil), relative: T.unsafe(nil), target_directory: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def touch(list, noop: T.unsafe(nil), verbose: T.unsafe(nil), mtime: T.unsafe(nil), nocreate: T.unsafe(nil)); end
  def uptodate?(new, old_list); end
  def user_mask(target); end

  class << self
    def cd(dir, verbose: T.unsafe(nil), &block); end
    def chdir(dir, verbose: T.unsafe(nil), &block); end
    def chmod(mode, list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def chmod_R(mode, list, noop: T.unsafe(nil), verbose: T.unsafe(nil), force: T.unsafe(nil)); end
    def chown(user, group, list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def chown_R(user, group, list, noop: T.unsafe(nil), verbose: T.unsafe(nil), force: T.unsafe(nil)); end
    def cmp(a, b); end
    def collect_method(opt); end
    def commands; end
    def compare_file(a, b); end
    def compare_stream(a, b); end
    def copy(src, dest, preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def copy_entry(src, dest, preserve = T.unsafe(nil), dereference_root = T.unsafe(nil), remove_destination = T.unsafe(nil)); end
    def copy_file(src, dest, preserve = T.unsafe(nil), dereference = T.unsafe(nil)); end
    def copy_stream(src, dest); end
    def cp(src, dest, preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def cp_lr(src, dest, noop: T.unsafe(nil), verbose: T.unsafe(nil), dereference_root: T.unsafe(nil), remove_destination: T.unsafe(nil)); end
    def cp_r(src, dest, preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), dereference_root: T.unsafe(nil), remove_destination: T.unsafe(nil)); end
    def getwd; end
    def have_option?(mid, opt); end
    def identical?(a, b); end
    def install(src, dest, mode: T.unsafe(nil), owner: T.unsafe(nil), group: T.unsafe(nil), preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def link(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def link_entry(src, dest, dereference_root = T.unsafe(nil), remove_destination = T.unsafe(nil)); end
    def ln(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def ln_s(src, dest, force: T.unsafe(nil), relative: T.unsafe(nil), target_directory: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def ln_sf(src, dest, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def ln_sr(src, dest, target_directory: T.unsafe(nil), force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def makedirs(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def mkdir(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def mkdir_p(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def mkpath(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def move(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
    def mv(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
    def options; end
    def options_of(mid); end
    def private_module_function(name); end
    def pwd; end
    def remove(list, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def remove_dir(path, force = T.unsafe(nil)); end
    def remove_entry(path, force = T.unsafe(nil)); end
    def remove_entry_secure(path, force = T.unsafe(nil)); end
    def remove_file(path, force = T.unsafe(nil)); end
    def rm(list, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def rm_f(list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def rm_r(list, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
    def rm_rf(list, noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
    def rmdir(list, parents: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def rmtree(list, noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
    def safe_unlink(list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def symlink(src, dest, force: T.unsafe(nil), relative: T.unsafe(nil), target_directory: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def touch(list, noop: T.unsafe(nil), verbose: T.unsafe(nil), mtime: T.unsafe(nil), nocreate: T.unsafe(nil)); end
    def uptodate?(new, old_list); end

    private

    def apply_mask(mode, user_mask, op, mode_mask); end
    def fu_clean_components(*comp); end
    def fu_each_src_dest(src, dest); end
    def fu_each_src_dest0(src, dest, target_directory = T.unsafe(nil)); end
    def fu_get_gid(group); end
    def fu_get_uid(user); end
    def fu_have_symlink?; end
    def fu_list(arg); end
    def fu_mkdir(path, mode); end
    def fu_mode(mode, path); end
    def fu_output_message(msg); end
    def fu_relative_components_from(target, base); end
    def fu_same?(a, b); end
    def fu_split_path(path); end
    def fu_starting_path?(path); end
    def fu_stat_identical_entry?(a, b); end
    def mode_to_s(mode); end
    def remove_trailing_slash(dir); end
    def symbolic_modes_to_i(mode_sym, path); end
    def user_mask(target); end
  end
end

module FileUtils::DryRun
  include ::FileUtils::StreamUtils_
  extend ::FileUtils::StreamUtils_
  extend ::FileUtils
  extend ::FileUtils::LowMethods

  private

  def chmod(*args, **options); end
  def chmod_R(*args, **options); end
  def chown(*args, **options); end
  def chown_R(*args, **options); end
  def copy(*args, **options); end
  def cp(*args, **options); end
  def cp_lr(*args, **options); end
  def cp_r(*args, **options); end
  def install(*args, **options); end
  def link(*args, **options); end
  def ln(*args, **options); end
  def ln_s(*args, **options); end
  def ln_sf(*args, **options); end
  def ln_sr(*args, **options); end
  def makedirs(*args, **options); end
  def mkdir(*args, **options); end
  def mkdir_p(*args, **options); end
  def mkpath(*args, **options); end
  def move(*args, **options); end
  def mv(*args, **options); end
  def remove(*args, **options); end
  def rm(*args, **options); end
  def rm_f(*args, **options); end
  def rm_r(*args, **options); end
  def rm_rf(*args, **options); end
  def rmdir(*args, **options); end
  def rmtree(*args, **options); end
  def safe_unlink(*args, **options); end
  def symlink(*args, **options); end
  def touch(*args, **options); end

  class << self
    def cd(*_arg0); end
    def chdir(*_arg0); end
    def chmod(*args, **options); end
    def chmod_R(*args, **options); end
    def chown(*args, **options); end
    def chown_R(*args, **options); end
    def cmp(*_arg0); end
    def compare_file(*_arg0); end
    def compare_stream(*_arg0); end
    def copy(*args, **options); end
    def copy_entry(*_arg0); end
    def copy_file(*_arg0); end
    def copy_stream(*_arg0); end
    def cp(*args, **options); end
    def cp_lr(*args, **options); end
    def cp_r(*args, **options); end
    def getwd(*_arg0); end
    def identical?(*_arg0); end
    def install(*args, **options); end
    def link(*args, **options); end
    def link_entry(*_arg0); end
    def ln(*args, **options); end
    def ln_s(*args, **options); end
    def ln_sf(*args, **options); end
    def ln_sr(*args, **options); end
    def makedirs(*args, **options); end
    def mkdir(*args, **options); end
    def mkdir_p(*args, **options); end
    def mkpath(*args, **options); end
    def move(*args, **options); end
    def mv(*args, **options); end
    def pwd(*_arg0); end
    def remove(*args, **options); end
    def remove_dir(*_arg0); end
    def remove_entry(*_arg0); end
    def remove_entry_secure(*_arg0); end
    def remove_file(*_arg0); end
    def rm(*args, **options); end
    def rm_f(*args, **options); end
    def rm_r(*args, **options); end
    def rm_rf(*args, **options); end
    def rmdir(*args, **options); end
    def rmtree(*args, **options); end
    def safe_unlink(*args, **options); end
    def symlink(*args, **options); end
    def touch(*args, **options); end
    def uptodate?(*_arg0); end
  end
end

class FileUtils::Entry_
  def initialize(a, b = T.unsafe(nil), deref = T.unsafe(nil)); end

  def blockdev?; end
  def chardev?; end
  def chmod(mode); end
  def chown(uid, gid); end
  def copy(dest); end
  def copy_file(dest); end
  def copy_metadata(path); end
  def dereference?; end
  def directory?; end
  def door?; end
  def entries; end
  def exist?; end
  def file?; end
  def inspect; end
  def link(dest); end
  def lstat; end
  def lstat!; end
  def path; end
  def pipe?; end
  def platform_support; end
  def postorder_traverse; end
  def prefix; end
  def preorder_traverse; end
  def rel; end
  def remove; end
  def remove_dir1; end
  def remove_file; end
  def socket?; end
  def stat; end
  def stat!; end
  def symlink?; end
  def traverse; end
  def wrap_traverse(pre, post); end

  private

  def check_have_lchmod?; end
  def check_have_lchown?; end
  def descendant_directory?(descendant, ascendant); end
  def have_lchmod?; end
  def have_lchown?; end
  def join(dir, base); end
end

module FileUtils::LowMethods
  private

  def _do_nothing(*_arg0); end
  def cd(*_arg0); end
  def chdir(*_arg0); end
  def cmp(*_arg0); end
  def collect_method(*_arg0); end
  def commands(*_arg0); end
  def compare_file(*_arg0); end
  def compare_stream(*_arg0); end
  def copy_entry(*_arg0); end
  def copy_file(*_arg0); end
  def copy_stream(*_arg0); end
  def getwd(*_arg0); end
  def have_option?(*_arg0); end
  def identical?(*_arg0); end
  def link_entry(*_arg0); end
  def options(*_arg0); end
  def options_of(*_arg0); end
  def private_module_function(*_arg0); end
  def pwd(*_arg0); end
  def remove_dir(*_arg0); end
  def remove_entry(*_arg0); end
  def remove_entry_secure(*_arg0); end
  def remove_file(*_arg0); end
  def uptodate?(*_arg0); end
end

module FileUtils::NoWrite
  include ::FileUtils::StreamUtils_
  extend ::FileUtils::StreamUtils_
  extend ::FileUtils
  extend ::FileUtils::LowMethods

  private

  def chmod(*args, **options); end
  def chmod_R(*args, **options); end
  def chown(*args, **options); end
  def chown_R(*args, **options); end
  def copy(*args, **options); end
  def cp(*args, **options); end
  def cp_lr(*args, **options); end
  def cp_r(*args, **options); end
  def install(*args, **options); end
  def link(*args, **options); end
  def ln(*args, **options); end
  def ln_s(*args, **options); end
  def ln_sf(*args, **options); end
  def ln_sr(*args, **options); end
  def makedirs(*args, **options); end
  def mkdir(*args, **options); end
  def mkdir_p(*args, **options); end
  def mkpath(*args, **options); end
  def move(*args, **options); end
  def mv(*args, **options); end
  def remove(*args, **options); end
  def rm(*args, **options); end
  def rm_f(*args, **options); end
  def rm_r(*args, **options); end
  def rm_rf(*args, **options); end
  def rmdir(*args, **options); end
  def rmtree(*args, **options); end
  def safe_unlink(*args, **options); end
  def symlink(*args, **options); end
  def touch(*args, **options); end

  class << self
    def cd(*_arg0); end
    def chdir(*_arg0); end
    def chmod(*args, **options); end
    def chmod_R(*args, **options); end
    def chown(*args, **options); end
    def chown_R(*args, **options); end
    def cmp(*_arg0); end
    def compare_file(*_arg0); end
    def compare_stream(*_arg0); end
    def copy(*args, **options); end
    def copy_entry(*_arg0); end
    def copy_file(*_arg0); end
    def copy_stream(*_arg0); end
    def cp(*args, **options); end
    def cp_lr(*args, **options); end
    def cp_r(*args, **options); end
    def getwd(*_arg0); end
    def identical?(*_arg0); end
    def install(*args, **options); end
    def link(*args, **options); end
    def link_entry(*_arg0); end
    def ln(*args, **options); end
    def ln_s(*args, **options); end
    def ln_sf(*args, **options); end
    def ln_sr(*args, **options); end
    def makedirs(*args, **options); end
    def mkdir(*args, **options); end
    def mkdir_p(*args, **options); end
    def mkpath(*args, **options); end
    def move(*args, **options); end
    def mv(*args, **options); end
    def pwd(*_arg0); end
    def remove(*args, **options); end
    def remove_dir(*_arg0); end
    def remove_entry(*_arg0); end
    def remove_entry_secure(*_arg0); end
    def remove_file(*_arg0); end
    def rm(*args, **options); end
    def rm_f(*args, **options); end
    def rm_r(*args, **options); end
    def rm_rf(*args, **options); end
    def rmdir(*args, **options); end
    def rmtree(*args, **options); end
    def safe_unlink(*args, **options); end
    def symlink(*args, **options); end
    def touch(*args, **options); end
    def uptodate?(*_arg0); end
  end
end

module FileUtils::StreamUtils_
  private

  def fu_blksize(st); end
  def fu_copy_stream0(src, dest, blksize = T.unsafe(nil)); end
  def fu_default_blksize; end
  def fu_stream_blksize(*streams); end
  def fu_windows?; end
end

module FileUtils::Verbose
  include ::FileUtils::StreamUtils_
  extend ::FileUtils::StreamUtils_
  extend ::FileUtils

  private

  def cd(*args, **options); end
  def chdir(*args, **options); end
  def chmod(*args, **options); end
  def chmod_R(*args, **options); end
  def chown(*args, **options); end
  def chown_R(*args, **options); end
  def copy(*args, **options); end
  def cp(*args, **options); end
  def cp_lr(*args, **options); end
  def cp_r(*args, **options); end
  def install(*args, **options); end
  def link(*args, **options); end
  def ln(*args, **options); end
  def ln_s(*args, **options); end
  def ln_sf(*args, **options); end
  def ln_sr(*args, **options); end
  def makedirs(*args, **options); end
  def mkdir(*args, **options); end
  def mkdir_p(*args, **options); end
  def mkpath(*args, **options); end
  def move(*args, **options); end
  def mv(*args, **options); end
  def remove(*args, **options); end
  def rm(*args, **options); end
  def rm_f(*args, **options); end
  def rm_r(*args, **options); end
  def rm_rf(*args, **options); end
  def rmdir(*args, **options); end
  def rmtree(*args, **options); end
  def safe_unlink(*args, **options); end
  def symlink(*args, **options); end
  def touch(*args, **options); end

  class << self
    def cd(*args, **options); end
    def chdir(*args, **options); end
    def chmod(*args, **options); end
    def chmod_R(*args, **options); end
    def chown(*args, **options); end
    def chown_R(*args, **options); end
    def cmp(a, b); end
    def compare_file(a, b); end
    def compare_stream(a, b); end
    def copy(*args, **options); end
    def copy_entry(src, dest, preserve = T.unsafe(nil), dereference_root = T.unsafe(nil), remove_destination = T.unsafe(nil)); end
    def copy_file(src, dest, preserve = T.unsafe(nil), dereference = T.unsafe(nil)); end
    def copy_stream(src, dest); end
    def cp(*args, **options); end
    def cp_lr(*args, **options); end
    def cp_r(*args, **options); end
    def getwd; end
    def identical?(a, b); end
    def install(*args, **options); end
    def link(*args, **options); end
    def link_entry(src, dest, dereference_root = T.unsafe(nil), remove_destination = T.unsafe(nil)); end
    def ln(*args, **options); end
    def ln_s(*args, **options); end
    def ln_sf(*args, **options); end
    def ln_sr(*args, **options); end
    def makedirs(*args, **options); end
    def mkdir(*args, **options); end
    def mkdir_p(*args, **options); end
    def mkpath(*args, **options); end
    def move(*args, **options); end
    def mv(*args, **options); end
    def pwd; end
    def remove(*args, **options); end
    def remove_dir(path, force = T.unsafe(nil)); end
    def remove_entry(path, force = T.unsafe(nil)); end
    def remove_entry_secure(path, force = T.unsafe(nil)); end
    def remove_file(path, force = T.unsafe(nil)); end
    def rm(*args, **options); end
    def rm_f(*args, **options); end
    def rm_r(*args, **options); end
    def rm_rf(*args, **options); end
    def rmdir(*args, **options); end
    def rmtree(*args, **options); end
    def safe_unlink(*args, **options); end
    def symlink(*args, **options); end
    def touch(*args, **options); end
    def uptodate?(new, old_list); end
  end
end

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

module Observable
  def add_observer(observer, func = T.unsafe(nil)); end
  def changed(state = T.unsafe(nil)); end
  def changed?; end
  def count_observers; end
  def delete_observer(observer); end
  def delete_observers; end
  def notify_observers(*arg); end
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

module Singleton
  mixes_in_class_methods ::Singleton::SingletonClassMethods

  def _dump(depth = T.unsafe(nil)); end
  def clone; end
  def dup; end

  class << self
    def __init__(klass); end

    private

    def append_features(mod); end
    def included(klass); end
  end
end

module Singleton::SingletonClassMethods
  def _load(str); end
  def clone; end
  def instance; end

  private

  def inherited(sub_klass); end
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
