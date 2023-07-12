# typed: __STDLIB_INTERNAL

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
