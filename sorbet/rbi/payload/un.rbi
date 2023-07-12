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

module UN
  private

  def help(argv, output: T.unsafe(nil)); end

  class << self
    def help(argv, output: T.unsafe(nil)); end
  end
end
