# typed: __STDLIB_INTERNAL

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

class Pathname
  def initialize(_arg0); end

  def +(other); end
  def /(other); end
  def <=>(_arg0); end
  def ==(_arg0); end
  def ===(_arg0); end
  def absolute?; end
  def ascend; end
  def atime; end
  def basename(*_arg0); end
  def binread(*_arg0); end
  def binwrite(*_arg0); end
  def birthtime; end
  def blockdev?; end
  def chardev?; end
  def children(with_directory = T.unsafe(nil)); end
  def chmod(_arg0); end
  def chown(_arg0, _arg1); end
  def cleanpath(consider_symlink = T.unsafe(nil)); end
  def ctime; end
  def delete; end
  def descend; end
  def directory?; end
  def dirname; end
  def each_child(with_directory = T.unsafe(nil), &b); end
  def each_entry; end
  def each_filename; end
  def each_line(*_arg0); end
  def empty?; end
  def entries; end
  def eql?(_arg0); end
  def executable?; end
  def executable_real?; end
  def exist?; end
  def expand_path(*_arg0); end
  def extname; end
  def file?; end
  def find(ignore_error: T.unsafe(nil)); end
  def fnmatch(*_arg0); end
  def fnmatch?(*_arg0); end
  def freeze; end
  def ftype; end
  def glob(*_arg0); end
  def grpowned?; end
  def hash; end
  def inspect; end
  def join(*args); end
  def lchmod(_arg0); end
  def lchown(_arg0, _arg1); end
  def lstat; end
  def lutime(_arg0, _arg1); end
  def make_link(_arg0); end
  def make_symlink(_arg0); end
  def mkdir(*_arg0); end
  def mkpath(mode: T.unsafe(nil)); end
  def mountpoint?; end
  def mtime; end
  def open(*_arg0); end
  def opendir; end
  def owned?; end
  def parent; end
  def pipe?; end
  def read(*_arg0); end
  def readable?; end
  def readable_real?; end
  def readlines(*_arg0); end
  def readlink; end
  def realdirpath(*_arg0); end
  def realpath(*_arg0); end
  def relative?; end
  def relative_path_from(base_directory); end
  def rename(_arg0); end
  def rmdir; end
  def rmtree(noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
  def root?; end
  def setgid?; end
  def setuid?; end
  def size; end
  def size?; end
  def socket?; end
  def split; end
  def stat; end
  def sticky?; end
  def sub(*_arg0); end
  def sub_ext(_arg0); end
  def symlink?; end
  def sysopen(*_arg0); end
  def taint; end
  def to_path; end
  def to_s; end
  def truncate(_arg0); end
  def unlink; end
  def untaint; end
  def utime(_arg0, _arg1); end
  def world_readable?; end
  def world_writable?; end
  def writable?; end
  def writable_real?; end
  def write(*_arg0); end
  def zero?; end

  private

  def add_trailing_separator(path); end
  def chop_basename(path); end
  def cleanpath_aggressive; end
  def cleanpath_conservative; end
  def del_trailing_separator(path); end
  def has_trailing_separator?(path); end
  def plus(path1, path2); end
  def prepend_prefix(prefix, relpath); end
  def split_names(path); end

  class << self
    def getwd; end
    def glob(*_arg0); end
    def pwd; end
  end
end

class Ripper
  def initialize(*_arg0); end

  def column; end
  def debug_output; end
  def debug_output=(_arg0); end
  def encoding; end
  def end_seen?; end
  def error?; end
  def filename; end
  def lineno; end
  def parse; end
  def state; end
  def token; end
  def yydebug; end
  def yydebug=(_arg0); end

  private

  def _dispatch_0; end
  def _dispatch_1(a); end
  def _dispatch_2(a, b); end
  def _dispatch_3(a, b, c); end
  def _dispatch_4(a, b, c, d); end
  def _dispatch_5(a, b, c, d, e); end
  def _dispatch_6(a, b, c, d, e, f); end
  def _dispatch_7(a, b, c, d, e, f, g); end
  def compile_error(msg); end
  def dedent_string(_arg0, _arg1); end
  def on_BEGIN(a); end
  def on_CHAR(a); end
  def on_END(a); end
  def on___end__(a); end
  def on_alias(a, b); end
  def on_alias_error(a, b); end
  def on_aref(a, b); end
  def on_aref_field(a, b); end
  def on_arg_ambiguous(a); end
  def on_arg_paren(a); end
  def on_args_add(a, b); end
  def on_args_add_block(a, b); end
  def on_args_add_star(a, b); end
  def on_args_forward; end
  def on_args_new; end
  def on_array(a); end
  def on_aryptn(a, b, c, d); end
  def on_assign(a, b); end
  def on_assign_error(a, b); end
  def on_assoc_new(a, b); end
  def on_assoc_splat(a); end
  def on_assoclist_from_args(a); end
  def on_backref(a); end
  def on_backtick(a); end
  def on_bare_assoc_hash(a); end
  def on_begin(a); end
  def on_binary(a, b, c); end
  def on_block_var(a, b); end
  def on_blockarg(a); end
  def on_bodystmt(a, b, c, d); end
  def on_brace_block(a, b); end
  def on_break(a); end
  def on_call(a, b, c); end
  def on_case(a, b); end
  def on_class(a, b, c); end
  def on_class_name_error(a, b); end
  def on_comma(a); end
  def on_command(a, b); end
  def on_command_call(a, b, c, d); end
  def on_comment(a); end
  def on_const(a); end
  def on_const_path_field(a, b); end
  def on_const_path_ref(a, b); end
  def on_const_ref(a); end
  def on_cvar(a); end
  def on_def(a, b, c); end
  def on_defined(a); end
  def on_defs(a, b, c, d, e); end
  def on_do_block(a, b); end
  def on_dot2(a, b); end
  def on_dot3(a, b); end
  def on_dyna_symbol(a); end
  def on_else(a); end
  def on_elsif(a, b, c); end
  def on_embdoc(a); end
  def on_embdoc_beg(a); end
  def on_embdoc_end(a); end
  def on_embexpr_beg(a); end
  def on_embexpr_end(a); end
  def on_embvar(a); end
  def on_ensure(a); end
  def on_excessed_comma; end
  def on_fcall(a); end
  def on_field(a, b, c); end
  def on_float(a); end
  def on_fndptn(a, b, c, d); end
  def on_for(a, b, c); end
  def on_gvar(a); end
  def on_hash(a); end
  def on_heredoc_beg(a); end
  def on_heredoc_dedent(a, b); end
  def on_heredoc_end(a); end
  def on_hshptn(a, b, c); end
  def on_ident(a); end
  def on_if(a, b, c); end
  def on_if_mod(a, b); end
  def on_ifop(a, b, c); end
  def on_ignored_nl(a); end
  def on_imaginary(a); end
  def on_in(a, b, c); end
  def on_int(a); end
  def on_ivar(a); end
  def on_kw(a); end
  def on_kwrest_param(a); end
  def on_label(a); end
  def on_label_end(a); end
  def on_lambda(a, b); end
  def on_lbrace(a); end
  def on_lbracket(a); end
  def on_lparen(a); end
  def on_magic_comment(a, b); end
  def on_massign(a, b); end
  def on_method_add_arg(a, b); end
  def on_method_add_block(a, b); end
  def on_mlhs_add(a, b); end
  def on_mlhs_add_post(a, b); end
  def on_mlhs_add_star(a, b); end
  def on_mlhs_new; end
  def on_mlhs_paren(a); end
  def on_module(a, b); end
  def on_mrhs_add(a, b); end
  def on_mrhs_add_star(a, b); end
  def on_mrhs_new; end
  def on_mrhs_new_from_args(a); end
  def on_next(a); end
  def on_nl(a); end
  def on_nokw_param(a); end
  def on_op(a); end
  def on_opassign(a, b, c); end
  def on_operator_ambiguous(a, b); end
  def on_param_error(a, b); end
  def on_params(a, b, c, d, e, f, g); end
  def on_paren(a); end
  def on_parse_error(a); end
  def on_period(a); end
  def on_program(a); end
  def on_qsymbols_add(a, b); end
  def on_qsymbols_beg(a); end
  def on_qsymbols_new; end
  def on_qwords_add(a, b); end
  def on_qwords_beg(a); end
  def on_qwords_new; end
  def on_rational(a); end
  def on_rbrace(a); end
  def on_rbracket(a); end
  def on_redo; end
  def on_regexp_add(a, b); end
  def on_regexp_beg(a); end
  def on_regexp_end(a); end
  def on_regexp_literal(a, b); end
  def on_regexp_new; end
  def on_rescue(a, b, c, d); end
  def on_rescue_mod(a, b); end
  def on_rest_param(a); end
  def on_retry; end
  def on_return(a); end
  def on_return0; end
  def on_rparen(a); end
  def on_sclass(a, b); end
  def on_semicolon(a); end
  def on_sp(a); end
  def on_stmts_add(a, b); end
  def on_stmts_new; end
  def on_string_add(a, b); end
  def on_string_concat(a, b); end
  def on_string_content; end
  def on_string_dvar(a); end
  def on_string_embexpr(a); end
  def on_string_literal(a); end
  def on_super(a); end
  def on_symbeg(a); end
  def on_symbol(a); end
  def on_symbol_literal(a); end
  def on_symbols_add(a, b); end
  def on_symbols_beg(a); end
  def on_symbols_new; end
  def on_tlambda(a); end
  def on_tlambeg(a); end
  def on_top_const_field(a); end
  def on_top_const_ref(a); end
  def on_tstring_beg(a); end
  def on_tstring_content(a); end
  def on_tstring_end(a); end
  def on_unary(a, b); end
  def on_undef(a); end
  def on_unless(a, b, c); end
  def on_unless_mod(a, b); end
  def on_until(a, b); end
  def on_until_mod(a, b); end
  def on_var_alias(a, b); end
  def on_var_field(a); end
  def on_var_ref(a); end
  def on_vcall(a); end
  def on_void_stmt; end
  def on_when(a, b, c); end
  def on_while(a, b); end
  def on_while_mod(a, b); end
  def on_word_add(a, b); end
  def on_word_new; end
  def on_words_add(a, b); end
  def on_words_beg(a); end
  def on_words_new; end
  def on_words_sep(a); end
  def on_xstring_add(a, b); end
  def on_xstring_literal(a); end
  def on_xstring_new; end
  def on_yield(a); end
  def on_yield0; end
  def on_zsuper; end
  def warn(fmt, *args); end
  def warning(fmt, *args); end

  class << self
    def dedent_string(_arg0, _arg1); end
    def lex(src, filename = T.unsafe(nil), lineno = T.unsafe(nil), **kw); end
    def lex_state_name(_arg0); end
    def parse(src, filename = T.unsafe(nil), lineno = T.unsafe(nil)); end
    def sexp(src, filename = T.unsafe(nil), lineno = T.unsafe(nil), raise_errors: T.unsafe(nil)); end
    def sexp_raw(src, filename = T.unsafe(nil), lineno = T.unsafe(nil), raise_errors: T.unsafe(nil)); end
    def slice(src, pattern, n = T.unsafe(nil)); end
    def token_match(src, pattern); end
    def tokenize(src, filename = T.unsafe(nil), lineno = T.unsafe(nil), **kw); end
  end
end

class Ripper::Filter
  def initialize(src, filename = T.unsafe(nil), lineno = T.unsafe(nil)); end

  def column; end
  def filename; end
  def lineno; end
  def parse(init = T.unsafe(nil)); end
  def state; end

  private

  def on_default(event, token, data); end
end

class Ripper::Lexer < ::Ripper
  def errors; end
  def lex(**kw); end
  def parse(raise_errors: T.unsafe(nil)); end
  def scan(**kw); end
  def tokenize(**kw); end

  private

  def _push_token(tok); end
  def compile_error(mesg); end
  def on_CHAR(tok); end
  def on___end__(tok); end
  def on_alias_error(mesg, elem); end
  def on_assign_error(mesg, elem); end
  def on_backref(tok); end
  def on_backtick(tok); end
  def on_class_name_error(mesg, elem); end
  def on_comma(tok); end
  def on_comment(tok); end
  def on_const(tok); end
  def on_cvar(tok); end
  def on_embdoc(tok); end
  def on_embdoc_beg(tok); end
  def on_embdoc_end(tok); end
  def on_embexpr_beg(tok); end
  def on_embexpr_end(tok); end
  def on_embvar(tok); end
  def on_error1(mesg); end
  def on_error2(mesg, elem); end
  def on_float(tok); end
  def on_gvar(tok); end
  def on_heredoc_beg(tok); end
  def on_heredoc_dedent(v, w); end
  def on_heredoc_end(tok); end
  def on_ident(tok); end
  def on_ignored_nl(tok); end
  def on_ignored_sp(tok); end
  def on_imaginary(tok); end
  def on_int(tok); end
  def on_ivar(tok); end
  def on_kw(tok); end
  def on_label(tok); end
  def on_label_end(tok); end
  def on_lbrace(tok); end
  def on_lbracket(tok); end
  def on_lparen(tok); end
  def on_nl(tok); end
  def on_op(tok); end
  def on_param_error(mesg, elem); end
  def on_parse_error(mesg); end
  def on_period(tok); end
  def on_qsymbols_beg(tok); end
  def on_qwords_beg(tok); end
  def on_rational(tok); end
  def on_rbrace(tok); end
  def on_rbracket(tok); end
  def on_regexp_beg(tok); end
  def on_regexp_end(tok); end
  def on_rparen(tok); end
  def on_semicolon(tok); end
  def on_sp(tok); end
  def on_symbeg(tok); end
  def on_symbols_beg(tok); end
  def on_tlambda(tok); end
  def on_tlambeg(tok); end
  def on_tstring_beg(tok); end
  def on_tstring_content(tok); end
  def on_tstring_end(tok); end
  def on_words_beg(tok); end
  def on_words_sep(tok); end
end

class Ripper::Lexer::Elem
  def initialize(pos, event, tok, state, message = T.unsafe(nil)); end

  def [](index); end
  def event; end
  def event=(_arg0); end
  def inspect; end
  def message; end
  def message=(_arg0); end
  def pos; end
  def pos=(_arg0); end
  def pretty_print(q); end
  def state; end
  def state=(_arg0); end
  def to_a; end
  def to_s; end
  def tok; end
  def tok=(_arg0); end
end

class Ripper::Lexer::State
  def initialize(i); end

  def &(i); end
  def ==(i); end
  def [](index); end
  def allbits?(i); end
  def anybits?(i); end
  def inspect; end
  def nobits?(i); end
  def pretty_print(q); end
  def to_i; end
  def to_int; end
  def to_s; end
  def |(i); end
end

class Ripper::SexpBuilder < ::Ripper
  def error; end
  def on_BEGIN(*args); end
  def on_CHAR(tok); end
  def on_END(*args); end
  def on___end__(tok); end
  def on_alias(*args); end
  def on_alias_error(*args); end
  def on_aref(*args); end
  def on_aref_field(*args); end
  def on_arg_ambiguous(*args); end
  def on_arg_paren(*args); end
  def on_args_add(*args); end
  def on_args_add_block(*args); end
  def on_args_add_star(*args); end
  def on_args_forward(*args); end
  def on_args_new(*args); end
  def on_array(*args); end
  def on_aryptn(*args); end
  def on_assign(*args); end
  def on_assign_error(*args); end
  def on_assoc_new(*args); end
  def on_assoc_splat(*args); end
  def on_assoclist_from_args(*args); end
  def on_backref(tok); end
  def on_backtick(tok); end
  def on_bare_assoc_hash(*args); end
  def on_begin(*args); end
  def on_binary(*args); end
  def on_block_var(*args); end
  def on_blockarg(*args); end
  def on_bodystmt(*args); end
  def on_brace_block(*args); end
  def on_break(*args); end
  def on_call(*args); end
  def on_case(*args); end
  def on_class(*args); end
  def on_class_name_error(*args); end
  def on_comma(tok); end
  def on_command(*args); end
  def on_command_call(*args); end
  def on_comment(tok); end
  def on_const(tok); end
  def on_const_path_field(*args); end
  def on_const_path_ref(*args); end
  def on_const_ref(*args); end
  def on_cvar(tok); end
  def on_def(*args); end
  def on_defined(*args); end
  def on_defs(*args); end
  def on_do_block(*args); end
  def on_dot2(*args); end
  def on_dot3(*args); end
  def on_dyna_symbol(*args); end
  def on_else(*args); end
  def on_elsif(*args); end
  def on_embdoc(tok); end
  def on_embdoc_beg(tok); end
  def on_embdoc_end(tok); end
  def on_embexpr_beg(tok); end
  def on_embexpr_end(tok); end
  def on_embvar(tok); end
  def on_ensure(*args); end
  def on_excessed_comma(*args); end
  def on_fcall(*args); end
  def on_field(*args); end
  def on_float(tok); end
  def on_fndptn(*args); end
  def on_for(*args); end
  def on_gvar(tok); end
  def on_hash(*args); end
  def on_heredoc_beg(tok); end
  def on_heredoc_end(tok); end
  def on_hshptn(*args); end
  def on_ident(tok); end
  def on_if(*args); end
  def on_if_mod(*args); end
  def on_ifop(*args); end
  def on_ignored_nl(tok); end
  def on_ignored_sp(tok); end
  def on_imaginary(tok); end
  def on_in(*args); end
  def on_int(tok); end
  def on_ivar(tok); end
  def on_kw(tok); end
  def on_kwrest_param(*args); end
  def on_label(tok); end
  def on_label_end(tok); end
  def on_lambda(*args); end
  def on_lbrace(tok); end
  def on_lbracket(tok); end
  def on_lparen(tok); end
  def on_magic_comment(*args); end
  def on_massign(*args); end
  def on_method_add_arg(*args); end
  def on_method_add_block(*args); end
  def on_mlhs_add(*args); end
  def on_mlhs_add_post(*args); end
  def on_mlhs_add_star(*args); end
  def on_mlhs_new(*args); end
  def on_mlhs_paren(*args); end
  def on_module(*args); end
  def on_mrhs_add(*args); end
  def on_mrhs_add_star(*args); end
  def on_mrhs_new(*args); end
  def on_mrhs_new_from_args(*args); end
  def on_next(*args); end
  def on_nl(tok); end
  def on_nokw_param(*args); end
  def on_op(tok); end
  def on_opassign(*args); end
  def on_operator_ambiguous(*args); end
  def on_param_error(*args); end
  def on_params(*args); end
  def on_paren(*args); end
  def on_period(tok); end
  def on_program(*args); end
  def on_qsymbols_add(*args); end
  def on_qsymbols_beg(tok); end
  def on_qsymbols_new(*args); end
  def on_qwords_add(*args); end
  def on_qwords_beg(tok); end
  def on_qwords_new(*args); end
  def on_rational(tok); end
  def on_rbrace(tok); end
  def on_rbracket(tok); end
  def on_redo(*args); end
  def on_regexp_add(*args); end
  def on_regexp_beg(tok); end
  def on_regexp_end(tok); end
  def on_regexp_literal(*args); end
  def on_regexp_new(*args); end
  def on_rescue(*args); end
  def on_rescue_mod(*args); end
  def on_rest_param(*args); end
  def on_retry(*args); end
  def on_return(*args); end
  def on_return0(*args); end
  def on_rparen(tok); end
  def on_sclass(*args); end
  def on_semicolon(tok); end
  def on_sp(tok); end
  def on_stmts_add(*args); end
  def on_stmts_new(*args); end
  def on_string_add(*args); end
  def on_string_concat(*args); end
  def on_string_content(*args); end
  def on_string_dvar(*args); end
  def on_string_embexpr(*args); end
  def on_string_literal(*args); end
  def on_super(*args); end
  def on_symbeg(tok); end
  def on_symbol(*args); end
  def on_symbol_literal(*args); end
  def on_symbols_add(*args); end
  def on_symbols_beg(tok); end
  def on_symbols_new(*args); end
  def on_tlambda(tok); end
  def on_tlambeg(tok); end
  def on_top_const_field(*args); end
  def on_top_const_ref(*args); end
  def on_tstring_beg(tok); end
  def on_tstring_content(tok); end
  def on_tstring_end(tok); end
  def on_unary(*args); end
  def on_undef(*args); end
  def on_unless(*args); end
  def on_unless_mod(*args); end
  def on_until(*args); end
  def on_until_mod(*args); end
  def on_var_alias(*args); end
  def on_var_field(*args); end
  def on_var_ref(*args); end
  def on_vcall(*args); end
  def on_void_stmt(*args); end
  def on_when(*args); end
  def on_while(*args); end
  def on_while_mod(*args); end
  def on_word_add(*args); end
  def on_word_new(*args); end
  def on_words_add(*args); end
  def on_words_beg(tok); end
  def on_words_new(*args); end
  def on_words_sep(tok); end
  def on_xstring_add(*args); end
  def on_xstring_literal(*args); end
  def on_xstring_new(*args); end
  def on_yield(*args); end
  def on_yield0(*args); end
  def on_zsuper(*args); end

  private

  def compile_error(mesg); end
  def dedent_element(e, width); end
  def on_error(mesg); end
  def on_heredoc_dedent(val, width); end
  def on_parse_error(mesg); end
end

class Ripper::SexpBuilderPP < ::Ripper::SexpBuilder
  private

  def _dispatch_event_new; end
  def _dispatch_event_push(list, item); end
  def on_args_add(list, item); end
  def on_args_new; end
  def on_heredoc_dedent(val, width); end
  def on_mlhs_add(list, item); end
  def on_mlhs_add_post(list, post); end
  def on_mlhs_add_star(list, star); end
  def on_mlhs_new; end
  def on_mlhs_paren(list); end
  def on_mrhs_add(list, item); end
  def on_mrhs_new; end
  def on_qsymbols_add(list, item); end
  def on_qsymbols_new; end
  def on_qwords_add(list, item); end
  def on_qwords_new; end
  def on_regexp_add(list, item); end
  def on_regexp_new; end
  def on_stmts_add(list, item); end
  def on_stmts_new; end
  def on_string_add(list, item); end
  def on_symbols_add(list, item); end
  def on_symbols_new; end
  def on_word_add(list, item); end
  def on_word_new; end
  def on_words_add(list, item); end
  def on_words_new; end
  def on_xstring_add(list, item); end
  def on_xstring_new; end
end

class Ripper::TokenPattern
  def initialize(pattern); end

  def match(str); end
  def match_list(tokens); end

  private

  def compile(pattern); end
  def map_token(tok); end
  def map_tokens(tokens); end

  class << self
    def compile(*_arg0); end
  end
end

class Ripper::TokenPattern::CompileError < ::Ripper::TokenPattern::Error; end
class Ripper::TokenPattern::Error < ::StandardError; end

class Ripper::TokenPattern::MatchData
  def initialize(tokens, match); end

  def string(n = T.unsafe(nil)); end

  private

  def match(n = T.unsafe(nil)); end
end

class Ripper::TokenPattern::MatchError < ::Ripper::TokenPattern::Error; end

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
