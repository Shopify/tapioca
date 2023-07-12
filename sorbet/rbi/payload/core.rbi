# typed: __STDLIB_INTERNAL

::ARGF = T.let(T.unsafe(nil), T.untyped)
::ENV = T.let(T.unsafe(nil), Object)
::STDERR = T.let(T.unsafe(nil), IO)
::STDIN = T.let(T.unsafe(nil), IO)
::STDOUT = T.let(T.unsafe(nil), IO)
ARGF = T.let(T.unsafe(nil), T.untyped)

class ArgumentError < ::StandardError
  include ::ErrorHighlight::CoreExt
end

class Array
  include ::Enumerable

  def initialize(*_arg0); end

  def &(_arg0); end
  def *(_arg0); end
  def +(_arg0); end
  def -(_arg0); end
  def <<(_arg0); end
  def <=>(_arg0); end
  def ==(_arg0); end
  def [](*_arg0); end
  def []=(*_arg0); end
  def all?(*_arg0); end
  def any?(*_arg0); end
  def append(*_arg0); end
  def assoc(_arg0); end
  def at(_arg0); end
  def bsearch; end
  def bsearch_index; end
  def clear; end
  def collect; end
  def collect!; end
  def combination(_arg0); end
  def compact; end
  def compact!; end
  def concat(*_arg0); end
  def count(*_arg0); end
  def cycle(*_arg0); end
  def deconstruct; end
  def delete(_arg0); end
  def delete_at(_arg0); end
  def delete_if; end
  def difference(*_arg0); end
  def dig(*_arg0); end
  def drop(_arg0); end
  def drop_while; end
  def each; end
  def each_index; end
  def empty?; end
  def eql?(_arg0); end
  def fetch(*_arg0); end
  def fill(*_arg0); end
  def filter; end
  def filter!; end
  def find_index(*_arg0); end
  def first(*_arg0); end
  def flatten(*_arg0); end
  def flatten!(*_arg0); end
  def hash; end
  def include?(_arg0); end
  def index(*_arg0); end
  def insert(*_arg0); end
  def inspect; end
  def intersect?(_arg0); end
  def intersection(*_arg0); end
  def join(*_arg0); end
  def keep_if; end
  def last(*_arg0); end
  def length; end
  def map; end
  def map!; end
  def max(*_arg0); end
  def min(*_arg0); end
  def minmax; end
  def none?(*_arg0); end
  def one?(*_arg0); end
  def pack(fmt, buffer: T.unsafe(nil)); end
  def permutation(*_arg0); end
  def place(*values); end
  def pop(*_arg0); end
  def prepend(*_arg0); end
  def pretty_print(q); end
  def pretty_print_cycle(q); end
  def product(*_arg0); end
  def push(*_arg0); end
  def rassoc(_arg0); end
  def reject; end
  def reject!; end
  def repeated_combination(_arg0); end
  def repeated_permutation(_arg0); end
  def replace(_arg0); end
  def reverse; end
  def reverse!; end
  def reverse_each; end
  def rindex(*_arg0); end
  def rotate(*_arg0); end
  def rotate!(*_arg0); end
  def sample(n = T.unsafe(nil), random: T.unsafe(nil)); end
  def select; end
  def select!; end
  def shelljoin; end
  def shift(*_arg0); end
  def shuffle(random: T.unsafe(nil)); end
  def shuffle!(random: T.unsafe(nil)); end
  def size; end
  def slice(*_arg0); end
  def slice!(*_arg0); end
  def sort; end
  def sort!; end
  def sort_by!; end
  def sum(*_arg0); end
  def take(_arg0); end
  def take_while; end
  def to_a; end
  def to_ary; end
  def to_h; end
  def to_s; end
  def transpose; end
  def union(*_arg0); end
  def uniq; end
  def uniq!; end
  def unshift(*_arg0); end
  def values_at(*_arg0); end
  def zip(*_arg0); end
  def |(_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def [](*_arg0); end
    def new(*_arg0); end
    def try_convert(_arg0); end
  end
end

class BasicObject
  def initialize; end

  def !; end
  def !=(_arg0); end
  def ==(_arg0); end
  def __id__; end
  def __send__(*_arg0); end
  def equal?(_arg0); end
  def instance_eval(*_arg0); end
  def instance_exec(*_arg0); end

  private

  def method_missing(*_arg0); end
  def singleton_method_added(_arg0); end
  def singleton_method_removed(_arg0); end
  def singleton_method_undefined(_arg0); end
end

class Binding
  def clone; end
  def dup; end
  def eval(*_arg0); end
  def irb; end
  def local_variable_defined?(_arg0); end
  def local_variable_get(_arg0); end
  def local_variable_set(_arg0, _arg1); end
  def local_variables; end
  def receiver; end
  def source_location; end
end

module Bundler::ForcePlatform
  private

  def default_force_ruby_platform; end
end

module Bundler::GemHelpers
  private

  def generic(p); end
  def generic_local_platform; end
  def local_platform; end
  def platform_specificity_match(spec_platform, user_platform); end
  def same_deps(spec, exemplary_spec); end
  def same_specificity(platform, spec, exemplary_spec); end
  def select_best_platform_match(specs, platform); end
  def sort_best_platform_match(matching, platform); end

  class << self
    def generic(p); end
    def generic_local_platform; end
    def local_platform; end
    def platform_specificity_match(spec_platform, user_platform); end
    def same_deps(spec, exemplary_spec); end
    def same_specificity(platform, spec, exemplary_spec); end
    def select_best_platform_match(specs, platform); end
    def sort_best_platform_match(matching, platform); end
  end
end

class Bundler::GemHelpers::PlatformMatch
  class << self
    def cpu_match(spec_platform, user_platform); end
    def os_match(spec_platform, user_platform); end
    def platform_version_match(spec_platform, user_platform); end
    def specificity_score(spec_platform, user_platform); end
  end
end

module Bundler::MatchMetadata
  def matches_current_ruby?; end
  def matches_current_rubygems?; end
end

module Bundler::MatchPlatform
  include ::Bundler::GemHelpers

  def match_platform(p); end

  class << self
    def platforms_match?(gemspec_platform, local_platform); end
  end
end

class Class < ::Module
  def initialize(*_arg0); end

  def allocate; end
  def attached_object; end
  def json_creatable?; end
  def new(*_arg0); end
  def subclasses; end
  def superclass; end

  private

  def inherited(_arg0); end

  class << self
    def allocate; end
  end
end

class ClosedQueueError < ::StopIteration; end

module Comparable
  def <(_arg0); end
  def <=(_arg0); end
  def ==(_arg0); end
  def >(_arg0); end
  def >=(_arg0); end
  def between?(_arg0, _arg1); end
  def clamp(*_arg0); end
end

class Complex < ::Numeric
  def *(_arg0); end
  def **(_arg0); end
  def +(_arg0); end
  def -(_arg0); end
  def -@; end
  def /(_arg0); end
  def <=>(_arg0); end
  def ==(_arg0); end
  def abs; end
  def abs2; end
  def angle; end
  def arg; end
  def coerce(_arg0); end
  def conj; end
  def conjugate; end
  def denominator; end
  def eql?(_arg0); end
  def fdiv(_arg0); end
  def finite?; end
  def hash; end
  def imag; end
  def imaginary; end
  def infinite?; end
  def inspect; end
  def magnitude; end
  def numerator; end
  def phase; end
  def polar; end
  def quo(_arg0); end
  def rationalize(*_arg0); end
  def real; end
  def real?; end
  def rect; end
  def rectangular; end
  def to_c; end
  def to_f; end
  def to_i; end
  def to_r; end
  def to_s; end

  private

  def marshal_dump; end

  class << self
    def polar(*_arg0); end
    def rect(*_arg0); end
    def rectangular(*_arg0); end

    private

    def convert(*_arg0); end
  end
end

class Data
  def initialize(*_arg0); end

  def ==(_arg0); end
  def deconstruct; end
  def deconstruct_keys(_arg0); end
  def eql?(_arg0); end
  def hash; end
  def inspect; end
  def members; end
  def pretty_print(q); end
  def pretty_print_cycle(q); end
  def to_h; end
  def to_s; end
  def with(*_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def define(*_arg0); end
  end
end

module DidYouMean
  class << self
    def correct_error(error_class, spell_checker); end
    def formatter; end
    def formatter=(formatter); end
    def spell_checkers; end
  end
end

class DidYouMean::ClassNameChecker
  def initialize(exception); end

  def class_name; end
  def class_names; end
  def corrections; end
  def scopes; end
end

module DidYouMean::Correctable
  def corrections; end
  def detailed_message(highlight: T.unsafe(nil), did_you_mean: T.unsafe(nil), **_arg2); end
  def original_message; end
  def spell_checker; end
end

class DidYouMean::Formatter
  def message_for(corrections); end

  class << self
    def message_for(corrections); end
  end
end

module DidYouMean::Jaro
  private

  def distance(str1, str2); end

  class << self
    def distance(str1, str2); end
  end
end

module DidYouMean::JaroWinkler
  private

  def distance(str1, str2); end

  class << self
    def distance(str1, str2); end
  end
end

class DidYouMean::KeyErrorChecker
  def initialize(key_error); end

  def corrections; end

  private

  def exact_matches; end
end

module DidYouMean::Levenshtein
  private

  def distance(str1, str2); end
  def min3(a, b, c); end

  class << self
    def distance(str1, str2); end
    def min3(a, b, c); end
  end
end

class DidYouMean::MethodNameChecker
  def initialize(exception); end

  def corrections; end
  def method_name; end
  def method_names; end
  def names_to_exclude; end
  def receiver; end
end

class DidYouMean::NullChecker
  def initialize(*_arg0); end

  def corrections; end
end

class DidYouMean::PatternKeyNameChecker
  def initialize(no_matching_pattern_key_error); end

  def corrections; end

  private

  def exact_matches; end
end

class DidYouMean::RequirePathChecker
  def initialize(exception); end

  def corrections; end
  def path; end

  class << self
    def requireables; end
  end
end

class DidYouMean::SpellChecker
  def initialize(dictionary:); end

  def correct(input); end

  private

  def normalize(str_or_symbol); end
end

class DidYouMean::TreeSpellChecker
  def initialize(dictionary:, separator: T.unsafe(nil), augment: T.unsafe(nil)); end

  def augment; end
  def correct(input); end
  def dictionary; end
  def dictionary_without_leaves; end
  def dimensions; end
  def find_leaves(path); end
  def plausible_dimensions(input); end
  def possible_paths(states); end
  def separator; end
  def tree_depth; end

  private

  def correct_element(names, element); end
  def fall_back_to_normal_spell_check(input); end
  def find_ideas(paths, leaf); end
  def find_suggestions(input, plausibles); end
  def ideas_to_paths(ideas, leaf, names, path); end
  def normalize(str); end
end

class DidYouMean::VariableNameChecker
  def initialize(exception); end

  def corrections; end
  def cvar_names; end
  def ivar_names; end
  def lvar_names; end
  def method_names; end
  def name; end
end

class Dir
  include ::Enumerable

  def initialize(name, encoding: T.unsafe(nil)); end

  def children; end
  def close; end
  def each; end
  def each_child; end
  def fileno; end
  def inspect; end
  def path; end
  def pos; end
  def pos=(_arg0); end
  def read; end
  def rewind; end
  def seek(_arg0); end
  def tell; end
  def to_path; end

  class << self
    def [](*args, base: T.unsafe(nil), sort: T.unsafe(nil)); end
    def chdir(*_arg0); end
    def children(*_arg0); end
    def chroot(_arg0); end
    def delete(_arg0); end
    def each_child(*_arg0); end
    def empty?(_arg0); end
    def entries(*_arg0); end
    def exist?(_arg0); end
    def foreach(*_arg0); end
    def getwd; end
    def glob(pattern, _flags = T.unsafe(nil), flags: T.unsafe(nil), base: T.unsafe(nil), sort: T.unsafe(nil)); end
    def home(*_arg0); end
    def mkdir(*_arg0); end
    def mktmpdir(prefix_suffix = T.unsafe(nil), *rest, **options); end
    def open(name, encoding: T.unsafe(nil), &block); end
    def pwd; end
    def rmdir(_arg0); end
    def tmpdir; end
    def unlink(_arg0); end
  end
end

module Dir::Tmpname
  private

  def create(basename, tmpdir = T.unsafe(nil), max_try: T.unsafe(nil), **opts); end
  def tmpdir; end

  class << self
    def create(basename, tmpdir = T.unsafe(nil), max_try: T.unsafe(nil), **opts); end
    def tmpdir; end
  end
end

ENV = T.let(T.unsafe(nil), Object)
class EOFError < ::IOError; end

class Encoding
  def _dump(*_arg0); end
  def ascii_compatible?; end
  def dummy?; end
  def inspect; end
  def name; end
  def names; end
  def replicate(_arg0); end
  def to_s; end

  class << self
    def _load(_arg0); end
    def aliases; end
    def compatible?(_arg0, _arg1); end
    def default_external; end
    def default_external=(_arg0); end
    def default_internal; end
    def default_internal=(_arg0); end
    def find(_arg0); end
    def list; end
    def locale_charmap; end
    def name_list; end
  end
end

class Encoding::CompatibilityError < ::EncodingError; end

class Encoding::Converter
  def initialize(*_arg0); end

  def ==(_arg0); end
  def convert(_arg0); end
  def convpath; end
  def destination_encoding; end
  def finish; end
  def insert_output(_arg0); end
  def inspect; end
  def last_error; end
  def primitive_convert(*_arg0); end
  def primitive_errinfo; end
  def putback(*_arg0); end
  def replacement; end
  def replacement=(_arg0); end
  def source_encoding; end

  class << self
    def asciicompat_encoding(_arg0); end
    def search_convpath(*_arg0); end
  end
end

Encoding::Converter::AFTER_OUTPUT = T.let(T.unsafe(nil), Integer)
Encoding::Converter::CRLF_NEWLINE_DECORATOR = T.let(T.unsafe(nil), Integer)
Encoding::Converter::CR_NEWLINE_DECORATOR = T.let(T.unsafe(nil), Integer)
Encoding::Converter::INVALID_MASK = T.let(T.unsafe(nil), Integer)
Encoding::Converter::INVALID_REPLACE = T.let(T.unsafe(nil), Integer)
Encoding::Converter::LF_NEWLINE_DECORATOR = T.let(T.unsafe(nil), Integer)
Encoding::Converter::PARTIAL_INPUT = T.let(T.unsafe(nil), Integer)
Encoding::Converter::UNDEF_HEX_CHARREF = T.let(T.unsafe(nil), Integer)
Encoding::Converter::UNDEF_MASK = T.let(T.unsafe(nil), Integer)
Encoding::Converter::UNDEF_REPLACE = T.let(T.unsafe(nil), Integer)
Encoding::Converter::UNIVERSAL_NEWLINE_DECORATOR = T.let(T.unsafe(nil), Integer)
Encoding::Converter::XML_ATTR_CONTENT_DECORATOR = T.let(T.unsafe(nil), Integer)
Encoding::Converter::XML_ATTR_QUOTE_DECORATOR = T.let(T.unsafe(nil), Integer)
Encoding::Converter::XML_TEXT_DECORATOR = T.let(T.unsafe(nil), Integer)
class Encoding::ConverterNotFoundError < ::EncodingError; end

class Encoding::InvalidByteSequenceError < ::EncodingError
  def destination_encoding; end
  def destination_encoding_name; end
  def error_bytes; end
  def incomplete_input?; end
  def readagain_bytes; end
  def source_encoding; end
  def source_encoding_name; end
end

class Encoding::UndefinedConversionError < ::EncodingError
  def destination_encoding; end
  def destination_encoding_name; end
  def error_char; end
  def source_encoding; end
  def source_encoding_name; end
end

class EncodingError < ::StandardError; end

module Enumerable
  def all?(*_arg0); end
  def any?(*_arg0); end
  def chain(*_arg0); end
  def chunk; end
  def chunk_while; end
  def collect; end
  def collect_concat; end
  def compact; end
  def count(*_arg0); end
  def cycle(*_arg0); end
  def detect(*_arg0); end
  def drop(_arg0); end
  def drop_while; end
  def each_cons(_arg0); end
  def each_entry(*_arg0); end
  def each_slice(_arg0); end
  def each_with_index(*_arg0); end
  def each_with_object(_arg0); end
  def entries(*_arg0); end
  def filter; end
  def filter_map; end
  def find(*_arg0); end
  def find_all; end
  def find_index(*_arg0); end
  def first(*_arg0); end
  def flat_map; end
  def grep(_arg0); end
  def grep_v(_arg0); end
  def group_by; end
  def include?(_arg0); end
  def inject(*_arg0); end
  def lazy; end
  def map; end
  def max(*_arg0); end
  def max_by(*_arg0); end
  def member?(_arg0); end
  def min(*_arg0); end
  def min_by(*_arg0); end
  def minmax; end
  def minmax_by; end
  def none?(*_arg0); end
  def one?(*_arg0); end
  def partition; end
  def reduce(*_arg0); end
  def reject; end
  def reverse_each(*_arg0); end
  def select; end
  def slice_after(*_arg0); end
  def slice_before(*_arg0); end
  def slice_when; end
  def sort; end
  def sort_by; end
  def sum(*_arg0); end
  def take(_arg0); end
  def take_while; end
  def tally(*_arg0); end
  def to_a(*_arg0); end
  def to_h(*_arg0); end
  def to_set(klass = T.unsafe(nil), *args, &block); end
  def uniq; end
  def zip(*_arg0); end
end

class Enumerator
  include ::Enumerable

  def initialize(*_arg0); end

  def +(_arg0); end
  def each(*_arg0); end
  def each_with_index; end
  def each_with_object(_arg0); end
  def feed(_arg0); end
  def inspect; end
  def next; end
  def next_values; end
  def peek; end
  def peek_values; end
  def rewind; end
  def size; end
  def with_index(*_arg0); end
  def with_object(_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def produce(*_arg0); end
    def product(*_arg0); end
  end
end

class Enumerator::ArithmeticSequence < ::Enumerator
  def ==(_arg0); end
  def ===(_arg0); end
  def begin; end
  def each; end
  def end; end
  def eql?(_arg0); end
  def exclude_end?; end
  def first(*_arg0); end
  def hash; end
  def inspect; end
  def last(*_arg0); end
  def size; end
  def step; end
end

class Enumerator::Chain < ::Enumerator
  def initialize(*_arg0); end

  def each(*_arg0); end
  def inspect; end
  def rewind; end
  def size; end

  private

  def initialize_copy(_arg0); end
end

class Enumerator::Generator
  include ::Enumerable

  def initialize(*_arg0); end

  def each(*_arg0); end

  private

  def initialize_copy(_arg0); end
end

class Enumerator::Lazy < ::Enumerator
  def initialize(*_arg0); end

  def chunk(*_arg0); end
  def chunk_while(*_arg0); end
  def collect; end
  def collect_concat; end
  def compact; end
  def drop(_arg0); end
  def drop_while; end
  def eager; end
  def enum_for(*_arg0); end
  def filter; end
  def filter_map; end
  def find_all; end
  def flat_map; end
  def force(*_arg0); end
  def grep(_arg0); end
  def grep_v(_arg0); end
  def lazy; end
  def map; end
  def reject; end
  def select; end
  def slice_after(*_arg0); end
  def slice_before(*_arg0); end
  def slice_when(*_arg0); end
  def take(_arg0); end
  def take_while; end
  def to_enum(*_arg0); end
  def uniq; end
  def with_index(*_arg0); end
  def zip(*_arg0); end

  private

  def _enumerable_collect; end
  def _enumerable_collect_concat; end
  def _enumerable_drop(_arg0); end
  def _enumerable_drop_while; end
  def _enumerable_filter; end
  def _enumerable_filter_map; end
  def _enumerable_find_all; end
  def _enumerable_flat_map; end
  def _enumerable_grep(_arg0); end
  def _enumerable_grep_v(_arg0); end
  def _enumerable_map; end
  def _enumerable_reject; end
  def _enumerable_select; end
  def _enumerable_take(_arg0); end
  def _enumerable_take_while; end
  def _enumerable_uniq; end
  def _enumerable_with_index(*_arg0); end
  def _enumerable_zip(*_arg0); end
end

class Enumerator::Producer
  def each; end
end

class Enumerator::Product < ::Enumerator
  def initialize(*_arg0); end

  def each; end
  def inspect; end
  def rewind; end
  def size; end

  private

  def initialize_copy(_arg0); end
end

class Enumerator::Yielder
  def initialize; end

  def <<(_arg0); end
  def to_proc; end
  def yield(*_arg0); end
end

module Errno; end
class Errno::E2BIG < ::SystemCallError; end
Errno::E2BIG::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EACCES < ::SystemCallError; end
Errno::EACCES::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EADDRINUSE < ::SystemCallError; end
Errno::EADDRINUSE::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EADDRNOTAVAIL < ::SystemCallError; end
Errno::EADDRNOTAVAIL::Errno = T.let(T.unsafe(nil), Integer)
Errno::EADV = Errno::NOERROR
class Errno::EAFNOSUPPORT < ::SystemCallError; end
Errno::EAFNOSUPPORT::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EAGAIN < ::SystemCallError; end
Errno::EAGAIN::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EALREADY < ::SystemCallError; end
Errno::EALREADY::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EAUTH < ::SystemCallError; end
Errno::EAUTH::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EBADARCH < ::SystemCallError; end
Errno::EBADARCH::Errno = T.let(T.unsafe(nil), Integer)
Errno::EBADE = Errno::NOERROR
class Errno::EBADEXEC < ::SystemCallError; end
Errno::EBADEXEC::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EBADF < ::SystemCallError; end
Errno::EBADF::Errno = T.let(T.unsafe(nil), Integer)
Errno::EBADFD = Errno::NOERROR
class Errno::EBADMACHO < ::SystemCallError; end
Errno::EBADMACHO::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EBADMSG < ::SystemCallError; end
Errno::EBADMSG::Errno = T.let(T.unsafe(nil), Integer)
Errno::EBADR = Errno::NOERROR
class Errno::EBADRPC < ::SystemCallError; end
Errno::EBADRPC::Errno = T.let(T.unsafe(nil), Integer)
Errno::EBADRQC = Errno::NOERROR
Errno::EBADSLT = Errno::NOERROR
Errno::EBFONT = Errno::NOERROR
class Errno::EBUSY < ::SystemCallError; end
Errno::EBUSY::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ECANCELED < ::SystemCallError; end
Errno::ECANCELED::Errno = T.let(T.unsafe(nil), Integer)
Errno::ECAPMODE = Errno::NOERROR
class Errno::ECHILD < ::SystemCallError; end
Errno::ECHILD::Errno = T.let(T.unsafe(nil), Integer)
Errno::ECHRNG = Errno::NOERROR
Errno::ECOMM = Errno::NOERROR
class Errno::ECONNABORTED < ::SystemCallError; end
Errno::ECONNABORTED::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ECONNREFUSED < ::SystemCallError; end
Errno::ECONNREFUSED::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ECONNRESET < ::SystemCallError; end
Errno::ECONNRESET::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EDEADLK < ::SystemCallError; end
Errno::EDEADLK::Errno = T.let(T.unsafe(nil), Integer)
Errno::EDEADLOCK = Errno::NOERROR
class Errno::EDESTADDRREQ < ::SystemCallError; end
Errno::EDESTADDRREQ::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EDEVERR < ::SystemCallError; end
Errno::EDEVERR::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EDOM < ::SystemCallError; end
Errno::EDOM::Errno = T.let(T.unsafe(nil), Integer)
Errno::EDOOFUS = Errno::NOERROR
Errno::EDOTDOT = Errno::NOERROR
class Errno::EDQUOT < ::SystemCallError; end
Errno::EDQUOT::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EEXIST < ::SystemCallError; end
Errno::EEXIST::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EFAULT < ::SystemCallError; end
Errno::EFAULT::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EFBIG < ::SystemCallError; end
Errno::EFBIG::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EFTYPE < ::SystemCallError; end
Errno::EFTYPE::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EHOSTDOWN < ::SystemCallError; end
Errno::EHOSTDOWN::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EHOSTUNREACH < ::SystemCallError; end
Errno::EHOSTUNREACH::Errno = T.let(T.unsafe(nil), Integer)
Errno::EHWPOISON = Errno::NOERROR
class Errno::EIDRM < ::SystemCallError; end
Errno::EIDRM::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EILSEQ < ::SystemCallError; end
Errno::EILSEQ::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EINPROGRESS < ::SystemCallError; end
Errno::EINPROGRESS::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EINTR < ::SystemCallError; end
Errno::EINTR::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EINVAL < ::SystemCallError; end
Errno::EINVAL::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EIO < ::SystemCallError; end
Errno::EIO::Errno = T.let(T.unsafe(nil), Integer)
Errno::EIPSEC = Errno::NOERROR
class Errno::EISCONN < ::SystemCallError; end
Errno::EISCONN::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EISDIR < ::SystemCallError; end
Errno::EISDIR::Errno = T.let(T.unsafe(nil), Integer)
Errno::EISNAM = Errno::NOERROR
Errno::EKEYEXPIRED = Errno::NOERROR
Errno::EKEYREJECTED = Errno::NOERROR
Errno::EKEYREVOKED = Errno::NOERROR
Errno::EL2HLT = Errno::NOERROR
Errno::EL2NSYNC = Errno::NOERROR
Errno::EL3HLT = Errno::NOERROR
Errno::EL3RST = Errno::NOERROR
class Errno::ELAST < ::SystemCallError; end
Errno::ELAST::Errno = T.let(T.unsafe(nil), Integer)
Errno::ELIBACC = Errno::NOERROR
Errno::ELIBBAD = Errno::NOERROR
Errno::ELIBEXEC = Errno::NOERROR
Errno::ELIBMAX = Errno::NOERROR
Errno::ELIBSCN = Errno::NOERROR
Errno::ELNRNG = Errno::NOERROR
class Errno::ELOOP < ::SystemCallError; end
Errno::ELOOP::Errno = T.let(T.unsafe(nil), Integer)
Errno::EMEDIUMTYPE = Errno::NOERROR
class Errno::EMFILE < ::SystemCallError; end
Errno::EMFILE::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EMLINK < ::SystemCallError; end
Errno::EMLINK::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EMSGSIZE < ::SystemCallError; end
Errno::EMSGSIZE::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EMULTIHOP < ::SystemCallError; end
Errno::EMULTIHOP::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENAMETOOLONG < ::SystemCallError; end
Errno::ENAMETOOLONG::Errno = T.let(T.unsafe(nil), Integer)
Errno::ENAVAIL = Errno::NOERROR
class Errno::ENEEDAUTH < ::SystemCallError; end
Errno::ENEEDAUTH::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENETDOWN < ::SystemCallError; end
Errno::ENETDOWN::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENETRESET < ::SystemCallError; end
Errno::ENETRESET::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENETUNREACH < ::SystemCallError; end
Errno::ENETUNREACH::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENFILE < ::SystemCallError; end
Errno::ENFILE::Errno = T.let(T.unsafe(nil), Integer)
Errno::ENOANO = Errno::NOERROR
class Errno::ENOATTR < ::SystemCallError; end
Errno::ENOATTR::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOBUFS < ::SystemCallError; end
Errno::ENOBUFS::Errno = T.let(T.unsafe(nil), Integer)
Errno::ENOCSI = Errno::NOERROR
class Errno::ENODATA < ::SystemCallError; end
Errno::ENODATA::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENODEV < ::SystemCallError; end
Errno::ENODEV::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOENT < ::SystemCallError; end
Errno::ENOENT::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOEXEC < ::SystemCallError; end
Errno::ENOEXEC::Errno = T.let(T.unsafe(nil), Integer)
Errno::ENOKEY = Errno::NOERROR
class Errno::ENOLCK < ::SystemCallError; end
Errno::ENOLCK::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOLINK < ::SystemCallError; end
Errno::ENOLINK::Errno = T.let(T.unsafe(nil), Integer)
Errno::ENOMEDIUM = Errno::NOERROR
class Errno::ENOMEM < ::SystemCallError; end
Errno::ENOMEM::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOMSG < ::SystemCallError; end
Errno::ENOMSG::Errno = T.let(T.unsafe(nil), Integer)
Errno::ENONET = Errno::NOERROR
Errno::ENOPKG = Errno::NOERROR
class Errno::ENOPOLICY < ::SystemCallError; end
Errno::ENOPOLICY::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOPROTOOPT < ::SystemCallError; end
Errno::ENOPROTOOPT::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOSPC < ::SystemCallError; end
Errno::ENOSPC::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOSR < ::SystemCallError; end
Errno::ENOSR::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOSTR < ::SystemCallError; end
Errno::ENOSTR::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOSYS < ::SystemCallError; end
Errno::ENOSYS::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOTBLK < ::SystemCallError; end
Errno::ENOTBLK::Errno = T.let(T.unsafe(nil), Integer)
Errno::ENOTCAPABLE = Errno::NOERROR
class Errno::ENOTCONN < ::SystemCallError; end
Errno::ENOTCONN::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOTDIR < ::SystemCallError; end
Errno::ENOTDIR::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOTEMPTY < ::SystemCallError; end
Errno::ENOTEMPTY::Errno = T.let(T.unsafe(nil), Integer)
Errno::ENOTNAM = Errno::NOERROR
class Errno::ENOTRECOVERABLE < ::SystemCallError; end
Errno::ENOTRECOVERABLE::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOTSOCK < ::SystemCallError; end
Errno::ENOTSOCK::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOTSUP < ::SystemCallError; end
Errno::ENOTSUP::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ENOTTY < ::SystemCallError; end
Errno::ENOTTY::Errno = T.let(T.unsafe(nil), Integer)
Errno::ENOTUNIQ = Errno::NOERROR
class Errno::ENXIO < ::SystemCallError; end
Errno::ENXIO::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EOPNOTSUPP < ::SystemCallError; end
Errno::EOPNOTSUPP::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EOVERFLOW < ::SystemCallError; end
Errno::EOVERFLOW::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EOWNERDEAD < ::SystemCallError; end
Errno::EOWNERDEAD::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EPERM < ::SystemCallError; end
Errno::EPERM::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EPFNOSUPPORT < ::SystemCallError; end
Errno::EPFNOSUPPORT::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EPIPE < ::SystemCallError; end
Errno::EPIPE::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EPROCLIM < ::SystemCallError; end
Errno::EPROCLIM::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EPROCUNAVAIL < ::SystemCallError; end
Errno::EPROCUNAVAIL::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EPROGMISMATCH < ::SystemCallError; end
Errno::EPROGMISMATCH::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EPROGUNAVAIL < ::SystemCallError; end
Errno::EPROGUNAVAIL::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EPROTO < ::SystemCallError; end
Errno::EPROTO::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EPROTONOSUPPORT < ::SystemCallError; end
Errno::EPROTONOSUPPORT::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EPROTOTYPE < ::SystemCallError; end
Errno::EPROTOTYPE::Errno = T.let(T.unsafe(nil), Integer)
class Errno::EPWROFF < ::SystemCallError; end
Errno::EPWROFF::Errno = T.let(T.unsafe(nil), Integer)
Errno::EQFULL = Errno::ELAST
class Errno::ERANGE < ::SystemCallError; end
Errno::ERANGE::Errno = T.let(T.unsafe(nil), Integer)
Errno::EREMCHG = Errno::NOERROR
class Errno::EREMOTE < ::SystemCallError; end
Errno::EREMOTE::Errno = T.let(T.unsafe(nil), Integer)
Errno::EREMOTEIO = Errno::NOERROR
Errno::ERESTART = Errno::NOERROR
Errno::ERFKILL = Errno::NOERROR
class Errno::EROFS < ::SystemCallError; end
Errno::EROFS::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ERPCMISMATCH < ::SystemCallError; end
Errno::ERPCMISMATCH::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ESHLIBVERS < ::SystemCallError; end
Errno::ESHLIBVERS::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ESHUTDOWN < ::SystemCallError; end
Errno::ESHUTDOWN::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ESOCKTNOSUPPORT < ::SystemCallError; end
Errno::ESOCKTNOSUPPORT::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ESPIPE < ::SystemCallError; end
Errno::ESPIPE::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ESRCH < ::SystemCallError; end
Errno::ESRCH::Errno = T.let(T.unsafe(nil), Integer)
Errno::ESRMNT = Errno::NOERROR
class Errno::ESTALE < ::SystemCallError; end
Errno::ESTALE::Errno = T.let(T.unsafe(nil), Integer)
Errno::ESTRPIPE = Errno::NOERROR
class Errno::ETIME < ::SystemCallError; end
Errno::ETIME::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ETIMEDOUT < ::SystemCallError; end
Errno::ETIMEDOUT::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ETOOMANYREFS < ::SystemCallError; end
Errno::ETOOMANYREFS::Errno = T.let(T.unsafe(nil), Integer)
class Errno::ETXTBSY < ::SystemCallError; end
Errno::ETXTBSY::Errno = T.let(T.unsafe(nil), Integer)
Errno::EUCLEAN = Errno::NOERROR
Errno::EUNATCH = Errno::NOERROR
class Errno::EUSERS < ::SystemCallError; end
Errno::EUSERS::Errno = T.let(T.unsafe(nil), Integer)
Errno::EWOULDBLOCK = Errno::EAGAIN
class Errno::EXDEV < ::SystemCallError; end
Errno::EXDEV::Errno = T.let(T.unsafe(nil), Integer)
Errno::EXFULL = Errno::NOERROR
class Errno::NOERROR < ::SystemCallError; end
Errno::NOERROR::Errno = T.let(T.unsafe(nil), Integer)

module ErrorHighlight
  class << self
    def formatter; end
    def formatter=(formatter); end
    def spot(obj, **opts); end
  end
end

module ErrorHighlight::CoreExt
  def detailed_message(highlight: T.unsafe(nil), error_highlight: T.unsafe(nil), **_arg2); end

  private

  def generate_snippet; end
end

class ErrorHighlight::DefaultFormatter
  class << self
    def message_for(spot); end
  end
end

class Exception
  def initialize(*_arg0); end

  def ==(_arg0); end
  def backtrace; end
  def backtrace_locations; end
  def cause; end
  def detailed_message(*_arg0); end
  def exception(*_arg0); end
  def full_message(*_arg0); end
  def inspect; end
  def message; end
  def respond_to?(*_arg0); end
  def set_backtrace(_arg0); end
  def to_s; end

  private

  def method_missing(*_arg0); end
  def respond_to_missing?(_arg0, _arg1); end

  class << self
    def exception(*_arg0); end
    def to_tty?; end
  end
end

class FalseClass
  def &(_arg0); end
  def ===(_arg0); end
  def ^(_arg0); end
  def inspect; end
  def pretty_print(q); end
  def pretty_print_cycle(q); end
  def to_s; end
  def |(_arg0); end
end

class Fiber
  def initialize(*_arg0); end

  def alive?; end
  def backtrace(*_arg0); end
  def backtrace_locations(*_arg0); end
  def blocking?; end
  def inspect; end
  def raise(*_arg0); end
  def resume(*_arg0); end
  def storage; end
  def storage=(_arg0); end
  def to_s; end
  def transfer(*_arg0); end

  class << self
    def [](_arg0); end
    def []=(_arg0, _arg1); end
    def blocking; end
    def blocking?; end
    def current; end
    def current_scheduler; end
    def schedule(*_arg0); end
    def scheduler; end
    def set_scheduler(_arg0); end
    def yield(*_arg0); end
  end
end

class FiberError < ::StandardError; end

class File < ::IO
  def initialize(*_arg0); end

  def atime; end
  def birthtime; end
  def chmod(_arg0); end
  def chown(_arg0, _arg1); end
  def ctime; end
  def flock(_arg0); end
  def lstat; end
  def mtime; end
  def size; end
  def truncate(_arg0); end

  class << self
    def absolute_path(*_arg0); end
    def absolute_path?(_arg0); end
    def atime(_arg0); end
    def basename(*_arg0); end
    def birthtime(_arg0); end
    def blockdev?(_arg0); end
    def chardev?(_arg0); end
    def chmod(*_arg0); end
    def chown(*_arg0); end
    def cleanpath(path, rel_root = T.unsafe(nil)); end
    def ctime(_arg0); end
    def delete(*_arg0); end
    def directory?(_arg0); end
    def dirname(*_arg0); end
    def empty?(_arg0); end
    def executable?(_arg0); end
    def executable_real?(_arg0); end
    def exist?(_arg0); end
    def expand_path(*_arg0); end
    def extname(_arg0); end
    def file?(_arg0); end
    def fnmatch(*_arg0); end
    def fnmatch?(*_arg0); end
    def ftype(_arg0); end
    def grpowned?(_arg0); end
    def identical?(_arg0, _arg1); end
    def join(*_arg0); end
    def lchmod(*_arg0); end
    def lchown(*_arg0); end
    def link(_arg0, _arg1); end
    def lstat(_arg0); end
    def lutime(*_arg0); end
    def mkfifo(*_arg0); end
    def mtime(_arg0); end
    def open!(file, *args, &block); end
    def owned?(_arg0); end
    def path(_arg0); end
    def pipe?(_arg0); end
    def read_binary(file); end
    def readable?(_arg0); end
    def readable_real?(_arg0); end
    def readlink(_arg0); end
    def realdirpath(*_arg0); end
    def realpath(*_arg0); end
    def relative_path(from, to); end
    def rename(_arg0, _arg1); end
    def setgid?(_arg0); end
    def setuid?(_arg0); end
    def size(_arg0); end
    def size?(_arg0); end
    def socket?(_arg0); end
    def split(_arg0); end
    def stat(_arg0); end
    def sticky?(_arg0); end
    def symlink(_arg0, _arg1); end
    def symlink?(_arg0); end
    def truncate(_arg0, _arg1); end
    def umask(*_arg0); end
    def unlink(*_arg0); end
    def utime(*_arg0); end
    def world_readable?(_arg0); end
    def world_writable?(_arg0); end
    def writable?(_arg0); end
    def writable_real?(_arg0); end
    def zero?(_arg0); end
  end
end

File::ALT_SEPARATOR = T.let(T.unsafe(nil), T.untyped)
module File::Constants; end
File::Constants::APPEND = T.let(T.unsafe(nil), Integer)
File::Constants::BINARY = T.let(T.unsafe(nil), Integer)
File::Constants::CREAT = T.let(T.unsafe(nil), Integer)
File::Constants::DSYNC = T.let(T.unsafe(nil), Integer)
File::Constants::EXCL = T.let(T.unsafe(nil), Integer)
File::Constants::FNM_CASEFOLD = T.let(T.unsafe(nil), Integer)
File::Constants::FNM_DOTMATCH = T.let(T.unsafe(nil), Integer)
File::Constants::FNM_EXTGLOB = T.let(T.unsafe(nil), Integer)
File::Constants::FNM_NOESCAPE = T.let(T.unsafe(nil), Integer)
File::Constants::FNM_PATHNAME = T.let(T.unsafe(nil), Integer)
File::Constants::FNM_SHORTNAME = T.let(T.unsafe(nil), Integer)
File::Constants::FNM_SYSCASE = T.let(T.unsafe(nil), Integer)
File::Constants::LOCK_EX = T.let(T.unsafe(nil), Integer)
File::Constants::LOCK_NB = T.let(T.unsafe(nil), Integer)
File::Constants::LOCK_SH = T.let(T.unsafe(nil), Integer)
File::Constants::LOCK_UN = T.let(T.unsafe(nil), Integer)
File::Constants::NOCTTY = T.let(T.unsafe(nil), Integer)
File::Constants::NOFOLLOW = T.let(T.unsafe(nil), Integer)
File::Constants::NONBLOCK = T.let(T.unsafe(nil), Integer)
File::Constants::NULL = T.let(T.unsafe(nil), String)
File::Constants::RDONLY = T.let(T.unsafe(nil), Integer)
File::Constants::RDWR = T.let(T.unsafe(nil), Integer)
File::Constants::SHARE_DELETE = T.let(T.unsafe(nil), Integer)
File::Constants::SYNC = T.let(T.unsafe(nil), Integer)
File::Constants::TRUNC = T.let(T.unsafe(nil), Integer)
File::Constants::WRONLY = T.let(T.unsafe(nil), Integer)
File::PATH_SEPARATOR = T.let(T.unsafe(nil), String)
File::SEPARATOR = T.let(T.unsafe(nil), String)
File::Separator = T.let(T.unsafe(nil), String)

class File::Stat
  include ::Comparable

  def initialize(_arg0); end

  def <=>(_arg0); end
  def atime; end
  def birthtime; end
  def blksize; end
  def blockdev?; end
  def blocks; end
  def chardev?; end
  def ctime; end
  def dev; end
  def dev_major; end
  def dev_minor; end
  def directory?; end
  def executable?; end
  def executable_real?; end
  def file?; end
  def ftype; end
  def gid; end
  def grpowned?; end
  def ino; end
  def inspect; end
  def mode; end
  def mtime; end
  def nlink; end
  def owned?; end
  def pipe?; end
  def pretty_print(q); end
  def rdev; end
  def rdev_major; end
  def rdev_minor; end
  def readable?; end
  def readable_real?; end
  def setgid?; end
  def setuid?; end
  def size; end
  def size?; end
  def socket?; end
  def sticky?; end
  def symlink?; end
  def uid; end
  def world_readable?; end
  def world_writable?; end
  def writable?; end
  def writable_real?; end
  def zero?; end

  private

  def initialize_copy(_arg0); end
end

module FileTest
  private

  def blockdev?(_arg0); end
  def chardev?(_arg0); end
  def directory?(_arg0); end
  def empty?(_arg0); end
  def executable?(_arg0); end
  def executable_real?(_arg0); end
  def exist?(_arg0); end
  def file?(_arg0); end
  def grpowned?(_arg0); end
  def identical?(_arg0, _arg1); end
  def owned?(_arg0); end
  def pipe?(_arg0); end
  def readable?(_arg0); end
  def readable_real?(_arg0); end
  def setgid?(_arg0); end
  def setuid?(_arg0); end
  def size(_arg0); end
  def size?(_arg0); end
  def socket?(_arg0); end
  def sticky?(_arg0); end
  def symlink?(_arg0); end
  def world_readable?(_arg0); end
  def world_writable?(_arg0); end
  def writable?(_arg0); end
  def writable_real?(_arg0); end
  def zero?(_arg0); end

  class << self
    def blockdev?(_arg0); end
    def chardev?(_arg0); end
    def directory?(_arg0); end
    def empty?(_arg0); end
    def executable?(_arg0); end
    def executable_real?(_arg0); end
    def exist?(_arg0); end
    def file?(_arg0); end
    def grpowned?(_arg0); end
    def identical?(_arg0, _arg1); end
    def owned?(_arg0); end
    def pipe?(_arg0); end
    def readable?(_arg0); end
    def readable_real?(_arg0); end
    def setgid?(_arg0); end
    def setuid?(_arg0); end
    def size(_arg0); end
    def size?(_arg0); end
    def socket?(_arg0); end
    def sticky?(_arg0); end
    def symlink?(_arg0); end
    def world_readable?(_arg0); end
    def world_writable?(_arg0); end
    def writable?(_arg0); end
    def writable_real?(_arg0); end
    def zero?(_arg0); end
  end
end

class Float < ::Numeric
  def %(_arg0); end
  def *(_arg0); end
  def **(_arg0); end
  def +(_arg0); end
  def -(_arg0); end
  def -@; end
  def /(_arg0); end
  def <(_arg0); end
  def <=(_arg0); end
  def <=>(_arg0); end
  def ==(_arg0); end
  def ===(_arg0); end
  def >(_arg0); end
  def >=(_arg0); end
  def abs; end
  def angle; end
  def arg; end
  def ceil(*_arg0); end
  def coerce(_arg0); end
  def denominator; end
  def divmod(_arg0); end
  def eql?(_arg0); end
  def fdiv(_arg0); end
  def finite?; end
  def floor(*_arg0); end
  def hash; end
  def infinite?; end
  def inspect; end
  def magnitude; end
  def modulo(_arg0); end
  def nan?; end
  def negative?; end
  def next_float; end
  def numerator; end
  def phase; end
  def positive?; end
  def prev_float; end
  def quo(_arg0); end
  def rationalize(*_arg0); end
  def round(*_arg0); end
  def to_f; end
  def to_i; end
  def to_int; end
  def to_r; end
  def to_s; end
  def truncate(*_arg0); end
  def zero?; end
end

Float::DIG = T.let(T.unsafe(nil), Integer)
Float::EPSILON = T.let(T.unsafe(nil), Float)
Float::INFINITY = T.let(T.unsafe(nil), Float)
Float::MANT_DIG = T.let(T.unsafe(nil), Integer)
Float::MAX = T.let(T.unsafe(nil), Float)
Float::MAX_10_EXP = T.let(T.unsafe(nil), Integer)
Float::MAX_EXP = T.let(T.unsafe(nil), Integer)
Float::MIN = T.let(T.unsafe(nil), Float)
Float::MIN_10_EXP = T.let(T.unsafe(nil), Integer)
Float::MIN_EXP = T.let(T.unsafe(nil), Integer)
Float::NAN = T.let(T.unsafe(nil), Float)
Float::RADIX = T.let(T.unsafe(nil), Integer)
class FloatDomainError < ::RangeError; end

class FrozenError < ::RuntimeError
  def initialize(*_arg0); end

  def receiver; end
end

module GC
  def garbage_collect(full_mark: T.unsafe(nil), immediate_mark: T.unsafe(nil), immediate_sweep: T.unsafe(nil)); end

  class << self
    def auto_compact; end
    def auto_compact=(_arg0); end
    def compact; end
    def count; end
    def disable; end
    def enable; end
    def latest_compact_info; end
    def latest_gc_info(hash_or_key = T.unsafe(nil)); end
    def measure_total_time; end
    def measure_total_time=(flag); end
    def start(full_mark: T.unsafe(nil), immediate_mark: T.unsafe(nil), immediate_sweep: T.unsafe(nil)); end
    def stat(hash_or_key = T.unsafe(nil)); end
    def stat_heap(heap_name = T.unsafe(nil), hash_or_key = T.unsafe(nil)); end
    def stress; end
    def stress=(flag); end
    def total_time; end
    def using_rvargc?; end
    def verify_compaction_references(toward: T.unsafe(nil), double_heap: T.unsafe(nil), expand_heap: T.unsafe(nil)); end
    def verify_internal_consistency; end
    def verify_transient_heap_internal_consistency; end
  end
end

GC::INTERNAL_CONSTANTS = T.let(T.unsafe(nil), Hash)
GC::OPTS = T.let(T.unsafe(nil), Array)

module GC::Profiler
  class << self
    def clear; end
    def disable; end
    def enable; end
    def enabled?; end
    def raw_data; end
    def report(*_arg0); end
    def result; end
    def total_time; end
  end
end

module Gem
  class << self
    def activate_bin_path(name, *args); end
    def activated_gem_paths; end
    def add_to_load_path(*paths); end
    def bin_path(name, *args); end
    def binary_mode; end
    def bindir(install_dir = T.unsafe(nil)); end
    def cache_home; end
    def clear_default_specs; end
    def clear_paths; end
    def config_file; end
    def config_home; end
    def configuration; end
    def configuration=(config); end
    def data_home; end
    def datadir(gem_name); end
    def default_bindir; end
    def default_cert_path; end
    def default_dir; end
    def default_exec_format; end
    def default_ext_dir_for(base_dir); end
    def default_key_path; end
    def default_path; end
    def default_rubygems_dirs; end
    def default_sources; end
    def default_spec_cache_dir; end
    def default_specifications_dir; end
    def deflate(data); end
    def dir; end
    def disable_system_update_message; end
    def disable_system_update_message=(_arg0); end
    def done_installing(&hook); end
    def done_installing_hooks; end
    def ensure_default_gem_subdirectories(dir = T.unsafe(nil), mode = T.unsafe(nil)); end
    def ensure_gem_subdirectories(dir = T.unsafe(nil), mode = T.unsafe(nil)); end
    def ensure_subdirectories(dir, mode, subdirs); end
    def env_requirement(gem_name); end
    def extension_api_version; end
    def find_config_file; end
    def find_files(glob, check_load_path = T.unsafe(nil)); end
    def find_files_from_load_path(glob); end
    def find_latest_files(glob, check_load_path = T.unsafe(nil)); end
    def find_unresolved_default_spec(path); end
    def finish_resolve(*_arg0); end
    def gemdeps; end
    def host; end
    def host=(host); end
    def install(name, version = T.unsafe(nil), *options); end
    def install_extension_in_lib; end
    def java_platform?; end
    def latest_rubygems_version; end
    def latest_spec_for(name); end
    def latest_version_for(name); end
    def load_env_plugins; end
    def load_path_insert_index; end
    def load_plugin_files(plugins); end
    def load_plugins; end
    def load_yaml; end
    def loaded_specs; end
    def location_of_caller(depth = T.unsafe(nil)); end
    def marshal_version; end
    def needs; end
    def open_file(path, flags, &block); end
    def operating_system_defaults; end
    def path; end
    def path_separator; end
    def paths; end
    def paths=(env); end
    def platform_defaults; end
    def platforms; end
    def platforms=(platforms); end
    def plugin_suffix_pattern; end
    def plugin_suffix_regexp; end
    def plugindir(install_dir = T.unsafe(nil)); end
    def post_build(&hook); end
    def post_build_hooks; end
    def post_install(&hook); end
    def post_install_hooks; end
    def post_reset(&hook); end
    def post_reset_hooks; end
    def post_uninstall(&hook); end
    def post_uninstall_hooks; end
    def pre_install(&hook); end
    def pre_install_hooks; end
    def pre_reset(&hook); end
    def pre_reset_hooks; end
    def pre_uninstall(&hook); end
    def pre_uninstall_hooks; end
    def prefix; end
    def read_binary(path); end
    def refresh; end
    def register_default_spec(spec); end
    def ruby; end
    def ruby_api_version; end
    def ruby_engine; end
    def ruby_version; end
    def rubygems_version; end
    def solaris_platform?; end
    def source_date_epoch; end
    def source_date_epoch_string; end
    def source_index; end
    def sources; end
    def sources=(new_sources); end
    def spec_cache_dir; end
    def state_file; end
    def state_home; end
    def suffix_pattern; end
    def suffix_regexp; end
    def suffixes; end
    def time(msg, width = T.unsafe(nil), display = T.unsafe(nil)); end
    def try_activate(path); end
    def ui; end
    def use_gemdeps(path = T.unsafe(nil)); end
    def use_paths(home, *paths); end
    def user_dir; end
    def user_home; end
    def vendor_dir; end
    def win_platform?; end
    def write_binary(path, data); end

    private

    def already_loaded?(file); end
    def default_gem_load_paths; end
    def find_home; end
    def find_spec_for_exe(gem_name, *args); end
  end
end

class Gem::BasicSpecification
  def initialize; end

  def activated?; end
  def base_dir; end
  def base_dir=(_arg0); end
  def contains_requirable_file?(file); end
  def datadir; end
  def default_gem?; end
  def extension_dir; end
  def extension_dir=(_arg0); end
  def extensions_dir; end
  def full_gem_path; end
  def full_gem_path=(_arg0); end
  def full_name; end
  def full_require_paths; end
  def gem_build_complete_path; end
  def gem_dir; end
  def gems_dir; end
  def ignored=(_arg0); end
  def internal_init; end
  def lib_dirs_glob; end
  def loaded_from; end
  def loaded_from=(_arg0); end
  def matches_for_glob(glob); end
  def name; end
  def platform; end
  def plugins; end
  def raw_require_paths; end
  def require_paths; end
  def source_paths; end
  def stubbed?; end
  def this; end
  def to_fullpath(path); end
  def to_spec; end
  def version; end

  private

  def find_full_gem_path; end
  def have_extensions?; end
  def have_file?(file, suffixes); end

  class << self
    def _deprecated_default_specifications_dir; end
    def default_specifications_dir(*args, **_arg1, &block); end
  end
end

module Gem::BundlerVersionFinder
  class << self
    def bundler_version; end
    def prioritize!(specs); end

    private

    def bundle_update_bundler_version; end
    def lockfile_contents; end
    def lockfile_version; end
  end
end

class Gem::CommandLineError < ::Gem::Exception; end

class Gem::ConfigFile
  include ::Gem::Text
  include ::Gem::DefaultUserInteraction

  def initialize(args); end

  def ==(other); end
  def [](key); end
  def []=(key, value); end
  def api_keys; end
  def args; end
  def backtrace; end
  def backtrace=(_arg0); end
  def bulk_threshold; end
  def bulk_threshold=(_arg0); end
  def cert_expiration_length_days; end
  def cert_expiration_length_days=(_arg0); end
  def check_credentials_permissions; end
  def concurrent_downloads; end
  def concurrent_downloads=(_arg0); end
  def config_file_name; end
  def credentials_path; end
  def disable_default_gem_server; end
  def disable_default_gem_server=(_arg0); end
  def each(&block); end
  def handle_arguments(arg_list); end
  def home; end
  def home=(_arg0); end
  def ipv4_fallback_enabled; end
  def ipv4_fallback_enabled=(_arg0); end
  def last_update_check; end
  def last_update_check=(timestamp); end
  def load_api_keys; end
  def load_file(filename); end
  def path; end
  def path=(_arg0); end
  def really_verbose; end
  def rubygems_api_key; end
  def rubygems_api_key=(api_key); end
  def set_api_key(host, api_key); end
  def sources; end
  def sources=(_arg0); end
  def ssl_ca_cert; end
  def ssl_ca_cert=(_arg0); end
  def ssl_client_cert; end
  def ssl_verify_mode; end
  def state_file_name; end
  def state_file_writable?; end
  def to_yaml; end
  def unset_api_key!; end
  def update_sources; end
  def update_sources=(_arg0); end
  def verbose; end
  def verbose=(_arg0); end
  def write; end

  protected

  def hash; end

  private

  def set_config_file_name(args); end
end

class Gem::ConflictError < ::Gem::LoadError
  def initialize(target, conflicts); end

  def conflicts; end
  def target; end
end

class Gem::ConsoleUI < ::Gem::StreamUI
  def initialize; end
end

module Gem::DefaultUserInteraction
  include ::Gem::Text

  def ui; end
  def ui=(new_ui); end
  def use_ui(new_ui, &block); end

  class << self
    def ui; end
    def ui=(new_ui); end
    def use_ui(new_ui); end
  end
end

class Gem::Dependency
  include ::Bundler::ForcePlatform

  def initialize(name, *requirements); end

  def <=>(other); end
  def ==(other); end
  def ===(other); end
  def =~(other); end
  def encode_with(coder); end
  def eql?(other); end
  def force_ruby_platform; end
  def groups; end
  def groups=(_arg0); end
  def hash; end
  def identity; end
  def inspect; end
  def latest_version?; end
  def match?(obj, version = T.unsafe(nil), allow_prerelease = T.unsafe(nil)); end
  def matches_spec?(spec); end
  def matching_specs(platform_only = T.unsafe(nil)); end
  def merge(other); end
  def name; end
  def name=(_arg0); end
  def prerelease=(_arg0); end
  def prerelease?; end
  def pretty_print(q); end
  def prioritizes_bundler?; end
  def requirement; end
  def requirements_list; end
  def runtime?; end
  def source; end
  def source=(_arg0); end
  def specific?; end
  def to_lock; end
  def to_s; end
  def to_spec; end
  def to_specs; end
  def to_yaml_properties; end
  def type; end
end

class Gem::DependencyError < ::Gem::Exception; end

class Gem::DependencyList
  def initialize(development = T.unsafe(nil)); end

  def add(*gemspecs); end
  def clear; end
  def dependency_order; end
  def development; end
  def development=(_arg0); end
  def each(&block); end
  def find_name(full_name); end
  def inspect; end
  def ok?; end
  def ok_to_remove?(full_name, check_dev = T.unsafe(nil)); end
  def remove_by_name(full_name); end
  def remove_specs_unsatisfied_by(dependencies); end
  def spec_predecessors; end
  def specs; end
  def tsort_each_child(node); end
  def tsort_each_node(&block); end
  def why_not_ok?(quick = T.unsafe(nil)); end

  private

  def active_count(specs, ignored); end

  class << self
    def from_specs; end
  end
end

class Gem::DependencyRemovalException < ::Gem::Exception; end

class Gem::DependencyResolutionError < ::Gem::DependencyError
  def initialize(conflict); end

  def conflict; end
  def conflicting_dependencies; end
end

module Gem::Deprecate
  def deprecate(name, repl, year, month); end

  private

  def rubygems_deprecate(name, replacement = T.unsafe(nil)); end
  def rubygems_deprecate_command; end
  def skip_during; end

  class << self
    def next_rubygems_major_version; end
    def rubygems_deprecate(name, replacement = T.unsafe(nil)); end
    def rubygems_deprecate_command; end
    def skip; end
    def skip=(v); end
    def skip_during; end
  end
end

class Gem::DocumentError < ::Gem::Exception; end
class Gem::EndOfYAMLException < ::Gem::Exception; end
class Gem::ErrorReason; end
class Gem::Exception < ::RuntimeError; end
module Gem::Ext; end
class Gem::Ext::BuildError < ::Gem::InstallError; end

class Gem::Ext::Builder
  include ::Gem::Text
  include ::Gem::DefaultUserInteraction
  include ::Gem::UserInteraction

  def initialize(spec, build_args = T.unsafe(nil)); end

  def build_args; end
  def build_args=(_arg0); end
  def build_error(output, backtrace = T.unsafe(nil)); end
  def build_extension(extension, dest_path); end
  def build_extensions; end
  def builder_for(extension); end
  def write_gem_make_out(output); end

  class << self
    def class_name; end
    def make(dest_path, results, make_dir = T.unsafe(nil), sitedir = T.unsafe(nil), targets = T.unsafe(nil)); end
    def run(command, results, command_name = T.unsafe(nil), dir = T.unsafe(nil), env = T.unsafe(nil)); end
  end
end

class Gem::Ext::CargoBuilder < ::Gem::Ext::Builder
  def initialize(spec); end

  def build(_extension, dest_path, results, args = T.unsafe(nil), lib_dir = T.unsafe(nil), cargo_dir = T.unsafe(nil)); end
  def build_crate(dest_path, results, args, cargo_dir); end
  def build_env; end
  def cargo_command(cargo_dir, dest_path, args = T.unsafe(nil)); end
  def profile; end
  def profile=(_arg0); end
  def runner; end
  def runner=(_arg0); end
  def spec; end
  def spec=(_arg0); end

  private

  def cargo_crate_name; end
  def cargo_dylib_path(dest_path); end
  def cargo_rustc_args(dest_dir); end
  def darwin_target?; end
  def final_extension_path(dest_path); end
  def finalize_directory(dest_path, lib_dir, extension_dir); end
  def get_relative_path(path, base); end
  def ldflag_to_link_modifier(arg); end
  def libruby_args(dest_dir); end
  def linker_args; end
  def makefile_config(var_name); end
  def maybe_resolve_ldflag_variable(input_arg, dest_dir); end
  def mingw_target?; end
  def mkmf_libpath; end
  def msvc_target?; end
  def mswin_link_args; end
  def platform_specific_rustc_args(dest_dir, flags = T.unsafe(nil)); end
  def rb_config_env; end
  def rename_cdylib_for_ruby_compatibility(dest_path); end
  def ruby_static?; end
  def rustc_dynamic_linker_flags(dest_dir); end
  def rustc_lib_flags(dest_dir); end
  def so_ext; end
  def split_flags(var); end
  def validate_cargo_build!(dir); end
  def win_target?; end
  def write_deffile(dest_dir); end
end

class Gem::Ext::CargoBuilder::DylibNotFoundError < ::StandardError
  def initialize(dir); end
end

class Gem::Ext::CmakeBuilder < ::Gem::Ext::Builder
  class << self
    def build(extension, dest_path, results, args = T.unsafe(nil), lib_dir = T.unsafe(nil), cmake_dir = T.unsafe(nil)); end
  end
end

class Gem::Ext::ConfigureBuilder < ::Gem::Ext::Builder
  class << self
    def build(extension, dest_path, results, args = T.unsafe(nil), lib_dir = T.unsafe(nil), configure_dir = T.unsafe(nil)); end
  end
end

class Gem::Ext::ExtConfBuilder < ::Gem::Ext::Builder
  class << self
    def build(extension, dest_path, results, args = T.unsafe(nil), lib_dir = T.unsafe(nil), extension_dir = T.unsafe(nil)); end
    def get_relative_path(path, base); end
  end
end

class Gem::Ext::RakeBuilder < ::Gem::Ext::Builder
  class << self
    def build(extension, dest_path, results, args = T.unsafe(nil), lib_dir = T.unsafe(nil), extension_dir = T.unsafe(nil)); end
  end
end

class Gem::FilePermissionError < ::Gem::Exception
  def initialize(directory); end

  def directory; end
end

class Gem::FormatException < ::Gem::Exception
  def file_path; end
  def file_path=(_arg0); end
end

class Gem::GemNotFoundException < ::Gem::Exception; end

class Gem::GemNotInHomeException < ::Gem::Exception
  def spec; end
  def spec=(_arg0); end
end

class Gem::ImpossibleDependenciesError < ::Gem::Exception
  def initialize(request, conflicts); end

  def build_message; end
  def conflicts; end
  def dependency; end
  def request; end
end

class Gem::InstallError < ::Gem::Exception; end

class Gem::Installer
  include ::Gem::Text
  include ::Gem::DefaultUserInteraction

  def initialize(package, options = T.unsafe(nil)); end

  def _deprecated_unpack(directory); end
  def app_script_text(bin_file_name); end
  def bin_dir; end
  def build_extensions; end
  def build_root; end
  def check_executable_overwrite(filename); end
  def check_that_user_bin_dir_is_in_path; end
  def default_spec_file; end
  def dir; end
  def ensure_dependencies_met; end
  def ensure_dependency(spec, dependency); end
  def ensure_loadable_spec; end
  def ensure_writable_dir(dir); end
  def explicit_version_requirement(name); end
  def extract_bin; end
  def extract_files; end
  def formatted_program_filename(filename); end
  def gem; end
  def gem_dir; end
  def gem_home; end
  def gemdeps_load(name); end
  def generate_bin; end
  def generate_bin_script(filename, bindir); end
  def generate_bin_symlink(filename, bindir); end
  def generate_plugins; end
  def generate_windows_script(filename, bindir); end
  def install; end
  def installation_satisfies_dependency?(dependency); end
  def installed_specs; end
  def options; end
  def package; end
  def pre_install_checks; end
  def process_options; end
  def run_post_build_hooks; end
  def run_post_install_hooks; end
  def run_pre_install_hooks; end
  def shebang(bin_file_name); end
  def spec; end
  def spec_file; end
  def unpack(*args, **_arg1, &block); end
  def verify_gem_home; end
  def verify_spec; end
  def windows_stub_script(bindir, bin_file_name); end
  def write_build_info_file; end
  def write_cache_file; end
  def write_default_spec; end
  def write_spec; end

  private

  def bash_prolog_script; end
  def build_args; end
  def load_relative_enabled?; end
  def rb_config; end
  def ruby_install_name; end

  class << self
    def at(path, options = T.unsafe(nil)); end
    def exec_format; end
    def exec_format=(_arg0); end
    def for_spec(spec, options = T.unsafe(nil)); end
    def inherited(klass); end
    def path_warning; end
    def path_warning=(_arg0); end
  end
end

class Gem::Installer::FakePackage
  def initialize(spec); end

  def copy_to(path); end
  def data_mode; end
  def data_mode=(_arg0); end
  def dir_mode; end
  def dir_mode=(_arg0); end
  def extract_files(destination_dir, pattern = T.unsafe(nil)); end
  def prog_mode; end
  def prog_mode=(_arg0); end
  def spec; end
  def spec=(_arg0); end
end

class Gem::InvalidSpecificationException < ::Gem::Exception; end

class Gem::Licenses
  class << self
    def match?(license); end
    def suggestions(license); end
  end
end

class Gem::List
  include ::Enumerable

  def initialize(value = T.unsafe(nil), tail = T.unsafe(nil)); end

  def each; end
  def prepend(value); end
  def pretty_print(q); end
  def tail; end
  def tail=(_arg0); end
  def to_a; end
  def value; end
  def value=(_arg0); end

  class << self
    def prepend(list, value); end
  end
end

class Gem::LoadError < ::LoadError
  def name; end
  def name=(_arg0); end
  def requirement; end
  def requirement=(_arg0); end
end

class Gem::MissingSpecError < ::Gem::LoadError
  def initialize(name, requirement, extra_message = T.unsafe(nil)); end

  def message; end

  private

  def build_message; end
end

class Gem::MissingSpecVersionError < ::Gem::MissingSpecError
  def initialize(name, requirement, specs); end

  def specs; end

  private

  def build_message; end
end

class Gem::NameTuple
  def initialize(name, version, platform = T.unsafe(nil)); end

  def <=>(other); end
  def ==(other); end
  def eql?(other); end
  def full_name; end
  def hash; end
  def inspect; end
  def match_platform?; end
  def name; end
  def platform; end
  def prerelease?; end
  def spec_name; end
  def to_a; end
  def to_s; end
  def version; end

  class << self
    def from_list(list); end
    def null; end
    def to_basic(list); end
  end
end

class Gem::OperationNotSupportedError < ::Gem::Exception; end

class Gem::PathSupport
  def initialize(env); end

  def home; end
  def path; end
  def spec_cache_dir; end

  private

  def default_path; end
  def expand(path); end
  def split_gem_path(gpaths, home); end
end

class Gem::Platform
  def initialize(arch); end

  def ==(other); end
  def ===(other); end
  def =~(other); end
  def cpu; end
  def cpu=(_arg0); end
  def eql?(other); end
  def hash; end
  def normalized_linux_version; end
  def normalized_linux_version_ext; end
  def os; end
  def os=(_arg0); end
  def to_a; end
  def to_s; end
  def version; end
  def version=(_arg0); end

  class << self
    def installable?(spec); end
    def local; end
    def match(platform); end
    def match_gem?(platform, gem_name); end
    def match_spec?(spec); end
    def new(arch); end
    def sort_priority(platform); end

    private

    def match_platforms?(platform, platforms); end
  end
end

class Gem::PlatformMismatch < ::Gem::ErrorReason
  def initialize(name, version); end

  def add_platform(platform); end
  def name; end
  def platforms; end
  def version; end
  def wordy; end
end

class Gem::RemoteError < ::Gem::Exception; end
class Gem::RemoteInstallationCancelled < ::Gem::Exception; end
class Gem::RemoteInstallationSkipped < ::Gem::Exception; end
class Gem::RemoteSourceException < ::Gem::Exception; end

class Gem::RequestSet
  include ::Gem::TSort

  def initialize(*deps); end

  def always_install; end
  def always_install=(_arg0); end
  def dependencies; end
  def development; end
  def development=(_arg0); end
  def development_shallow; end
  def development_shallow=(_arg0); end
  def errors; end
  def gem(name, *reqs); end
  def git_set; end
  def ignore_dependencies; end
  def ignore_dependencies=(_arg0); end
  def import(deps); end
  def install(options, &block); end
  def install_dir; end
  def install_from_gemdeps(options, &block); end
  def install_hooks(requests, options); end
  def install_into(dir, force = T.unsafe(nil), options = T.unsafe(nil)); end
  def load_gemdeps(path, without_groups = T.unsafe(nil), installing = T.unsafe(nil)); end
  def prerelease; end
  def prerelease=(_arg0); end
  def pretty_print(q); end
  def remote; end
  def remote=(_arg0); end
  def resolve(set = T.unsafe(nil)); end
  def resolve_current; end
  def resolver; end
  def sets; end
  def soft_missing; end
  def soft_missing=(_arg0); end
  def sorted_requests; end
  def source_set; end
  def specs; end
  def specs_in(dir); end
  def tsort_each_child(node); end
  def tsort_each_node(&block); end
  def vendor_set; end
end

class Gem::RequestSet::GemDependencyAPI
  def initialize(set, path); end

  def dependencies; end
  def find_gemspec(name, path); end
  def gem(name, *requirements); end
  def gem_deps_file; end
  def gem_git_reference(options); end
  def gemspec(options = T.unsafe(nil)); end
  def git(repository); end
  def git_set; end
  def git_source(name, &callback); end
  def group(*groups); end
  def installing=(installing); end
  def load; end
  def platform(*platforms); end
  def platforms(*platforms); end
  def requires; end
  def ruby(version, options = T.unsafe(nil)); end
  def source(url); end
  def vendor_set; end
  def without_groups; end
  def without_groups=(_arg0); end

  private

  def add_dependencies(groups, dependencies); end
  def gem_git(name, options); end
  def gem_git_source(name, options); end
  def gem_group(name, options); end
  def gem_path(name, options); end
  def gem_platforms(name, options); end
  def gem_requires(name, options); end
  def gem_source(name, options); end
  def pin_gem_source(name, type = T.unsafe(nil), source = T.unsafe(nil)); end
end

class Gem::RequestSet::Lockfile
  def initialize(request_set, gem_deps_file, dependencies); end

  def add_DEPENDENCIES(out); end
  def add_GEM(out, spec_groups); end
  def add_GIT(out, git_requests); end
  def add_PATH(out, path_requests); end
  def add_PLATFORMS(out); end
  def platforms; end
  def relative_path_from(dest, base); end
  def spec_groups; end
  def to_s; end
  def write; end

  private

  def requests; end

  class << self
    def build(request_set, gem_deps_file, dependencies = T.unsafe(nil)); end
    def requests_to_deps(requests); end
  end
end

class Gem::RequestSet::Lockfile::ParseError < ::Gem::Exception
  def initialize(message, column, line, path); end

  def column; end
  def line; end
  def path; end
end

class Gem::RequestSet::Lockfile::Parser
  def initialize(tokenizer, set, platforms, filename = T.unsafe(nil)); end

  def get(expected_types = T.unsafe(nil), expected_value = T.unsafe(nil)); end
  def parse; end
  def parse_DEPENDENCIES; end
  def parse_GEM; end
  def parse_GIT; end
  def parse_PATH; end
  def parse_PLATFORMS; end
  def parse_dependency(name, op); end

  private

  def peek; end
  def pinned_requirement(name); end
  def skip(type); end
  def unget(token); end
end

class Gem::RequestSet::Lockfile::Tokenizer
  def initialize(input, filename = T.unsafe(nil), line = T.unsafe(nil), pos = T.unsafe(nil)); end

  def empty?; end
  def make_parser(set, platforms); end
  def next_token; end
  def peek; end
  def shift; end
  def skip(type); end
  def to_a; end
  def token_pos(byte_offset); end
  def unshift(token); end

  private

  def tokenize(input); end

  class << self
    def from_file(file); end
  end
end

class Gem::RequestSet::Lockfile::Tokenizer::Token < ::Struct
  def column; end
  def column=(_); end
  def line; end
  def line=(_); end
  def type; end
  def type=(_); end
  def value; end
  def value=(_); end

  class << self
    def [](*_arg0); end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

class Gem::Requirement
  def initialize(*requirements); end

  def ==(other); end
  def ===(version); end
  def =~(version); end
  def as_list; end
  def concat(new); end
  def encode_with(coder); end
  def exact?; end
  def for_lockfile; end
  def hash; end
  def init_with(coder); end
  def marshal_dump; end
  def marshal_load(array); end
  def none?; end
  def prerelease?; end
  def pretty_print(q); end
  def requirements; end
  def satisfied_by?(version); end
  def specific?; end
  def to_s; end
  def to_yaml_properties; end
  def yaml_initialize(tag, vals); end

  protected

  def _sorted_requirements; end
  def _tilde_requirements; end

  class << self
    def create(*inputs); end
    def default; end
    def default_prerelease; end
    def parse(obj); end
    def source_set; end
  end
end

class Gem::Requirement::BadRequirementError < ::ArgumentError; end

class Gem::Resolver
  include ::Gem::Resolver::Molinillo::UI
  include ::Gem::Resolver::Molinillo::SpecificationProvider

  def initialize(needed, set = T.unsafe(nil)); end

  def activation_request(dep, possible); end
  def allow_missing?(dependency); end
  def debug?; end
  def dependencies_for(specification); end
  def development; end
  def development=(_arg0); end
  def development_shallow; end
  def development_shallow=(_arg0); end
  def explain(stage, *data); end
  def explain_list(stage); end
  def find_possible(dependency); end
  def ignore_dependencies; end
  def ignore_dependencies=(_arg0); end
  def missing; end
  def name_for(dependency); end
  def output; end
  def requests(s, act, reqs = T.unsafe(nil)); end
  def requirement_satisfied_by?(requirement, activated, spec); end
  def resolve; end
  def search_for(dependency); end
  def select_local_platforms(specs); end
  def skip_gems; end
  def skip_gems=(_arg0); end
  def soft_missing; end
  def soft_missing=(_arg0); end
  def sort_dependencies(dependencies, activated, conflicts); end
  def stats; end

  private

  def amount_constrained(dependency); end

  class << self
    def compose_sets(*sets); end
    def for_current_gems(needed); end
  end
end

class Gem::Resolver::APISet < ::Gem::Resolver::Set
  def initialize(dep_uri = T.unsafe(nil)); end

  def dep_uri; end
  def find_all(req); end
  def prefetch(reqs); end
  def prefetch_now; end
  def pretty_print(q); end
  def source; end
  def uri; end
  def versions(name); end

  private

  def lines(str); end
  def parse_gem(string); end
end

class Gem::Resolver::APISet::GemParser
  def parse(line); end

  private

  def parse_dependency(string); end
end

class Gem::Resolver::APISpecification < ::Gem::Resolver::Specification
  def initialize(set, api_data); end

  def ==(other); end
  def fetch_development_dependencies; end
  def hash; end
  def installable_platform?; end
  def pretty_print(q); end
  def source; end
  def spec; end

  class << self
    def new(set, api_data); end
  end
end

class Gem::Resolver::ActivationRequest
  def initialize(spec, request); end

  def ==(other); end
  def development?; end
  def download(path); end
  def eql?(other); end
  def full_name; end
  def full_spec; end
  def hash; end
  def inspect; end
  def installed?; end
  def name; end
  def parent; end
  def platform; end
  def pretty_print(q); end
  def request; end
  def spec; end
  def to_s; end
  def version; end

  private

  def name_tuple; end
end

class Gem::Resolver::BestSet < ::Gem::Resolver::ComposedSet
  def initialize(sources = T.unsafe(nil)); end

  def find_all(req); end
  def pick_sets; end
  def prefetch(reqs); end
  def pretty_print(q); end
  def replace_failed_api_set(error); end
end

class Gem::Resolver::ComposedSet < ::Gem::Resolver::Set
  def initialize(*sets); end

  def errors; end
  def find_all(req); end
  def prefetch(reqs); end
  def prerelease=(allow_prerelease); end
  def remote=(remote); end
  def sets; end
end

class Gem::Resolver::Conflict
  def initialize(dependency, activated, failed_dep = T.unsafe(nil)); end

  def ==(other); end
  def activated; end
  def conflicting_dependencies; end
  def dependency; end
  def explain; end
  def explanation; end
  def failed_dep; end
  def for_spec?(spec); end
  def pretty_print(q); end
  def request_path(current); end
  def requester; end
end

class Gem::Resolver::CurrentSet < ::Gem::Resolver::Set
  def find_all(req); end
end

class Gem::Resolver::DependencyRequest
  def initialize(dependency, requester); end

  def ==(other); end
  def dependency; end
  def development?; end
  def explicit?; end
  def implicit?; end
  def match?(spec, allow_prerelease = T.unsafe(nil)); end
  def matches_spec?(spec); end
  def name; end
  def pretty_print(q); end
  def request_context; end
  def requester; end
  def requirement; end
  def to_s; end
  def type; end
end

class Gem::Resolver::GitSet < ::Gem::Resolver::Set
  def initialize; end

  def add_git_gem(name, repository, reference, submodules); end
  def add_git_spec(name, version, repository, reference, submodules); end
  def find_all(req); end
  def need_submodules; end
  def prefetch(reqs); end
  def pretty_print(q); end
  def repositories; end
  def root_dir; end
  def root_dir=(_arg0); end
  def specs; end
end

class Gem::Resolver::GitSpecification < ::Gem::Resolver::SpecSpecification
  def ==(other); end
  def add_dependency(dependency); end
  def install(options = T.unsafe(nil)); end
  def pretty_print(q); end
end

class Gem::Resolver::IndexSet < ::Gem::Resolver::Set
  def initialize(source = T.unsafe(nil)); end

  def find_all(req); end
  def pretty_print(q); end
end

class Gem::Resolver::IndexSpecification < ::Gem::Resolver::Specification
  def initialize(set, name, version, source, platform); end

  def ==(other); end
  def dependencies; end
  def hash; end
  def inspect; end
  def pretty_print(q); end
  def required_ruby_version; end
  def required_rubygems_version; end
  def spec; end
end

class Gem::Resolver::InstalledSpecification < ::Gem::Resolver::SpecSpecification
  def ==(other); end
  def install(options = T.unsafe(nil)); end
  def installable_platform?; end
  def pretty_print(q); end
  def source; end
end

class Gem::Resolver::InstallerSet < ::Gem::Resolver::Set
  def initialize(domain); end

  def add_always_install(dependency); end
  def add_local(dep_name, spec, source); end
  def always_install; end
  def consider_local?; end
  def consider_remote?; end
  def errors; end
  def find_all(req); end
  def force; end
  def force=(_arg0); end
  def ignore_dependencies; end
  def ignore_dependencies=(_arg0); end
  def ignore_installed; end
  def ignore_installed=(_arg0); end
  def inspect; end
  def load_spec(name, ver, platform, source); end
  def local?(dep_name); end
  def prefetch(reqs); end
  def prerelease=(allow_prerelease); end
  def pretty_print(q); end
  def remote=(remote); end
  def remote_set; end

  private

  def ensure_required_ruby_version_met(spec); end
  def ensure_required_rubygems_version_met(spec); end
  def metadata_satisfied?(spec); end
end

class Gem::Resolver::LocalSpecification < ::Gem::Resolver::SpecSpecification
  def installable_platform?; end
  def local?; end
  def pretty_print(q); end
end

class Gem::Resolver::LockSet < ::Gem::Resolver::Set
  def initialize(sources); end

  def add(name, version, platform); end
  def find_all(req); end
  def load_spec(name, version, platform, source); end
  def pretty_print(q); end
  def specs; end
end

class Gem::Resolver::LockSpecification < ::Gem::Resolver::Specification
  def initialize(set, name, version, sources, platform); end

  def add_dependency(dependency); end
  def install(options = T.unsafe(nil)); end
  def pretty_print(q); end
  def sources; end
  def spec; end
end

module Gem::Resolver::Molinillo; end

class Gem::Resolver::Molinillo::CircularDependencyError < ::Gem::Resolver::Molinillo::ResolverError
  def initialize(vertices); end

  def dependencies; end
end

module Gem::Resolver::Molinillo::Delegates; end

module Gem::Resolver::Molinillo::Delegates::ResolutionState
  def activated; end
  def conflicts; end
  def depth; end
  def name; end
  def possibilities; end
  def requirement; end
  def requirements; end
  def unused_unwind_options; end
end

module Gem::Resolver::Molinillo::Delegates::SpecificationProvider
  def allow_missing?(dependency); end
  def dependencies_equal?(dependencies, other_dependencies); end
  def dependencies_for(specification); end
  def name_for(dependency); end
  def name_for_explicit_dependency_source; end
  def name_for_locking_dependency_source; end
  def requirement_satisfied_by?(requirement, activated, spec); end
  def search_for(dependency); end
  def sort_dependencies(dependencies, activated, conflicts); end

  private

  def with_no_such_dependency_error_handling; end
end

class Gem::Resolver::Molinillo::DependencyGraph
  include ::Enumerable
  include ::Gem::TSort

  def initialize; end

  def ==(other); end
  def add_child_vertex(name, payload, parent_names, requirement); end
  def add_edge(origin, destination, requirement); end
  def add_vertex(name, payload, root = T.unsafe(nil)); end
  def delete_edge(edge); end
  def detach_vertex_named(name); end
  def each; end
  def inspect; end
  def log; end
  def rewind_to(tag); end
  def root_vertex_named(name); end
  def set_payload(name, payload); end
  def tag(tag); end
  def to_dot(options = T.unsafe(nil)); end
  def tsort_each_child(vertex, &block); end
  def tsort_each_node; end
  def vertex_named(name); end
  def vertices; end

  private

  def add_edge_no_circular(origin, destination, requirement); end
  def initialize_copy(other); end
  def path(from, to); end

  class << self
    def tsort(vertices); end
  end
end

class Gem::Resolver::Molinillo::DependencyGraph::Action
  def down(graph); end
  def next; end
  def next=(_arg0); end
  def previous; end
  def previous=(_arg0); end
  def up(graph); end

  class << self
    def action_name; end
  end
end

class Gem::Resolver::Molinillo::DependencyGraph::AddEdgeNoCircular < ::Gem::Resolver::Molinillo::DependencyGraph::Action
  def initialize(origin, destination, requirement); end

  def destination; end
  def down(graph); end
  def make_edge(graph); end
  def origin; end
  def requirement; end
  def up(graph); end

  private

  def delete_first(array, item); end

  class << self
    def action_name; end
  end
end

class Gem::Resolver::Molinillo::DependencyGraph::AddVertex < ::Gem::Resolver::Molinillo::DependencyGraph::Action
  def initialize(name, payload, root); end

  def down(graph); end
  def name; end
  def payload; end
  def root; end
  def up(graph); end

  class << self
    def action_name; end
  end
end

class Gem::Resolver::Molinillo::DependencyGraph::DeleteEdge < ::Gem::Resolver::Molinillo::DependencyGraph::Action
  def initialize(origin_name, destination_name, requirement); end

  def destination_name; end
  def down(graph); end
  def make_edge(graph); end
  def origin_name; end
  def requirement; end
  def up(graph); end

  class << self
    def action_name; end
  end
end

class Gem::Resolver::Molinillo::DependencyGraph::DetachVertexNamed < ::Gem::Resolver::Molinillo::DependencyGraph::Action
  def initialize(name); end

  def down(graph); end
  def name; end
  def up(graph); end

  class << self
    def action_name; end
  end
end

class Gem::Resolver::Molinillo::DependencyGraph::Edge < ::Struct
  def destination; end
  def destination=(_); end
  def origin; end
  def origin=(_); end
  def requirement; end
  def requirement=(_); end

  class << self
    def [](*_arg0); end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

class Gem::Resolver::Molinillo::DependencyGraph::Log
  extend ::Enumerable

  def initialize; end

  def add_edge_no_circular(graph, origin, destination, requirement); end
  def add_vertex(graph, name, payload, root); end
  def delete_edge(graph, origin_name, destination_name, requirement); end
  def detach_vertex_named(graph, name); end
  def each; end
  def pop!(graph); end
  def reverse_each; end
  def rewind_to(graph, tag); end
  def set_payload(graph, name, payload); end
  def tag(graph, tag); end

  private

  def push_action(graph, action); end
end

class Gem::Resolver::Molinillo::DependencyGraph::SetPayload < ::Gem::Resolver::Molinillo::DependencyGraph::Action
  def initialize(name, payload); end

  def down(graph); end
  def name; end
  def payload; end
  def up(graph); end

  class << self
    def action_name; end
  end
end

class Gem::Resolver::Molinillo::DependencyGraph::Tag < ::Gem::Resolver::Molinillo::DependencyGraph::Action
  def initialize(tag); end

  def down(graph); end
  def tag; end
  def up(graph); end

  class << self
    def action_name; end
  end
end

class Gem::Resolver::Molinillo::DependencyGraph::Vertex
  def initialize(name, payload); end

  def ==(other); end
  def ancestor?(other); end
  def descendent?(other); end
  def eql?(other); end
  def explicit_requirements; end
  def hash; end
  def incoming_edges; end
  def incoming_edges=(_arg0); end
  def inspect; end
  def is_reachable_from?(other); end
  def name; end
  def name=(_arg0); end
  def outgoing_edges; end
  def outgoing_edges=(_arg0); end
  def path_to?(other); end
  def payload; end
  def payload=(_arg0); end
  def predecessors; end
  def recursive_predecessors; end
  def recursive_successors; end
  def requirements; end
  def root; end
  def root=(_arg0); end
  def root?; end
  def shallow_eql?(other); end
  def successors; end

  protected

  def _path_to?(other, visited = T.unsafe(nil)); end
  def _recursive_predecessors(vertices = T.unsafe(nil)); end
  def _recursive_successors(vertices = T.unsafe(nil)); end

  private

  def new_vertex_set; end
end

class Gem::Resolver::Molinillo::DependencyState < ::Gem::Resolver::Molinillo::ResolutionState
  def pop_possibility_state; end
end

class Gem::Resolver::Molinillo::NoSuchDependencyError < ::Gem::Resolver::Molinillo::ResolverError
  def initialize(dependency, required_by = T.unsafe(nil)); end

  def dependency; end
  def dependency=(_arg0); end
  def message; end
  def required_by; end
  def required_by=(_arg0); end
end

class Gem::Resolver::Molinillo::PossibilityState < ::Gem::Resolver::Molinillo::ResolutionState; end

class Gem::Resolver::Molinillo::ResolutionState < ::Struct
  def activated; end
  def activated=(_); end
  def conflicts; end
  def conflicts=(_); end
  def depth; end
  def depth=(_); end
  def name; end
  def name=(_); end
  def possibilities; end
  def possibilities=(_); end
  def requirement; end
  def requirement=(_); end
  def requirements; end
  def requirements=(_); end
  def unused_unwind_options; end
  def unused_unwind_options=(_); end

  class << self
    def [](*_arg0); end
    def empty; end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

class Gem::Resolver::Molinillo::Resolver
  def initialize(specification_provider, resolver_ui); end

  def resolve(requested, base = T.unsafe(nil)); end
  def resolver_ui; end
  def specification_provider; end
end

class Gem::Resolver::Molinillo::Resolver::Resolution
  include ::Gem::Resolver::Molinillo::Delegates::ResolutionState
  include ::Gem::Resolver::Molinillo::Delegates::SpecificationProvider

  def initialize(specification_provider, resolver_ui, requested, base); end

  def base; end
  def iteration_rate=(_arg0); end
  def original_requested; end
  def resolve; end
  def resolver_ui; end
  def specification_provider; end
  def started_at=(_arg0); end
  def states=(_arg0); end

  private

  def activate_new_spec; end
  def attempt_to_activate; end
  def attempt_to_filter_existing_spec(vertex); end
  def binding_requirement_in_set?(requirement, possible_binding_requirements, possibilities); end
  def binding_requirements_for_conflict(conflict); end
  def build_details_for_unwind; end
  def conflict_fixing_possibilities?(state, binding_requirements); end
  def create_conflict(underlying_error = T.unsafe(nil)); end
  def debug(depth = T.unsafe(nil), &block); end
  def end_resolution; end
  def filter_possibilities_after_unwind(unwind_details); end
  def filter_possibilities_for_parent_unwind(unwind_details); end
  def filter_possibilities_for_primary_unwind(unwind_details); end
  def filtered_possibility_set(vertex); end
  def find_state_for(requirement); end
  def group_possibilities(possibilities); end
  def handle_missing_or_push_dependency_state(state); end
  def indicate_progress; end
  def iteration_rate; end
  def locked_requirement_named(requirement_name); end
  def locked_requirement_possibility_set(requirement, activated = T.unsafe(nil)); end
  def parent_of(requirement); end
  def possibilities_for_requirement(requirement, activated = T.unsafe(nil)); end
  def possibility; end
  def possibility_satisfies_requirements?(possibility, requirements); end
  def process_topmost_state; end
  def push_initial_state; end
  def push_state_for_requirements(new_requirements, requires_sort = T.unsafe(nil), new_activated = T.unsafe(nil)); end
  def raise_error_unless_state(conflicts); end
  def require_nested_dependencies_for(possibility_set); end
  def requirement_for_existing_name(name); end
  def requirement_tree_for(requirement); end
  def requirement_trees; end
  def resolve_activated_specs; end
  def start_resolution; end
  def started_at; end
  def state; end
  def states; end
  def unwind_for_conflict; end
  def unwind_options_for_requirements(binding_requirements); end
end

class Gem::Resolver::Molinillo::Resolver::Resolution::Conflict < ::Struct
  def activated_by_name; end
  def activated_by_name=(_); end
  def existing; end
  def existing=(_); end
  def locked_requirement; end
  def locked_requirement=(_); end
  def possibility; end
  def possibility_set; end
  def possibility_set=(_); end
  def requirement; end
  def requirement=(_); end
  def requirement_trees; end
  def requirement_trees=(_); end
  def requirements; end
  def requirements=(_); end
  def underlying_error; end
  def underlying_error=(_); end

  class << self
    def [](*_arg0); end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

class Gem::Resolver::Molinillo::Resolver::Resolution::PossibilitySet < ::Struct
  def dependencies; end
  def dependencies=(_); end
  def latest_version; end
  def possibilities; end
  def possibilities=(_); end
  def to_s; end

  class << self
    def [](*_arg0); end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

class Gem::Resolver::Molinillo::Resolver::Resolution::UnwindDetails < ::Struct
  include ::Comparable

  def <=>(other); end
  def all_requirements; end
  def conflicting_requirements; end
  def conflicting_requirements=(_); end
  def requirement_tree; end
  def requirement_tree=(_); end
  def requirement_trees; end
  def requirement_trees=(_); end
  def requirements_unwound_to_instead; end
  def requirements_unwound_to_instead=(_); end
  def reversed_requirement_tree_index; end
  def state_index; end
  def state_index=(_); end
  def state_requirement; end
  def state_requirement=(_); end
  def sub_dependencies_to_avoid; end
  def unwinding_to_primary_requirement?; end

  class << self
    def [](*_arg0); end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

class Gem::Resolver::Molinillo::ResolverError < ::StandardError; end

module Gem::Resolver::Molinillo::SpecificationProvider
  def allow_missing?(dependency); end
  def dependencies_equal?(dependencies, other_dependencies); end
  def dependencies_for(specification); end
  def name_for(dependency); end
  def name_for_explicit_dependency_source; end
  def name_for_locking_dependency_source; end
  def requirement_satisfied_by?(requirement, activated, spec); end
  def search_for(dependency); end
  def sort_dependencies(dependencies, activated, conflicts); end
end

module Gem::Resolver::Molinillo::UI
  def after_resolution; end
  def before_resolution; end
  def debug(depth = T.unsafe(nil)); end
  def debug?; end
  def indicate_progress; end
  def output; end
  def progress_rate; end
end

class Gem::Resolver::Molinillo::VersionConflict < ::Gem::Resolver::Molinillo::ResolverError
  include ::Gem::Resolver::Molinillo::Delegates::SpecificationProvider

  def initialize(conflicts, specification_provider); end

  def conflicts; end
  def message_with_trees(opts = T.unsafe(nil)); end
  def specification_provider; end
end

class Gem::Resolver::RequirementList
  include ::Enumerable

  def initialize; end

  def add(req); end
  def each; end
  def empty?; end
  def next5; end
  def remove; end
  def size; end

  private

  def initialize_copy(other); end
end

class Gem::Resolver::Set
  def initialize; end

  def errors; end
  def errors=(_arg0); end
  def find_all(req); end
  def prefetch(reqs); end
  def prerelease; end
  def prerelease=(_arg0); end
  def remote; end
  def remote=(_arg0); end
  def remote?; end
end

class Gem::Resolver::SourceSet < ::Gem::Resolver::Set
  def initialize; end

  def add_source_gem(name, source); end
  def find_all(req); end
  def prefetch(reqs); end

  private

  def get_set(name); end
end

class Gem::Resolver::SpecSpecification < ::Gem::Resolver::Specification
  def initialize(set, spec, source = T.unsafe(nil)); end

  def dependencies; end
  def full_name; end
  def name; end
  def platform; end
  def required_ruby_version; end
  def required_rubygems_version; end
  def version; end
end

class Gem::Resolver::Specification
  def initialize; end

  def dependencies; end
  def download(options); end
  def fetch_development_dependencies; end
  def full_name; end
  def install(options = T.unsafe(nil)); end
  def installable_platform?; end
  def local?; end
  def name; end
  def platform; end
  def required_ruby_version; end
  def required_rubygems_version; end
  def set; end
  def source; end
  def spec; end
  def version; end
end

class Gem::Resolver::Stats
  def initialize; end

  def backtracking!; end
  def display; end
  def iteration!; end
  def record_depth(stack); end
  def record_requirements(reqs); end
  def requirement!; end
end

class Gem::Resolver::VendorSet < ::Gem::Resolver::Set
  def initialize; end

  def add_vendor_gem(name, directory); end
  def find_all(req); end
  def load_spec(name, version, platform, source); end
  def pretty_print(q); end
  def specs; end
end

class Gem::Resolver::VendorSpecification < ::Gem::Resolver::SpecSpecification
  def ==(other); end
  def install(options = T.unsafe(nil)); end
end

class Gem::RubyVersionMismatch < ::Gem::Exception; end

class Gem::RuntimeRequirementNotMetError < ::Gem::InstallError
  def message; end
  def suggestion; end
  def suggestion=(_arg0); end
end

class Gem::SilentUI < ::Gem::StreamUI
  def initialize; end

  def close; end
  def download_reporter(*args); end
  def progress_reporter(*args); end
end

class Gem::SilentUI::NullIO
  def flush; end
  def gets(*args); end
  def print(*args); end
  def puts(*args); end
  def tty?; end
end

class Gem::Source
  include ::Comparable
  include ::Gem::Text

  def initialize(uri); end

  def <=>(other); end
  def ==(other); end
  def cache_dir(uri); end
  def dependency_resolver_set; end
  def download(spec, dir = T.unsafe(nil)); end
  def eql?(other); end
  def fetch_spec(name_tuple); end
  def hash; end
  def load_specs(type); end
  def pretty_print(q); end
  def typo_squatting?(host, distance_threshold = T.unsafe(nil)); end
  def update_cache?; end
  def uri; end

  private

  def enforce_trailing_slash(uri); end
end

class Gem::Source::Git < ::Gem::Source
  def initialize(name, repository, reference, submodules = T.unsafe(nil)); end

  def <=>(other); end
  def ==(other); end
  def base_dir; end
  def cache; end
  def checkout; end
  def dir_shortref; end
  def download(full_spec, path); end
  def install_dir; end
  def name; end
  def need_submodules; end
  def pretty_print(q); end
  def reference; end
  def remote; end
  def remote=(_arg0); end
  def repo_cache_dir; end
  def repository; end
  def rev_parse; end
  def root_dir; end
  def root_dir=(_arg0); end
  def specs; end
  def uri_hash; end
end

class Gem::Source::Installed < ::Gem::Source
  def initialize; end

  def <=>(other); end
  def download(spec, path); end
  def pretty_print(q); end
end

class Gem::Source::Local < ::Gem::Source
  def initialize; end

  def <=>(other); end
  def download(spec, cache_dir = T.unsafe(nil)); end
  def fetch_spec(name); end
  def find_gem(gem_name, version = T.unsafe(nil), prerelease = T.unsafe(nil)); end
  def inspect; end
  def load_specs(type); end
  def pretty_print(q); end
end

class Gem::Source::Lock < ::Gem::Source
  def initialize(source); end

  def <=>(other); end
  def ==(other); end
  def fetch_spec(name_tuple); end
  def hash; end
  def uri; end
  def wrapped; end
end

class Gem::Source::SpecificFile < ::Gem::Source
  def initialize(file); end

  def <=>(other); end
  def download(spec, dir = T.unsafe(nil)); end
  def fetch_spec(name); end
  def load_specs(*a); end
  def path; end
  def pretty_print(q); end
  def spec; end
end

class Gem::Source::Vendor < ::Gem::Source::Installed
  def initialize(path); end

  def <=>(other); end
end

class Gem::SourceFetchProblem < ::Gem::ErrorReason
  def initialize(source, error); end

  def error; end
  def exception; end
  def source; end
  def wordy; end
end

class Gem::SourceIndex
  def initialize(specifications = T.unsafe(nil)); end

  def ==(other); end
  def add_spec(gem_spec, name = T.unsafe(nil)); end
  def add_specs(*gem_specs); end
  def all_gems; end
  def dump; end
  def each(&block); end
  def find_name(gem_name, requirement = T.unsafe(nil)); end
  def gem_signature(gem_full_name); end
  def gems; end
  def index_signature; end
  def latest_specs(include_prerelease = T.unsafe(nil)); end
  def length; end
  def load_gems_in(*spec_dirs); end
  def outdated; end
  def prerelease_gems; end
  def prerelease_specs; end
  def refresh!; end
  def released_gems; end
  def released_specs; end
  def remove_spec(full_name); end
  def search(gem_pattern, platform_only = T.unsafe(nil)); end
  def size; end
  def spec_dirs; end
  def spec_dirs=(_arg0); end
  def specification(full_name); end

  class << self
    def from_gems_in(*spec_dirs); end
    def from_installed_gems(*deprecated); end
    def installed_spec_directories; end
    def load_specification(file_name); end
  end
end

class Gem::SourceList
  def initialize; end

  def <<(obj); end
  def ==(other); end
  def clear; end
  def delete(source); end
  def each; end
  def each_source(&b); end
  def empty?; end
  def first; end
  def include?(other); end
  def replace(other); end
  def sources; end
  def to_a; end
  def to_ary; end

  private

  def initialize_copy(other); end

  class << self
    def from(ary); end
  end
end

class Gem::SpecFetcher
  include ::Gem::DefaultUserInteraction

  def initialize(sources = T.unsafe(nil)); end

  def available_specs(type); end
  def detect(type = T.unsafe(nil)); end
  def latest_specs; end
  def prerelease_specs; end
  def search_for_dependency(dependency, matching_platform = T.unsafe(nil)); end
  def sources; end
  def spec_for_dependency(dependency, matching_platform = T.unsafe(nil)); end
  def specs; end
  def suggest_gems_from_name(gem_name, type = T.unsafe(nil), num_results = T.unsafe(nil)); end
  def tuples_for(source, type, gracefully_ignore = T.unsafe(nil)); end

  class << self
    def fetcher; end
    def fetcher=(fetcher); end
  end
end

class Gem::SpecificGemNotFoundException < ::Gem::GemNotFoundException
  def initialize(name, version, errors = T.unsafe(nil)); end

  def errors; end
  def name; end
  def version; end
end

class Gem::Specification < ::Gem::BasicSpecification
  include ::Gem::Specification::YamlBackfiller
  include ::Bundler::MatchMetadata
  include ::Bundler::GemHelpers
  include ::Bundler::MatchPlatform
  extend ::Gem::Deprecate
  extend ::Enumerable

  def initialize(name = T.unsafe(nil), version = T.unsafe(nil)); end

  def <=>(other); end
  def ==(other); end
  def _deprecated_default_executable; end
  def _deprecated_default_executable=(_arg0); end
  def _deprecated_has_rdoc; end
  def _deprecated_has_rdoc=(ignored); end
  def _deprecated_has_rdoc?(*args, **_arg1, &block); end
  def _deprecated_validate_dependencies; end
  def _deprecated_validate_metadata; end
  def _deprecated_validate_permissions; end
  def _dump(limit); end
  def abbreviate; end
  def activate; end
  def activate_dependencies; end
  def activated; end
  def activated=(_arg0); end
  def activated?; end
  def add_bindir(executables); end
  def add_dependency(gem, *requirements); end
  def add_development_dependency(gem, *requirements); end
  def add_runtime_dependency(gem, *requirements); end
  def add_self_to_load_path; end
  def author; end
  def author=(o); end
  def authors; end
  def authors=(value); end
  def autorequire; end
  def autorequire=(_arg0); end
  def base_dir; end
  def bin_dir; end
  def bin_file(name); end
  def bindir; end
  def bindir=(_arg0); end
  def build_args; end
  def build_extensions; end
  def build_info_dir; end
  def build_info_file; end
  def cache_dir; end
  def cache_file; end
  def cert_chain; end
  def cert_chain=(_arg0); end
  def conficts_when_loaded_with?(list_of_specs); end
  def conflicts; end
  def date; end
  def date=(date); end
  def default_executable(*args, **_arg1, &block); end
  def default_executable=(*args, **_arg1, &block); end
  def default_value(name); end
  def deleted_gem?; end
  def dependencies; end
  def dependent_gems(check_dev = T.unsafe(nil)); end
  def dependent_specs; end
  def description; end
  def description=(str); end
  def development_dependencies; end
  def doc_dir(type = T.unsafe(nil)); end
  def email; end
  def email=(_arg0); end
  def encode_with(coder); end
  def eql?(other); end
  def executable; end
  def executable=(o); end
  def executables; end
  def executables=(value); end
  def extension_dir; end
  def extensions; end
  def extensions=(extensions); end
  def extra_rdoc_files; end
  def extra_rdoc_files=(files); end
  def file_name; end
  def files; end
  def files=(files); end
  def flatten_require_paths; end
  def for_cache; end
  def full_gem_path; end
  def full_name; end
  def gem_dir; end
  def gems_dir; end
  def git_version; end
  def groups; end
  def has_conflicts?; end
  def has_rdoc(*args, **_arg1, &block); end
  def has_rdoc=(*args, **_arg1, &block); end
  def has_rdoc?(*args, **_arg1, &block); end
  def has_test_suite?; end
  def has_unit_tests?; end
  def hash; end
  def homepage; end
  def homepage=(_arg0); end
  def init_with(coder); end
  def inspect; end
  def installed_by_version; end
  def installed_by_version=(version); end
  def internal_init; end
  def keep_only_files_and_directories; end
  def lib_files; end
  def license; end
  def license=(o); end
  def licenses; end
  def licenses=(licenses); end
  def load_paths; end
  def loaded_from; end
  def location; end
  def location=(_arg0); end
  def mark_version; end
  def metadata; end
  def metadata=(_arg0); end
  def method_missing(sym, *a, &b); end
  def missing_extensions?; end
  def name; end
  def name=(_arg0); end
  def name_tuple; end
  def nondevelopment_dependencies; end
  def normalize; end
  def original_name; end
  def original_platform; end
  def original_platform=(_arg0); end
  def platform; end
  def platform=(platform); end
  def post_install_message; end
  def post_install_message=(_arg0); end
  def pretty_print(q); end
  def raise_if_conflicts; end
  def raw_require_paths; end
  def rdoc_options; end
  def rdoc_options=(options); end
  def relative_loaded_from; end
  def relative_loaded_from=(_arg0); end
  def remote; end
  def remote=(_arg0); end
  def removed_method_calls; end
  def require_path; end
  def require_path=(path); end
  def require_paths=(val); end
  def required_ruby_version; end
  def required_ruby_version=(req); end
  def required_rubygems_version; end
  def required_rubygems_version=(req); end
  def requirements; end
  def requirements=(req); end
  def reset_nil_attributes_to_default; end
  def rg_extension_dir; end
  def rg_full_gem_path; end
  def rg_loaded_from; end
  def ri_dir; end
  def rubygems_version; end
  def rubygems_version=(_arg0); end
  def runtime_dependencies; end
  def sanitize; end
  def sanitize_string(string); end
  def satisfies_requirement?(dependency); end
  def signing_key; end
  def signing_key=(_arg0); end
  def sort_obj; end
  def source; end
  def source=(_arg0); end
  def spec_dir; end
  def spec_file; end
  def spec_name; end
  def specification_version; end
  def specification_version=(_arg0); end
  def stubbed?; end
  def summary; end
  def summary=(str); end
  def test_file; end
  def test_file=(file); end
  def test_files; end
  def test_files=(files); end
  def to_gemfile(path = T.unsafe(nil)); end
  def to_ruby; end
  def to_ruby_for_cache; end
  def to_s; end
  def to_spec; end
  def to_yaml(opts = T.unsafe(nil)); end
  def traverse(trail = T.unsafe(nil), visited = T.unsafe(nil), &block); end
  def validate(packaging = T.unsafe(nil), strict = T.unsafe(nil)); end
  def validate_dependencies(*args, **_arg1, &block); end
  def validate_metadata(*args, **_arg1, &block); end
  def validate_permissions(*args, **_arg1, &block); end
  def version; end
  def version=(version); end
  def yaml_initialize(tag, vals); end

  private

  def add_dependency_with_type(dependency, type, requirements); end
  def check_version_conflict(other); end
  def dependencies_to_gemfile(dependencies, group = T.unsafe(nil)); end
  def find_all_satisfiers(dep); end
  def initialize_copy(other_spec); end
  def invalidate_memoized_attributes; end
  def respond_to_missing?(m, include_private = T.unsafe(nil)); end
  def ruby_code(obj); end
  def same_attributes?(spec); end
  def set_nil_attributes_to_nil; end
  def set_not_nil_attributes_to_default_values; end

  class << self
    def _all; end
    def _latest_specs(specs, prerelease = T.unsafe(nil)); end
    def _load(str); end
    def _resort!(specs); end
    def add_spec(spec); end
    def all; end
    def all=(specs); end
    def all_names; end
    def array_attributes; end
    def attribute_names; end
    def default_stubs(pattern = T.unsafe(nil)); end
    def dirs; end
    def dirs=(dirs); end
    def each; end
    def each_gemspec(dirs); end
    def each_spec(dirs); end
    def find_active_stub_by_path(path); end
    def find_all_by_full_name(full_name); end
    def find_all_by_name(name, *requirements); end
    def find_by_name(name, *requirements); end
    def find_by_path(path); end
    def find_in_unresolved(path); end
    def find_in_unresolved_tree(path); end
    def find_inactive_by_path(path); end
    def from_yaml(input); end
    def latest_spec_for(name); end
    def latest_specs(prerelease = T.unsafe(nil)); end
    def load(file); end
    def load_defaults; end
    def non_nil_attributes; end
    def normalize_yaml_input(input); end
    def outdated; end
    def outdated_and_latest_version; end
    def remove_spec(spec); end
    def required_attribute?(name); end
    def required_attributes; end
    def reset; end
    def stubs; end
    def stubs_for(name); end
    def stubs_for_pattern(pattern, match_platform = T.unsafe(nil)); end
    def unresolved_deps; end

    private

    def clear_load_cache; end
    def clear_specs; end
    def gemspec_stubs_in(dir, pattern); end
    def installed_stubs(dirs, pattern); end
    def map_stubs(dirs, pattern); end
    def unresolved_specs; end
  end
end

module Gem::Specification::YamlBackfiller
  def to_yaml(opts = T.unsafe(nil)); end
end

class Gem::SpecificationPolicy
  include ::Gem::Text
  include ::Gem::DefaultUserInteraction
  include ::Gem::UserInteraction

  def initialize(specification); end

  def packaging; end
  def packaging=(_arg0); end
  def validate(strict = T.unsafe(nil)); end
  def validate_dependencies; end
  def validate_duplicate_dependencies; end
  def validate_metadata; end
  def validate_optional(strict); end
  def validate_permissions; end
  def validate_required!; end

  private

  def error(statement); end
  def help_text; end
  def validate_array_attribute(field); end
  def validate_array_attributes; end
  def validate_attribute_present(attribute); end
  def validate_authors_field; end
  def validate_extensions; end
  def validate_lazy_metadata; end
  def validate_licenses; end
  def validate_licenses_length; end
  def validate_name; end
  def validate_nil_attributes; end
  def validate_non_files; end
  def validate_platform; end
  def validate_rake_extensions(builder); end
  def validate_removed_attributes; end
  def validate_require_paths; end
  def validate_required_attributes; end
  def validate_rubygems_version; end
  def validate_rust_extensions(builder); end
  def validate_self_inclusion_in_files_list; end
  def validate_shebang_line_in(executable); end
  def validate_specification_version; end
  def validate_values; end
  def warning(statement); end
end

class Gem::StreamUI
  extend ::Gem::Deprecate

  def initialize(in_stream, out_stream, err_stream = T.unsafe(nil), usetty = T.unsafe(nil)); end

  def _gets_noecho; end
  def alert(statement, question = T.unsafe(nil)); end
  def alert_error(statement, question = T.unsafe(nil)); end
  def alert_warning(statement, question = T.unsafe(nil)); end
  def ask(question); end
  def ask_for_password(question); end
  def ask_yes_no(question, default = T.unsafe(nil)); end
  def backtrace(exception); end
  def choose_from_list(question, list); end
  def close; end
  def download_reporter(*args); end
  def errs; end
  def ins; end
  def outs; end
  def progress_reporter(*args); end
  def require_io_console; end
  def say(statement = T.unsafe(nil)); end
  def terminate_interaction(status = T.unsafe(nil)); end
  def tty?; end
end

class Gem::StreamUI::SilentDownloadReporter
  def initialize(out_stream, *args); end

  def done; end
  def fetch(filename, filesize); end
  def update(current); end
end

class Gem::StreamUI::SilentProgressReporter
  def initialize(out_stream, size, initial_message, terminal_message = T.unsafe(nil)); end

  def count; end
  def done; end
  def updated(message); end
end

class Gem::StreamUI::SimpleProgressReporter
  include ::Gem::Text
  include ::Gem::DefaultUserInteraction

  def initialize(out_stream, size, initial_message, terminal_message = T.unsafe(nil)); end

  def count; end
  def done; end
  def updated(message); end
end

class Gem::StreamUI::ThreadedDownloadReporter
  def initialize(out_stream, *args); end

  def done; end
  def fetch(file_name, *args); end
  def file_name; end
  def update(bytes); end

  private

  def locked_puts(message); end
end

class Gem::StreamUI::VerboseProgressReporter
  include ::Gem::Text
  include ::Gem::DefaultUserInteraction

  def initialize(out_stream, size, initial_message, terminal_message = T.unsafe(nil)); end

  def count; end
  def done; end
  def updated(message); end
end

class Gem::StubSpecification < ::Gem::BasicSpecification
  def initialize(filename, base_dir, gems_dir, default_gem); end

  def activated?; end
  def base_dir; end
  def build_extensions; end
  def default_gem?; end
  def extensions; end
  def full_name; end
  def gems_dir; end
  def missing_extensions?; end
  def name; end
  def platform; end
  def raw_require_paths; end
  def stubbed?; end
  def to_spec; end
  def valid?; end
  def version; end

  private

  def data; end

  class << self
    def default_gemspec_stub(filename, base_dir, gems_dir); end
    def gemspec_stub(filename, base_dir, gems_dir); end
  end
end

class Gem::StubSpecification::StubLine
  def initialize(data, extensions); end

  def extensions; end
  def full_name; end
  def name; end
  def platform; end
  def require_paths; end
  def version; end
end

class Gem::SystemExitException < ::SystemExit
  def initialize(exit_code); end

  def exit_code; end
end

module Gem::TSort
  def each_strongly_connected_component(&block); end
  def each_strongly_connected_component_from(node, id_map = T.unsafe(nil), stack = T.unsafe(nil), &block); end
  def strongly_connected_components; end
  def tsort; end
  def tsort_each(&block); end
  def tsort_each_child(node); end
  def tsort_each_node; end

  class << self
    def each_strongly_connected_component(each_node, each_child); end
    def each_strongly_connected_component_from(node, each_child, id_map = T.unsafe(nil), stack = T.unsafe(nil)); end
    def strongly_connected_components(each_node, each_child); end
    def tsort(each_node, each_child); end
    def tsort_each(each_node, each_child); end
  end
end

class Gem::TSort::Cyclic < ::StandardError; end

module Gem::Text
  def clean_text(text); end
  def format_text(text, wrap, indent = T.unsafe(nil)); end
  def levenshtein_distance(str1, str2); end
  def min3(a, b, c); end
  def truncate_text(text, description, max_length = T.unsafe(nil)); end
end

class Gem::UninstallError < ::Gem::Exception
  def spec; end
  def spec=(_arg0); end
end

class Gem::UnknownCommandError < ::Gem::Exception
  def initialize(unknown_command); end

  def unknown_command; end

  class << self
    def attach_correctable; end
  end
end

class Gem::UnknownCommandSpellChecker
  def initialize(error); end

  def corrections; end
  def error; end

  private

  def spell_checker; end
end

class Gem::UnsatisfiableDependencyError < ::Gem::DependencyError
  def initialize(dep, platform_mismatch = T.unsafe(nil)); end

  def dependency; end
  def errors; end
  def errors=(_arg0); end
  def name; end
  def version; end
end

module Gem::UserInteraction
  include ::Gem::Text
  include ::Gem::DefaultUserInteraction

  def alert(statement, question = T.unsafe(nil)); end
  def alert_error(statement, question = T.unsafe(nil)); end
  def alert_warning(statement, question = T.unsafe(nil)); end
  def ask(question); end
  def ask_for_password(prompt); end
  def ask_yes_no(question, default = T.unsafe(nil)); end
  def choose_from_list(question, list); end
  def say(statement = T.unsafe(nil)); end
  def terminate_interaction(exit_code = T.unsafe(nil)); end
  def verbose(msg = T.unsafe(nil)); end
end

module Gem::Util
  class << self
    def _deprecated_silent_system(*command); end
    def correct_for_windows_path(path); end
    def glob_files_in_dir(glob, base_path); end
    def gunzip(data); end
    def gzip(data); end
    def inflate(data); end
    def popen(*command); end
    def silent_system(*args, **_arg1, &block); end
    def traverse_parents(directory, &block); end
  end
end

class Gem::VerificationError < ::Gem::Exception; end

class Gem::Version
  include ::Comparable

  def initialize(version); end

  def <=>(other); end
  def approximate_recommendation; end
  def bump; end
  def canonical_segments; end
  def encode_with(coder); end
  def eql?(other); end
  def freeze; end
  def hash; end
  def init_with(coder); end
  def inspect; end
  def marshal_dump; end
  def marshal_load(array); end
  def prerelease?; end
  def pretty_print(q); end
  def release; end
  def segments; end
  def to_s; end
  def to_yaml_properties; end
  def version; end
  def yaml_initialize(tag, map); end

  protected

  def _segments; end
  def _split_segments; end
  def _version; end

  class << self
    def correct?(version); end
    def create(input); end
    def new(version); end

    private

    def nil_versions_are_discouraged!; end
  end
end

class Hash
  include ::Enumerable

  def initialize(*_arg0); end

  def <(_arg0); end
  def <=(_arg0); end
  def ==(_arg0); end
  def >(_arg0); end
  def >=(_arg0); end
  def [](_arg0); end
  def []=(_arg0, _arg1); end
  def any?(*_arg0); end
  def assoc(_arg0); end
  def clear; end
  def compact; end
  def compact!; end
  def compare_by_identity; end
  def compare_by_identity?; end
  def deconstruct_keys(_arg0); end
  def default(*_arg0); end
  def default=(_arg0); end
  def default_proc; end
  def default_proc=(_arg0); end
  def delete(_arg0); end
  def delete_if; end
  def dig(*_arg0); end
  def each; end
  def each_key; end
  def each_pair; end
  def each_value; end
  def empty?; end
  def eql?(_arg0); end
  def except(*_arg0); end
  def fetch(*_arg0); end
  def fetch_values(*_arg0); end
  def filter; end
  def filter!; end
  def flatten(*_arg0); end
  def has_key?(_arg0); end
  def has_value?(_arg0); end
  def hash; end
  def include?(_arg0); end
  def inspect; end
  def invert; end
  def keep_if; end
  def key(_arg0); end
  def key?(_arg0); end
  def keys; end
  def length; end
  def member?(_arg0); end
  def merge(*_arg0); end
  def merge!(*_arg0); end
  def pretty_print(q); end
  def pretty_print_cycle(q); end
  def rassoc(_arg0); end
  def rehash; end
  def reject; end
  def reject!; end
  def replace(_arg0); end
  def select; end
  def select!; end
  def shift; end
  def size; end
  def slice(*_arg0); end
  def store(_arg0, _arg1); end
  def to_a; end
  def to_h; end
  def to_hash; end
  def to_proc; end
  def to_s; end
  def transform_keys(*_arg0); end
  def transform_keys!(*_arg0); end
  def transform_values; end
  def transform_values!; end
  def update(*_arg0); end
  def value?(_arg0); end
  def values; end
  def values_at(*_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def [](*_arg0); end
    def ruby2_keywords_hash(_arg0); end
    def ruby2_keywords_hash?(_arg0); end
    def try_convert(_arg0); end
  end
end

class IO
  include ::Enumerable
  include ::File::Constants

  def initialize(*_arg0); end

  def <<(_arg0); end
  def advise(*_arg0); end
  def autoclose=(_arg0); end
  def autoclose?; end
  def binmode; end
  def binmode?; end
  def close; end
  def close_on_exec=(_arg0); end
  def close_on_exec?; end
  def close_read; end
  def close_write; end
  def closed?; end
  def each(*_arg0); end
  def each_byte; end
  def each_char; end
  def each_codepoint; end
  def each_line(*_arg0); end
  def eof; end
  def eof?; end
  def external_encoding; end
  def fcntl(*_arg0); end
  def fdatasync; end
  def fileno; end
  def flush; end
  def fsync; end
  def getbyte; end
  def getc; end
  def gets(*_arg0); end
  def inspect; end
  def internal_encoding; end
  def ioctl(*_arg0); end
  def isatty; end
  def lineno; end
  def lineno=(_arg0); end
  def nonblock(*_arg0); end
  def nonblock=(_arg0); end
  def nonblock?; end
  def nread; end
  def path; end
  def pathconf(_arg0); end
  def pid; end
  def pos; end
  def pos=(_arg0); end
  def pread(*_arg0); end
  def print(*_arg0); end
  def printf(*_arg0); end
  def putc(_arg0); end
  def puts(*_arg0); end
  def pwrite(_arg0, _arg1); end
  def read(*_arg0); end
  def read_nonblock(len, buf = T.unsafe(nil), exception: T.unsafe(nil)); end
  def readbyte; end
  def readchar; end
  def readline(*_arg0); end
  def readlines(*_arg0); end
  def readpartial(*_arg0); end
  def ready?; end
  def reopen(*_arg0); end
  def rewind; end
  def seek(*_arg0); end
  def set_encoding(*_arg0); end
  def set_encoding_by_bom; end
  def stat; end
  def sync; end
  def sync=(_arg0); end
  def sysread(*_arg0); end
  def sysseek(*_arg0); end
  def syswrite(_arg0); end
  def tell; end
  def timeout; end
  def timeout=(_arg0); end
  def to_i; end
  def to_io; end
  def to_path; end
  def tty?; end
  def ungetbyte(_arg0); end
  def ungetc(_arg0); end
  def wait(*_arg0); end
  def wait_priority(*_arg0); end
  def wait_readable(*_arg0); end
  def wait_writable(*_arg0); end
  def write(*_arg0); end
  def write_nonblock(buf, exception: T.unsafe(nil)); end

  private

  def initialize_copy(_arg0); end

  class << self
    def binread(*_arg0); end
    def binwrite(*_arg0); end
    def copy_stream(*_arg0); end
    def for_fd(*_arg0); end
    def foreach(*_arg0); end
    def new(*_arg0); end
    def open(*_arg0); end
    def pipe(*_arg0); end
    def popen(*_arg0); end
    def read(*_arg0); end
    def readlines(*_arg0); end
    def select(*_arg0); end
    def sysopen(*_arg0); end
    def try_convert(_arg0); end
    def write(*_arg0); end
  end
end

class IO::Buffer
  include ::Comparable

  def initialize(*_arg0); end

  def &(_arg0); end
  def <=>(_arg0); end
  def ^(_arg0); end
  def and!(_arg0); end
  def clear(*_arg0); end
  def copy(*_arg0); end
  def each(*_arg0); end
  def each_byte(*_arg0); end
  def empty?; end
  def external?; end
  def free; end
  def get_string(*_arg0); end
  def get_value(_arg0, _arg1); end
  def get_values(_arg0, _arg1); end
  def hexdump; end
  def inspect; end
  def internal?; end
  def locked; end
  def locked?; end
  def mapped?; end
  def not!; end
  def null?; end
  def or!(_arg0); end
  def pread(*_arg0); end
  def pwrite(*_arg0); end
  def read(*_arg0); end
  def readonly?; end
  def resize(_arg0); end
  def set_string(*_arg0); end
  def set_value(_arg0, _arg1, _arg2); end
  def set_values(_arg0, _arg1, _arg2); end
  def shared?; end
  def size; end
  def slice(*_arg0); end
  def to_s; end
  def transfer; end
  def valid?; end
  def values(*_arg0); end
  def write(*_arg0); end
  def xor!(_arg0); end
  def |(_arg0); end
  def ~; end

  private

  def initialize_copy(_arg0); end

  class << self
    def for(_arg0); end
    def map(*_arg0); end
    def size_of(_arg0); end
  end
end

class IO::Buffer::AccessError < ::RuntimeError; end
class IO::Buffer::AllocationError < ::RuntimeError; end
IO::Buffer::BIG_ENDIAN = T.let(T.unsafe(nil), Integer)
IO::Buffer::DEFAULT_SIZE = T.let(T.unsafe(nil), Integer)
IO::Buffer::EXTERNAL = T.let(T.unsafe(nil), Integer)
IO::Buffer::HOST_ENDIAN = T.let(T.unsafe(nil), Integer)
IO::Buffer::INTERNAL = T.let(T.unsafe(nil), Integer)
class IO::Buffer::InvalidatedError < ::RuntimeError; end
IO::Buffer::LITTLE_ENDIAN = T.let(T.unsafe(nil), Integer)
IO::Buffer::LOCKED = T.let(T.unsafe(nil), Integer)
class IO::Buffer::LockedError < ::RuntimeError; end
IO::Buffer::MAPPED = T.let(T.unsafe(nil), Integer)
class IO::Buffer::MaskError < ::ArgumentError; end
IO::Buffer::NETWORK_ENDIAN = T.let(T.unsafe(nil), Integer)
IO::Buffer::PAGE_SIZE = T.let(T.unsafe(nil), Integer)
IO::Buffer::PRIVATE = T.let(T.unsafe(nil), Integer)
IO::Buffer::READONLY = T.let(T.unsafe(nil), Integer)
IO::Buffer::SHARED = T.let(T.unsafe(nil), Integer)

class IO::EAGAINWaitReadable < ::Errno::EAGAIN
  include ::IO::WaitReadable
end

class IO::EAGAINWaitWritable < ::Errno::EAGAIN
  include ::IO::WaitWritable
end

class IO::EINPROGRESSWaitReadable < ::Errno::EINPROGRESS
  include ::IO::WaitReadable
end

class IO::EINPROGRESSWaitWritable < ::Errno::EINPROGRESS
  include ::IO::WaitWritable
end

IO::EWOULDBLOCKWaitReadable = IO::EAGAINWaitReadable
IO::EWOULDBLOCKWaitWritable = IO::EAGAINWaitWritable
IO::PRIORITY = T.let(T.unsafe(nil), Integer)
IO::READABLE = T.let(T.unsafe(nil), Integer)
IO::SEEK_CUR = T.let(T.unsafe(nil), Integer)
IO::SEEK_DATA = T.let(T.unsafe(nil), Integer)
IO::SEEK_END = T.let(T.unsafe(nil), Integer)
IO::SEEK_HOLE = T.let(T.unsafe(nil), Integer)
IO::SEEK_SET = T.let(T.unsafe(nil), Integer)
class IO::TimeoutError < ::IOError; end
IO::WRITABLE = T.let(T.unsafe(nil), Integer)
module IO::WaitReadable; end
module IO::WaitWritable; end
class IOError < ::StandardError; end
class IndexError < ::StandardError; end

class Integer < ::Numeric
  def %(_arg0); end
  def &(_arg0); end
  def *(_arg0); end
  def **(_arg0); end
  def +(_arg0); end
  def -(_arg0); end
  def -@; end
  def /(_arg0); end
  def <(_arg0); end
  def <<(_arg0); end
  def <=(_arg0); end
  def <=>(_arg0); end
  def ==(_arg0); end
  def ===(_arg0); end
  def >(_arg0); end
  def >=(_arg0); end
  def >>(_arg0); end
  def [](*_arg0); end
  def ^(_arg0); end
  def abs; end
  def allbits?(_arg0); end
  def anybits?(_arg0); end
  def bit_length; end
  def ceil(*_arg0); end
  def ceildiv(other); end
  def chr(*_arg0); end
  def coerce(_arg0); end
  def denominator; end
  def digits(*_arg0); end
  def div(_arg0); end
  def divmod(_arg0); end
  def downto(_arg0); end
  def even?; end
  def fdiv(_arg0); end
  def floor(*_arg0); end
  def gcd(_arg0); end
  def gcdlcm(_arg0); end
  def inspect(*_arg0); end
  def integer?; end
  def lcm(_arg0); end
  def magnitude; end
  def modulo(_arg0); end
  def next; end
  def nobits?(_arg0); end
  def numerator; end
  def odd?; end
  def ord; end
  def pow(*_arg0); end
  def pred; end
  def rationalize(*_arg0); end
  def remainder(_arg0); end
  def round(*_arg0); end
  def size; end
  def succ; end
  def times; end
  def to_f; end
  def to_i; end
  def to_int; end
  def to_r; end
  def to_s(*_arg0); end
  def truncate(*_arg0); end
  def upto(_arg0); end
  def zero?; end
  def |(_arg0); end
  def ~; end

  class << self
    def sqrt(_arg0); end
    def try_convert(_arg0); end
  end
end

class Interrupt < ::SignalException
  def initialize(*_arg0); end
end

module Kernel
  def !~(_arg0); end
  def <=>(_arg0); end
  def ===(_arg0); end
  def class; end
  def clone(freeze: T.unsafe(nil)); end
  def define_singleton_method(*_arg0); end
  def display(*_arg0); end
  def dup; end
  def enum_for(*_arg0); end
  def eql?(_arg0); end
  def extend(*_arg0); end
  def freeze; end
  def frozen?; end
  def gem(dep, *reqs); end
  def hash; end
  def inspect; end
  def instance_of?(_arg0); end
  def instance_variable_defined?(_arg0); end
  def instance_variable_get(_arg0); end
  def instance_variable_set(_arg0, _arg1); end
  def instance_variables; end
  def is_a?(_arg0); end
  def itself; end
  def kind_of?(_arg0); end
  def method(_arg0); end
  def methods(*_arg0); end
  def nil?; end
  def object_id; end
  def pretty_inspect; end
  def private_methods(*_arg0); end
  def protected_methods(*_arg0); end
  def public_method(_arg0); end
  def public_methods(*_arg0); end
  def public_send(*_arg0); end
  def remove_instance_variable(_arg0); end
  def respond_to?(*_arg0); end
  def send(*_arg0); end
  def singleton_class; end
  def singleton_method(_arg0); end
  def singleton_methods(*_arg0); end
  def tap; end
  def then; end
  def to_enum(*_arg0); end
  def to_s; end
  def yield_self; end

  private

  def Array(_arg0); end
  def Complex(*_arg0); end
  def Float(arg, exception: T.unsafe(nil)); end
  def Hash(_arg0); end
  def Integer(*_arg0); end
  def JSON(object, *args); end
  def Pathname(_arg0); end
  def Rational(*_arg0); end
  def String(_arg0); end
  def URI(uri); end
  def __callee__; end
  def __dir__; end
  def __method__; end
  def `(_arg0); end
  def abort(*_arg0); end
  def at_exit; end
  def autoload(_arg0, _arg1); end
  def autoload?(*_arg0); end
  def binding; end
  def block_given?; end
  def caller(*_arg0); end
  def caller_locations(*_arg0); end
  def catch(*_arg0); end
  def eval(*_arg0); end
  def exec(*_arg0); end
  def exit(*_arg0); end
  def exit!(*_arg0); end
  def fail(*_arg0); end
  def fork; end
  def format(*_arg0); end
  def gem_original_require(_arg0); end
  def gets(*_arg0); end
  def global_variables; end
  def initialize_clone(*_arg0); end
  def initialize_copy(_arg0); end
  def initialize_dup(_arg0); end
  def iterator?; end
  def j(*objs); end
  def jj(*objs); end
  def lambda; end
  def load(*_arg0); end
  def local_variables; end
  def loop; end
  def open(*_arg0); end
  def p(*_arg0); end
  def pp(*objs); end
  def print(*_arg0); end
  def printf(*_arg0); end
  def proc; end
  def putc(_arg0); end
  def puts(*_arg0); end
  def raise(*_arg0); end
  def rand(*_arg0); end
  def readline(*_arg0); end
  def readlines(*_arg0); end
  def require(_arg0); end
  def require_relative(_arg0); end
  def respond_to_missing?(_arg0, _arg1); end
  def select(*_arg0); end
  def set_trace_func(_arg0); end
  def sleep(*_arg0); end
  def spawn(*_arg0); end
  def sprintf(*_arg0); end
  def srand(*_arg0); end
  def syscall; end
  def system(*_arg0); end
  def test(*_arg0); end
  def throw(*_arg0); end
  def trace_var(*_arg0); end
  def trap(*_arg0); end
  def untrace_var(*_arg0); end
  def warn(*msgs, uplevel: T.unsafe(nil), category: T.unsafe(nil)); end

  class << self
    def Array(_arg0); end
    def Complex(*_arg0); end
    def Float(arg, exception: T.unsafe(nil)); end
    def Hash(_arg0); end
    def Integer(*_arg0); end
    def Pathname(_arg0); end
    def Rational(*_arg0); end
    def String(_arg0); end
    def URI(uri); end
    def __callee__; end
    def __dir__; end
    def __method__; end
    def `(_arg0); end
    def abort(*_arg0); end
    def at_exit; end
    def autoload(_arg0, _arg1); end
    def autoload?(*_arg0); end
    def binding; end
    def block_given?; end
    def caller(*_arg0); end
    def caller_locations(*_arg0); end
    def catch(*_arg0); end
    def eval(*_arg0); end
    def exec(*_arg0); end
    def exit(*_arg0); end
    def exit!(*_arg0); end
    def fail(*_arg0); end
    def fork; end
    def format(*_arg0); end
    def gem(dep, *reqs); end
    def gets(*_arg0); end
    def global_variables; end
    def iterator?; end
    def lambda; end
    def load(*_arg0); end
    def local_variables; end
    def loop; end
    def open(*_arg0); end
    def p(*_arg0); end
    def pp(*objs); end
    def print(*_arg0); end
    def printf(*_arg0); end
    def proc; end
    def putc(_arg0); end
    def puts(*_arg0); end
    def raise(*_arg0); end
    def rand(*_arg0); end
    def readline(*_arg0); end
    def readlines(*_arg0); end
    def require(_arg0); end
    def require_relative(_arg0); end
    def select(*_arg0); end
    def set_trace_func(_arg0); end
    def sleep(*_arg0); end
    def spawn(*_arg0); end
    def sprintf(*_arg0); end
    def srand(*_arg0); end
    def syscall; end
    def system(*_arg0); end
    def test(*_arg0); end
    def throw(*_arg0); end
    def trace_var(*_arg0); end
    def trap(*_arg0); end
    def untrace_var(*_arg0); end
    def warn(*msgs, uplevel: T.unsafe(nil), category: T.unsafe(nil)); end
  end
end

class KeyError < ::IndexError
  include ::DidYouMean::Correctable

  def initialize(*_arg0); end

  def key; end
  def receiver; end
end

class LoadError < ::ScriptError
  include ::DidYouMean::Correctable

  def path; end
end

class LocalJumpError < ::StandardError
  def exit_value; end
  def reason; end
end

module Marshal
  private

  def dump(*_arg0); end

  class << self
    def dump(*_arg0); end
    def load(source, proc = T.unsafe(nil), freeze: T.unsafe(nil)); end
    def restore(source, proc = T.unsafe(nil), freeze: T.unsafe(nil)); end
  end
end

Marshal::MAJOR_VERSION = T.let(T.unsafe(nil), Integer)
Marshal::MINOR_VERSION = T.let(T.unsafe(nil), Integer)

class MatchData
  def ==(_arg0); end
  def [](*_arg0); end
  def begin(_arg0); end
  def byteoffset(_arg0); end
  def captures; end
  def deconstruct; end
  def deconstruct_keys(_arg0); end
  def end(_arg0); end
  def eql?(_arg0); end
  def hash; end
  def inspect; end
  def length; end
  def match(_arg0); end
  def match_length(_arg0); end
  def named_captures; end
  def names; end
  def offset(_arg0); end
  def post_match; end
  def pre_match; end
  def pretty_print(q); end
  def regexp; end
  def size; end
  def string; end
  def to_a; end
  def to_s; end
  def values_at(*_arg0); end

  private

  def initialize_copy(_arg0); end
end

module Math
  private

  def acos(_arg0); end
  def acosh(_arg0); end
  def asin(_arg0); end
  def asinh(_arg0); end
  def atan(_arg0); end
  def atan2(_arg0, _arg1); end
  def atanh(_arg0); end
  def cbrt(_arg0); end
  def cos(_arg0); end
  def cosh(_arg0); end
  def erf(_arg0); end
  def erfc(_arg0); end
  def exp(_arg0); end
  def frexp(_arg0); end
  def gamma(_arg0); end
  def hypot(_arg0, _arg1); end
  def ldexp(_arg0, _arg1); end
  def lgamma(_arg0); end
  def log(*_arg0); end
  def log10(_arg0); end
  def log2(_arg0); end
  def sin(_arg0); end
  def sinh(_arg0); end
  def sqrt(_arg0); end
  def tan(_arg0); end
  def tanh(_arg0); end

  class << self
    def acos(_arg0); end
    def acosh(_arg0); end
    def asin(_arg0); end
    def asinh(_arg0); end
    def atan(_arg0); end
    def atan2(_arg0, _arg1); end
    def atanh(_arg0); end
    def cbrt(_arg0); end
    def cos(_arg0); end
    def cosh(_arg0); end
    def erf(_arg0); end
    def erfc(_arg0); end
    def exp(_arg0); end
    def frexp(_arg0); end
    def gamma(_arg0); end
    def hypot(_arg0, _arg1); end
    def ldexp(_arg0, _arg1); end
    def lgamma(_arg0); end
    def log(*_arg0); end
    def log10(_arg0); end
    def log2(_arg0); end
    def sin(_arg0); end
    def sinh(_arg0); end
    def sqrt(_arg0); end
    def tan(_arg0); end
    def tanh(_arg0); end
  end
end

class Math::DomainError < ::StandardError; end
Math::E = T.let(T.unsafe(nil), Float)
Math::PI = T.let(T.unsafe(nil), Float)

class Method
  def <<(_arg0); end
  def ==(_arg0); end
  def ===(*_arg0); end
  def >>(_arg0); end
  def [](*_arg0); end
  def arity; end
  def call(*_arg0); end
  def clone; end
  def curry(*_arg0); end
  def eql?(_arg0); end
  def hash; end
  def inspect; end
  def name; end
  def original_name; end
  def owner; end
  def parameters; end
  def receiver; end
  def source_location; end
  def super_method; end
  def to_proc; end
  def to_s; end
  def unbind; end
end

class Module
  def initialize; end

  def <(_arg0); end
  def <=(_arg0); end
  def <=>(_arg0); end
  def ==(_arg0); end
  def ===(_arg0); end
  def >(_arg0); end
  def >=(_arg0); end
  def alias_method(_arg0, _arg1); end
  def ancestors; end
  def append_features(constant); end
  def attr(*_arg0); end
  def attr_accessor(*_arg0); end
  def attr_reader(*_arg0); end
  def attr_writer(*_arg0); end
  def autoload(const_name, path); end
  def autoload?(*_arg0); end
  def autoload_without_tapioca(_arg0, _arg1); end
  def class_eval(*_arg0); end
  def class_exec(*_arg0); end
  def class_name; end
  def class_variable_defined?(_arg0); end
  def class_variable_get(_arg0); end
  def class_variable_set(_arg0, _arg1); end
  def class_variables(*_arg0); end
  def const_defined?(*_arg0); end
  def const_get(*_arg0); end
  def const_missing(_arg0); end
  def const_set(_arg0, _arg1); end
  def const_source_location(*_arg0); end
  def constants(*_arg0); end
  def define_method(*_arg0); end
  def deprecate_constant(*_arg0); end
  def extend_object(obj); end
  def freeze; end
  def include(*_arg0); end
  def include?(_arg0); end
  def included_modules; end
  def inspect; end
  def instance_method(_arg0); end
  def instance_methods(*_arg0); end
  def method_defined?(*_arg0); end
  def module_eval(*_arg0); end
  def module_exec(*_arg0); end
  def name; end
  def prepend(*_arg0); end
  def prepend_features(constant); end
  def pretty_print(q); end
  def pretty_print_cycle(q); end
  def private_class_method(*_arg0); end
  def private_constant(*_arg0); end
  def private_instance_methods(*_arg0); end
  def private_method_defined?(*_arg0); end
  def protected_instance_methods(*_arg0); end
  def protected_method_defined?(*_arg0); end
  def public_class_method(*_arg0); end
  def public_constant(*_arg0); end
  def public_instance_method(_arg0); end
  def public_instance_methods(*_arg0); end
  def public_method_defined?(*_arg0); end
  def refinements; end
  def remove_class_variable(_arg0); end
  def remove_method(*_arg0); end
  def singleton_class?; end
  def to_s; end
  def undef_method(*_arg0); end
  def undefined_instance_methods; end

  private

  def const_added(_arg0); end
  def extended(_arg0); end
  def included(_arg0); end
  def initialize_clone(*_arg0); end
  def initialize_copy(_arg0); end
  def method_added(_arg0); end
  def method_removed(_arg0); end
  def method_undefined(_arg0); end
  def module_function(*_arg0); end
  def prepended(_arg0); end
  def private(*_arg0); end
  def protected(*_arg0); end
  def public(*_arg0); end
  def refine(_arg0); end
  def remove_const(_arg0); end
  def ruby2_keywords(*_arg0); end
  def using(_arg0); end

  class << self
    def constants(*_arg0); end
    def nesting; end
    def used_modules; end
    def used_refinements; end
  end
end

class Monitor
  def enter; end
  def exit; end
  def mon_check_owner; end
  def mon_enter; end
  def mon_exit; end
  def mon_locked?; end
  def mon_owned?; end
  def mon_synchronize; end
  def mon_try_enter; end
  def new_cond; end
  def synchronize; end
  def try_enter; end
  def try_mon_enter; end
  def wait_for_cond(_arg0, _arg1); end
end

module MonitorMixin
  def initialize(*_arg0, **_arg1, &_arg2); end

  def mon_enter; end
  def mon_exit; end
  def mon_locked?; end
  def mon_owned?; end
  def mon_synchronize(&b); end
  def mon_try_enter; end
  def new_cond; end
  def synchronize(&b); end
  def try_mon_enter; end

  private

  def mon_check_owner; end
  def mon_initialize; end

  class << self
    def extend_object(obj); end
  end
end

class MonitorMixin::ConditionVariable
  def initialize(monitor); end

  def broadcast; end
  def signal; end
  def wait(timeout = T.unsafe(nil)); end
  def wait_until; end
  def wait_while; end
end

class NameError < ::StandardError
  include ::ErrorHighlight::CoreExt
  include ::DidYouMean::Correctable

  def initialize(*_arg0); end

  def local_variables; end
  def name; end
  def receiver; end
end

class NilClass
  def &(_arg0); end
  def ===(_arg0); end
  def =~(_arg0); end
  def ^(_arg0); end
  def inspect; end
  def nil?; end
  def pretty_print_cycle(q); end
  def rationalize(*_arg0); end
  def to_a; end
  def to_c; end
  def to_f; end
  def to_h; end
  def to_i; end
  def to_r; end
  def to_s; end
  def |(_arg0); end
end

class NoMatchingPatternError < ::StandardError; end

class NoMatchingPatternKeyError < ::NoMatchingPatternError
  include ::DidYouMean::Correctable

  def initialize(*_arg0); end

  def key; end
  def matchee; end
end

class NoMemoryError < ::Exception; end

class NoMethodError < ::NameError
  def initialize(*_arg0); end

  def args; end
  def private_call?; end
end

class NotImplementedError < ::ScriptError; end

class Numeric
  include ::Comparable

  def %(_arg0); end
  def +@; end
  def -@; end
  def <=>(_arg0); end
  def abs; end
  def abs2; end
  def angle; end
  def arg; end
  def ceil(*_arg0); end
  def clone(*_arg0); end
  def coerce(_arg0); end
  def conj; end
  def conjugate; end
  def denominator; end
  def div(_arg0); end
  def divmod(_arg0); end
  def dup; end
  def eql?(_arg0); end
  def fdiv(_arg0); end
  def finite?; end
  def floor(*_arg0); end
  def i; end
  def imag; end
  def imaginary; end
  def infinite?; end
  def integer?; end
  def magnitude; end
  def modulo(_arg0); end
  def negative?; end
  def nonzero?; end
  def numerator; end
  def phase; end
  def polar; end
  def positive?; end
  def pretty_print(q); end
  def pretty_print_cycle(q); end
  def quo(_arg0); end
  def real; end
  def real?; end
  def rect; end
  def rectangular; end
  def remainder(_arg0); end
  def round(*_arg0); end
  def singleton_method_added(_arg0); end
  def step(*_arg0); end
  def to_c; end
  def to_int; end
  def truncate(*_arg0); end
  def zero?; end
end

class Object < ::BasicObject
  include ::Kernel
  include ::PP::ObjectMixin

  def to_yaml(options = T.unsafe(nil)); end

  private

  def DelegateClass(superclass, &block); end
  def Digest(name); end
  def P(namespace, name = T.unsafe(nil), type = T.unsafe(nil)); end
  def log; end

  class << self
    def yaml_tag(url); end
  end
end

module ObjectSpace
  private

  def _id2ref(_arg0); end
  def count_objects(*_arg0); end
  def define_finalizer(*_arg0); end
  def each_object(*_arg0); end
  def garbage_collect(full_mark: T.unsafe(nil), immediate_mark: T.unsafe(nil), immediate_sweep: T.unsafe(nil)); end
  def undefine_finalizer(_arg0); end

  class << self
    def _id2ref(_arg0); end
    def count_objects(*_arg0); end
    def define_finalizer(*_arg0); end
    def each_object(*_arg0); end
    def garbage_collect(full_mark: T.unsafe(nil), immediate_mark: T.unsafe(nil), immediate_sweep: T.unsafe(nil)); end
    def undefine_finalizer(_arg0); end
  end
end

class ObjectSpace::WeakMap
  include ::Enumerable

  def [](_arg0); end
  def []=(_arg0, _arg1); end
  def each; end
  def each_key; end
  def each_pair; end
  def each_value; end
  def include?(_arg0); end
  def inspect; end
  def key?(_arg0); end
  def keys; end
  def length; end
  def member?(_arg0); end
  def size; end
  def values; end
end

module PP::ObjectMixin
  def pretty_print(q); end
  def pretty_print_cycle(q); end
  def pretty_print_inspect; end
  def pretty_print_instance_variables; end
end

class Proc
  def <<(_arg0); end
  def ==(_arg0); end
  def ===(*_arg0); end
  def >>(_arg0); end
  def [](*_arg0); end
  def arity; end
  def binding; end
  def call(*_arg0); end
  def clone; end
  def curry(*_arg0); end
  def dup; end
  def eql?(_arg0); end
  def hash; end
  def inspect; end
  def lambda?; end
  def parameters(*_arg0); end
  def ruby2_keywords; end
  def source_location; end
  def to_proc; end
  def to_s; end
  def yield(*_arg0); end

  class << self
    def new(*_arg0); end
  end
end

module Process
  private

  def argv0; end
  def clock_getres(*_arg0); end
  def clock_gettime(*_arg0); end
  def daemon(*_arg0); end
  def detach(_arg0); end
  def egid; end
  def egid=(_arg0); end
  def euid; end
  def euid=(_arg0); end
  def getpgid(_arg0); end
  def getpgrp; end
  def getpriority(_arg0, _arg1); end
  def getrlimit(_arg0); end
  def getsid(*_arg0); end
  def gid; end
  def gid=(_arg0); end
  def groups; end
  def groups=(_arg0); end
  def initgroups(_arg0, _arg1); end
  def kill(*_arg0); end
  def maxgroups; end
  def maxgroups=(_arg0); end
  def pid; end
  def ppid; end
  def setpgid(_arg0, _arg1); end
  def setpgrp; end
  def setpriority(_arg0, _arg1, _arg2); end
  def setproctitle(_arg0); end
  def setrlimit(*_arg0); end
  def setsid; end
  def times; end
  def uid; end
  def uid=(_arg0); end
  def wait(*_arg0); end
  def wait2(*_arg0); end
  def waitall; end
  def waitpid(*_arg0); end
  def waitpid2(*_arg0); end

  class << self
    def _fork; end
    def abort(*_arg0); end
    def argv0; end
    def clock_getres(*_arg0); end
    def clock_gettime(*_arg0); end
    def daemon(*_arg0); end
    def detach(_arg0); end
    def egid; end
    def egid=(_arg0); end
    def euid; end
    def euid=(_arg0); end
    def exec(*_arg0); end
    def exit(*_arg0); end
    def exit!(*_arg0); end
    def fork; end
    def getpgid(_arg0); end
    def getpgrp; end
    def getpriority(_arg0, _arg1); end
    def getrlimit(_arg0); end
    def getsid(*_arg0); end
    def gid; end
    def gid=(_arg0); end
    def groups; end
    def groups=(_arg0); end
    def initgroups(_arg0, _arg1); end
    def kill(*_arg0); end
    def last_status; end
    def maxgroups; end
    def maxgroups=(_arg0); end
    def pid; end
    def ppid; end
    def setpgid(_arg0, _arg1); end
    def setpgrp; end
    def setpriority(_arg0, _arg1, _arg2); end
    def setproctitle(_arg0); end
    def setrlimit(*_arg0); end
    def setsid; end
    def spawn(*_arg0); end
    def times; end
    def uid; end
    def uid=(_arg0); end
    def wait(*_arg0); end
    def wait2(*_arg0); end
    def waitall; end
    def waitpid(*_arg0); end
    def waitpid2(*_arg0); end
  end
end

module Process::GID
  private

  def change_privilege(_arg0); end
  def eid; end
  def from_name(_arg0); end
  def grant_privilege(_arg0); end
  def re_exchange; end
  def re_exchangeable?; end
  def rid; end
  def sid_available?; end
  def switch; end

  class << self
    def change_privilege(_arg0); end
    def eid; end
    def eid=(_arg0); end
    def from_name(_arg0); end
    def grant_privilege(_arg0); end
    def re_exchange; end
    def re_exchangeable?; end
    def rid; end
    def sid_available?; end
    def switch; end
  end
end

class Process::Status
  def &(_arg0); end
  def ==(_arg0); end
  def >>(_arg0); end
  def coredump?; end
  def exited?; end
  def exitstatus; end
  def inspect; end
  def pid; end
  def signaled?; end
  def stopped?; end
  def stopsig; end
  def success?; end
  def termsig; end
  def to_i; end
  def to_s; end

  class << self
    def wait(*_arg0); end
  end
end

module Process::Sys
  private

  def getegid; end
  def geteuid; end
  def getgid; end
  def getuid; end
  def issetugid; end
  def setegid(_arg0); end
  def seteuid(_arg0); end
  def setgid(_arg0); end
  def setregid(_arg0, _arg1); end
  def setresgid; end
  def setresuid; end
  def setreuid(_arg0, _arg1); end
  def setrgid(_arg0); end
  def setruid(_arg0); end
  def setuid(_arg0); end

  class << self
    def getegid; end
    def geteuid; end
    def getgid; end
    def getuid; end
    def issetugid; end
    def setegid(_arg0); end
    def seteuid(_arg0); end
    def setgid(_arg0); end
    def setregid(_arg0, _arg1); end
    def setresgid; end
    def setresuid; end
    def setreuid(_arg0, _arg1); end
    def setrgid(_arg0); end
    def setruid(_arg0); end
    def setuid(_arg0); end
  end
end

class Process::Tms < ::Struct
  def cstime; end
  def cstime=(_); end
  def cutime; end
  def cutime=(_); end
  def stime; end
  def stime=(_); end
  def utime; end
  def utime=(_); end

  class << self
    def [](*_arg0); end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

module Process::UID
  private

  def change_privilege(_arg0); end
  def eid; end
  def from_name(_arg0); end
  def grant_privilege(_arg0); end
  def re_exchange; end
  def re_exchangeable?; end
  def rid; end
  def sid_available?; end
  def switch; end

  class << self
    def change_privilege(_arg0); end
    def eid; end
    def eid=(_arg0); end
    def from_name(_arg0); end
    def grant_privilege(_arg0); end
    def re_exchange; end
    def re_exchangeable?; end
    def rid; end
    def sid_available?; end
    def switch; end
  end
end

class Process::Waiter < ::Thread
  def pid; end
end

class Ractor
  def <<(obj, move: T.unsafe(nil)); end
  def [](sym); end
  def []=(sym, val); end
  def close_incoming; end
  def close_outgoing; end
  def inspect; end
  def name; end
  def send(obj, move: T.unsafe(nil)); end
  def take; end
  def to_s; end

  private

  def receive; end
  def receive_if(&b); end
  def recv; end

  class << self
    def count; end
    def current; end
    def main; end
    def make_shareable(obj, copy: T.unsafe(nil)); end
    def new(*args, name: T.unsafe(nil), &block); end
    def receive; end
    def receive_if(&b); end
    def recv; end
    def select(*ractors, yield_value: T.unsafe(nil), move: T.unsafe(nil)); end
    def shareable?(obj); end
    def yield(obj, move: T.unsafe(nil)); end
  end
end

class Ractor::ClosedError < ::StopIteration; end
class Ractor::Error < ::RuntimeError; end
class Ractor::IsolationError < ::Ractor::Error; end
class Ractor::MovedError < ::Ractor::Error; end

class Ractor::MovedObject < ::BasicObject
  def !(*_arg0); end
  def !=(*_arg0); end
  def ==(*_arg0); end
  def __id__(*_arg0); end
  def __send__(*_arg0); end
  def equal?(*_arg0); end
  def instance_eval(*_arg0); end
  def instance_exec(*_arg0); end
  def method_missing(*_arg0); end
end

class Ractor::RemoteError < ::Ractor::Error
  def ractor; end
end

class Ractor::UnsafeError < ::Ractor::Error; end

class Random < ::Random::Base
  def ==(_arg0); end

  private

  def initialize_copy(_arg0); end
  def left; end
  def marshal_dump; end
  def marshal_load(_arg0); end
  def state; end

  class << self
    def bytes(_arg0); end
    def new_seed; end
    def rand(*_arg0); end
    def seed; end
    def srand(*_arg0); end
    def urandom(_arg0); end

    private

    def left; end
    def state; end
  end
end

class Random::Base
  include ::Random::Formatter
  extend ::Random::Formatter

  def initialize(*_arg0); end

  def bytes(_arg0); end
  def rand(*_arg0); end
  def seed; end
end

module Random::Formatter
  def alphanumeric(n = T.unsafe(nil)); end
  def base64(n = T.unsafe(nil)); end
  def hex(n = T.unsafe(nil)); end
  def rand(*_arg0); end
  def random_bytes(n = T.unsafe(nil)); end
  def random_number(*_arg0); end
  def urlsafe_base64(n = T.unsafe(nil), padding = T.unsafe(nil)); end
  def uuid; end

  private

  def choose(source, n); end
  def gen_random(n); end
end

class Range
  include ::Enumerable

  def initialize(*_arg0); end

  def %(_arg0); end
  def ==(_arg0); end
  def ===(_arg0); end
  def begin; end
  def bsearch; end
  def count(*_arg0); end
  def cover?(_arg0); end
  def each; end
  def end; end
  def entries; end
  def eql?(_arg0); end
  def exclude_end?; end
  def first(*_arg0); end
  def hash; end
  def include?(_arg0); end
  def inspect; end
  def last(*_arg0); end
  def max(*_arg0); end
  def member?(_arg0); end
  def min(*_arg0); end
  def minmax; end
  def pretty_print(q); end
  def size; end
  def step(*_arg0); end
  def to_a; end
  def to_s; end

  private

  def initialize_copy(_arg0); end
end

class RangeError < ::StandardError; end

class Rational < ::Numeric
  def *(_arg0); end
  def **(_arg0); end
  def +(_arg0); end
  def -(_arg0); end
  def -@; end
  def /(_arg0); end
  def <=>(_arg0); end
  def ==(_arg0); end
  def abs; end
  def ceil(*_arg0); end
  def coerce(_arg0); end
  def denominator; end
  def fdiv(_arg0); end
  def floor(*_arg0); end
  def hash; end
  def inspect; end
  def magnitude; end
  def negative?; end
  def numerator; end
  def positive?; end
  def quo(_arg0); end
  def rationalize(*_arg0); end
  def round(*_arg0); end
  def to_f; end
  def to_i; end
  def to_r; end
  def to_s; end
  def truncate(*_arg0); end

  private

  def marshal_dump; end

  class << self
    private

    def convert(*_arg0); end
  end
end

module RbConfig
  class << self
    def expand(val, config = T.unsafe(nil)); end
    def fire_update!(key, val, mkconf = T.unsafe(nil), conf = T.unsafe(nil)); end
    def ruby; end
  end
end

class Refinement < ::Module
  def refined_class; end

  private

  def import_methods(*_arg0); end
end

class Regexp
  def initialize(*_arg0); end

  def ==(_arg0); end
  def ===(_arg0); end
  def =~(_arg0); end
  def casefold?; end
  def encoding; end
  def eql?(_arg0); end
  def fixed_encoding?; end
  def hash; end
  def inspect; end
  def match(*_arg0); end
  def match?(*_arg0); end
  def named_captures; end
  def names; end
  def options; end
  def source; end
  def timeout; end
  def to_s; end
  def ~; end

  private

  def initialize_copy(_arg0); end

  class << self
    def compile(*_arg0); end
    def escape(_arg0); end
    def last_match(*_arg0); end
    def linear_time?(*_arg0); end
    def quote(_arg0); end
    def timeout; end
    def timeout=(_arg0); end
    def try_convert(_arg0); end
    def union(*_arg0); end
  end
end

Regexp::EXTENDED = T.let(T.unsafe(nil), Integer)
Regexp::FIXEDENCODING = T.let(T.unsafe(nil), Integer)
Regexp::IGNORECASE = T.let(T.unsafe(nil), Integer)
Regexp::MULTILINE = T.let(T.unsafe(nil), Integer)
Regexp::NOENCODING = T.let(T.unsafe(nil), Integer)
class Regexp::TimeoutError < ::RegexpError; end
class RegexpError < ::StandardError; end

class RubyVM
  class << self
    def keep_script_lines; end
    def keep_script_lines=(_arg0); end
    def stat(*_arg0); end
  end
end

module RubyVM::AbstractSyntaxTree
  class << self
    def node_id_for_backtrace_location(backtrace_location); end
    def of(body, keep_script_lines: T.unsafe(nil), error_tolerant: T.unsafe(nil), keep_tokens: T.unsafe(nil)); end
    def parse(string, keep_script_lines: T.unsafe(nil), error_tolerant: T.unsafe(nil), keep_tokens: T.unsafe(nil)); end
    def parse_file(pathname, keep_script_lines: T.unsafe(nil), error_tolerant: T.unsafe(nil), keep_tokens: T.unsafe(nil)); end
  end
end

class RubyVM::AbstractSyntaxTree::Node
  def all_tokens; end
  def children; end
  def first_column; end
  def first_lineno; end
  def inspect; end
  def last_column; end
  def last_lineno; end
  def node_id; end
  def pretty_print(q); end
  def pretty_print_children(q, names = T.unsafe(nil)); end
  def script_lines; end
  def source; end
  def tokens; end
  def type; end
end

RubyVM::DEFAULT_PARAMS = T.let(T.unsafe(nil), Hash)
RubyVM::INSTRUCTION_NAMES = T.let(T.unsafe(nil), Array)

class RubyVM::InstructionSequence
  def absolute_path; end
  def base_label; end
  def disasm; end
  def disassemble; end
  def each_child; end
  def eval; end
  def first_lineno; end
  def inspect; end
  def label; end
  def path; end
  def script_lines; end
  def to_a; end
  def to_binary(*_arg0); end
  def trace_points; end

  class << self
    def compile(*_arg0); end
    def compile_file(*_arg0); end
    def compile_option; end
    def compile_option=(_arg0); end
    def disasm(_arg0); end
    def disassemble(_arg0); end
    def load_from_binary(_arg0); end
    def load_from_binary_extra_data(_arg0); end
    def new(*_arg0); end
    def of(_arg0); end
  end
end

module RubyVM::MJIT
  class << self
    def enabled?; end
    def pause(wait: T.unsafe(nil)); end
    def resume; end
  end
end

RubyVM::OPTS = T.let(T.unsafe(nil), Array)

module RubyVM::YJIT
  class << self
    def code_gc; end
    def disasm(iseq); end
    def dump_exit_locations(filename); end
    def enabled?; end
    def exit_locations; end
    def insns_compiled(iseq); end
    def reset_stats!; end
    def runtime_stats; end
    def simulate_oom!; end
    def stats_enabled?; end
    def trace_exit_locations_enabled?; end

    private

    def _dump_locations; end
    def _print_stats; end
    def print_counters(counters, prefix:, prompt:); end
    def print_sorted_exit_counts(stats, prefix:, how_many: T.unsafe(nil), left_pad: T.unsafe(nil)); end
    def total_exit_count(stats, prefix: T.unsafe(nil)); end
  end
end

class RuntimeError < ::StandardError; end
STDERR = T.let(T.unsafe(nil), IO)
STDIN = T.let(T.unsafe(nil), IO)
STDOUT = T.let(T.unsafe(nil), IO)
class ScriptError < ::Exception; end
class SecurityError < ::Exception; end

class Set
  include ::Enumerable

  def initialize(enum = T.unsafe(nil), &block); end

  def &(enum); end
  def +(enum); end
  def -(enum); end
  def <(set); end
  def <<(o); end
  def <=(set); end
  def <=>(set); end
  def ==(other); end
  def ===(o); end
  def >(set); end
  def >=(set); end
  def ^(enum); end
  def add(o); end
  def add?(o); end
  def classify; end
  def clear; end
  def collect!; end
  def compare_by_identity; end
  def compare_by_identity?; end
  def delete(o); end
  def delete?(o); end
  def delete_if; end
  def difference(enum); end
  def disjoint?(set); end
  def divide(&func); end
  def each(&block); end
  def empty?; end
  def eql?(o); end
  def filter!(&block); end
  def flatten; end
  def flatten!; end
  def freeze; end
  def hash; end
  def include?(o); end
  def inspect; end
  def intersect?(set); end
  def intersection(enum); end
  def join(separator = T.unsafe(nil)); end
  def keep_if; end
  def length; end
  def map!; end
  def member?(o); end
  def merge(enum); end
  def pretty_print(pp); end
  def pretty_print_cycle(pp); end
  def proper_subset?(set); end
  def proper_superset?(set); end
  def reject!(&block); end
  def replace(enum); end
  def reset; end
  def select!(&block); end
  def size; end
  def subset?(set); end
  def subtract(enum); end
  def superset?(set); end
  def to_a; end
  def to_s; end
  def to_set(klass = T.unsafe(nil), *args, &block); end
  def union(enum); end
  def |(enum); end

  protected

  def flatten_merge(set, seen = T.unsafe(nil)); end

  private

  def do_with_enum(enum, &block); end
  def initialize_clone(orig, **options); end
  def initialize_dup(orig); end

  class << self
    def [](*ary); end
  end
end

module Signal
  private

  def list; end
  def signame(_arg0); end
  def trap(*_arg0); end

  class << self
    def list; end
    def signame(_arg0); end
    def trap(*_arg0); end
  end
end

class SignalException < ::Exception
  def initialize(*_arg0); end

  def signm; end
  def signo; end
end

class StandardError < ::Exception; end

class StopIteration < ::IndexError
  def result; end
end

class String
  include ::Comparable

  def initialize(*_arg0); end

  def %(_arg0); end
  def *(_arg0); end
  def +(_arg0); end
  def +@; end
  def -@; end
  def <<(_arg0); end
  def <=>(_arg0); end
  def ==(_arg0); end
  def ===(_arg0); end
  def =~(_arg0); end
  def [](*_arg0); end
  def []=(*_arg0); end
  def ascii_only?; end
  def b; end
  def byteindex(*_arg0); end
  def byterindex(*_arg0); end
  def bytes; end
  def bytesize; end
  def byteslice(*_arg0); end
  def bytesplice(*_arg0); end
  def capitalize(*_arg0); end
  def capitalize!(*_arg0); end
  def casecmp(_arg0); end
  def casecmp?(_arg0); end
  def center(*_arg0); end
  def chars; end
  def chomp(*_arg0); end
  def chomp!(*_arg0); end
  def chop; end
  def chop!; end
  def chr; end
  def clear; end
  def codepoints; end
  def concat(*_arg0); end
  def count(*_arg0); end
  def crypt(_arg0); end
  def dedup; end
  def delete(*_arg0); end
  def delete!(*_arg0); end
  def delete_prefix(_arg0); end
  def delete_prefix!(_arg0); end
  def delete_suffix(_arg0); end
  def delete_suffix!(_arg0); end
  def downcase(*_arg0); end
  def downcase!(*_arg0); end
  def dump; end
  def each_byte; end
  def each_char; end
  def each_codepoint; end
  def each_grapheme_cluster; end
  def each_line(*_arg0); end
  def empty?; end
  def encode(*_arg0); end
  def encode!(*_arg0); end
  def encoding; end
  def end_with?(*_arg0); end
  def eql?(_arg0); end
  def force_encoding(_arg0); end
  def freeze; end
  def getbyte(_arg0); end
  def grapheme_clusters; end
  def gsub(*_arg0); end
  def gsub!(*_arg0); end
  def hash; end
  def hex; end
  def include?(_arg0); end
  def index(*_arg0); end
  def insert(_arg0, _arg1); end
  def inspect; end
  def intern; end
  def length; end
  def lines(*_arg0); end
  def ljust(*_arg0); end
  def lstrip; end
  def lstrip!; end
  def match(*_arg0); end
  def match?(*_arg0); end
  def next; end
  def next!; end
  def oct; end
  def ord; end
  def partition(_arg0); end
  def prepend(*_arg0); end
  def pretty_print(q); end
  def replace(_arg0); end
  def reverse; end
  def reverse!; end
  def rindex(*_arg0); end
  def rjust(*_arg0); end
  def rpartition(_arg0); end
  def rstrip; end
  def rstrip!; end
  def scan(_arg0); end
  def scrub(*_arg0); end
  def scrub!(*_arg0); end
  def setbyte(_arg0, _arg1); end
  def shell_split; end
  def shellescape; end
  def shellsplit; end
  def size; end
  def slice(*_arg0); end
  def slice!(*_arg0); end
  def split(*_arg0); end
  def squeeze(*_arg0); end
  def squeeze!(*_arg0); end
  def start_with?(*_arg0); end
  def strip; end
  def strip!; end
  def sub(*_arg0); end
  def sub!(*_arg0); end
  def succ; end
  def succ!; end
  def sum(*_arg0); end
  def swapcase(*_arg0); end
  def swapcase!(*_arg0); end
  def to_c; end
  def to_f; end
  def to_i(*_arg0); end
  def to_r; end
  def to_s; end
  def to_str; end
  def to_sym; end
  def tr(_arg0, _arg1); end
  def tr!(_arg0, _arg1); end
  def tr_s(_arg0, _arg1); end
  def tr_s!(_arg0, _arg1); end
  def undump; end
  def unicode_normalize(*_arg0); end
  def unicode_normalize!(*_arg0); end
  def unicode_normalized?(*_arg0); end
  def unpack(fmt, offset: T.unsafe(nil)); end
  def unpack1(fmt, offset: T.unsafe(nil)); end
  def upcase(*_arg0); end
  def upcase!(*_arg0); end
  def upto(*_arg0); end
  def valid_encoding?; end

  private

  def initialize_copy(_arg0); end

  class << self
    def try_convert(_arg0); end
  end
end

class Struct
  include ::Enumerable

  def initialize(*_arg0); end

  def ==(_arg0); end
  def [](_arg0); end
  def []=(_arg0, _arg1); end
  def deconstruct; end
  def deconstruct_keys(_arg0); end
  def dig(*_arg0); end
  def each; end
  def each_pair; end
  def eql?(_arg0); end
  def filter(*_arg0); end
  def hash; end
  def inspect; end
  def length; end
  def members; end
  def pretty_print(q); end
  def pretty_print_cycle(q); end
  def select(*_arg0); end
  def size; end
  def to_a; end
  def to_h; end
  def to_s; end
  def values; end
  def values_at(*_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def new(*_arg0); end
  end
end

class Symbol
  include ::Comparable

  def <=>(_arg0); end
  def ==(_arg0); end
  def ===(_arg0); end
  def =~(_arg0); end
  def [](*_arg0); end
  def capitalize(*_arg0); end
  def casecmp(_arg0); end
  def casecmp?(_arg0); end
  def downcase(*_arg0); end
  def empty?; end
  def encoding; end
  def end_with?(*_arg0); end
  def id2name; end
  def inspect; end
  def intern; end
  def length; end
  def match(*_arg0); end
  def match?(*_arg0); end
  def name; end
  def next; end
  def pretty_print_cycle(q); end
  def size; end
  def slice(*_arg0); end
  def start_with?(*_arg0); end
  def succ; end
  def swapcase(*_arg0); end
  def to_proc; end
  def to_s; end
  def to_sym; end
  def upcase(*_arg0); end

  class << self
    def all_symbols; end
  end
end

class SyntaxError < ::ScriptError
  def initialize(*_arg0); end

  def path; end
end

module SyntaxSuggest
  class << self
    def module_for_detailed_message; end
  end
end

class SyntaxSuggest::MiniStringIO
  def initialize(isatty: T.unsafe(nil)); end

  def isatty; end
  def puts(value = T.unsafe(nil), **_arg1); end
  def string; end
end

class SystemCallError < ::StandardError
  def initialize(*_arg0); end

  def errno; end

  class << self
    def ===(_arg0); end
  end
end

class SystemExit < ::Exception
  def initialize(*_arg0); end

  def status; end
  def success?; end
end

class SystemStackError < ::Exception; end

class Thread
  def initialize(*_arg0); end

  def [](_arg0); end
  def []=(_arg0, _arg1); end
  def abort_on_exception; end
  def abort_on_exception=(_arg0); end
  def add_trace_func(_arg0); end
  def alive?; end
  def backtrace(*_arg0); end
  def backtrace_locations(*_arg0); end
  def exit; end
  def fetch(*_arg0); end
  def group; end
  def inspect; end
  def join(*_arg0); end
  def key?(_arg0); end
  def keys; end
  def kill; end
  def name; end
  def name=(_arg0); end
  def native_thread_id; end
  def pending_interrupt?(*_arg0); end
  def priority; end
  def priority=(_arg0); end
  def raise(*_arg0); end
  def report_on_exception; end
  def report_on_exception=(_arg0); end
  def run; end
  def set_trace_func(_arg0); end
  def status; end
  def stop?; end
  def terminate; end
  def thread_variable?(_arg0); end
  def thread_variable_get(_arg0); end
  def thread_variable_set(_arg0, _arg1); end
  def thread_variables; end
  def to_s; end
  def value; end
  def wakeup; end

  class << self
    def abort_on_exception; end
    def abort_on_exception=(_arg0); end
    def current; end
    def each_caller_location; end
    def exit; end
    def fork(*_arg0); end
    def handle_interrupt(_arg0); end
    def ignore_deadlock; end
    def ignore_deadlock=(_arg0); end
    def kill(_arg0); end
    def list; end
    def main; end
    def new(*_arg0); end
    def pass; end
    def pending_interrupt?(*_arg0); end
    def report_on_exception; end
    def report_on_exception=(_arg0); end
    def start(*_arg0); end
    def stop; end
  end
end

class Thread::Backtrace
  class << self
    def limit; end
  end
end

class Thread::Backtrace::Location
  def absolute_path; end
  def base_label; end
  def inspect; end
  def label; end
  def lineno; end
  def path; end
  def to_s; end
end

class Thread::ConditionVariable
  def initialize; end

  def broadcast; end
  def marshal_dump; end
  def signal; end
  def wait(*_arg0); end
end

class Thread::Mutex
  def initialize; end

  def lock; end
  def locked?; end
  def owned?; end
  def sleep(*_arg0); end
  def synchronize; end
  def try_lock; end
  def unlock; end
end

class Thread::Queue
  def initialize(*_arg0); end

  def <<(_arg0); end
  def clear; end
  def close; end
  def closed?; end
  def deq(non_block = T.unsafe(nil), timeout: T.unsafe(nil)); end
  def empty?; end
  def enq(_arg0); end
  def length; end
  def marshal_dump; end
  def num_waiting; end
  def pop(non_block = T.unsafe(nil), timeout: T.unsafe(nil)); end
  def push(_arg0); end
  def shift(non_block = T.unsafe(nil), timeout: T.unsafe(nil)); end
  def size; end
end

class Thread::SizedQueue < ::Thread::Queue
  def initialize(_arg0); end

  def <<(object, non_block = T.unsafe(nil), timeout: T.unsafe(nil)); end
  def clear; end
  def close; end
  def deq(non_block = T.unsafe(nil), timeout: T.unsafe(nil)); end
  def empty?; end
  def enq(object, non_block = T.unsafe(nil), timeout: T.unsafe(nil)); end
  def length; end
  def max; end
  def max=(_arg0); end
  def num_waiting; end
  def pop(non_block = T.unsafe(nil), timeout: T.unsafe(nil)); end
  def push(object, non_block = T.unsafe(nil), timeout: T.unsafe(nil)); end
  def shift(non_block = T.unsafe(nil), timeout: T.unsafe(nil)); end
  def size; end
end

class ThreadError < ::StandardError; end

class ThreadGroup
  def add(_arg0); end
  def enclose; end
  def enclosed?; end
  def list; end
end

class Time
  include ::Comparable

  def initialize(year = T.unsafe(nil), mon = T.unsafe(nil), mday = T.unsafe(nil), hour = T.unsafe(nil), min = T.unsafe(nil), sec = T.unsafe(nil), zone = T.unsafe(nil), in: T.unsafe(nil), precision: T.unsafe(nil)); end

  def +(_arg0); end
  def -(_arg0); end
  def <=>(_arg0); end
  def asctime; end
  def ceil(*_arg0); end
  def ctime; end
  def day; end
  def deconstruct_keys(_arg0); end
  def dst?; end
  def eql?(_arg0); end
  def floor(*_arg0); end
  def friday?; end
  def getgm; end
  def getlocal(*_arg0); end
  def getutc; end
  def gmt?; end
  def gmt_offset; end
  def gmtime; end
  def gmtoff; end
  def hash; end
  def hour; end
  def httpdate; end
  def inspect; end
  def isdst; end
  def iso8601(fraction_digits = T.unsafe(nil)); end
  def localtime(*_arg0); end
  def mday; end
  def min; end
  def mon; end
  def monday?; end
  def month; end
  def nsec; end
  def rfc2822; end
  def rfc822; end
  def round(*_arg0); end
  def saturday?; end
  def sec; end
  def strftime(_arg0); end
  def subsec; end
  def sunday?; end
  def thursday?; end
  def to_a; end
  def to_date; end
  def to_datetime; end
  def to_f; end
  def to_i; end
  def to_r; end
  def to_s; end
  def to_time; end
  def tuesday?; end
  def tv_nsec; end
  def tv_sec; end
  def tv_usec; end
  def usec; end
  def utc; end
  def utc?; end
  def utc_offset; end
  def wday; end
  def wednesday?; end
  def xmlschema(fraction_digits = T.unsafe(nil)); end
  def yday; end
  def year; end
  def zone; end

  private

  def _dump(*_arg0); end
  def initialize_copy(_arg0); end

  class << self
    def at(time, subsec = T.unsafe(nil), unit = T.unsafe(nil), in: T.unsafe(nil)); end
    def gm(*_arg0); end
    def httpdate(date); end
    def iso8601(time); end
    def local(*_arg0); end
    def mktime(*_arg0); end
    def now(in: T.unsafe(nil)); end
    def parse(date, now = T.unsafe(nil)); end
    def rfc2822(date); end
    def rfc822(date); end
    def strptime(date, format, now = T.unsafe(nil)); end
    def utc(*_arg0); end
    def xmlschema(time); end
    def zone_offset(zone, year = T.unsafe(nil)); end

    private

    def _load(_arg0); end
    def apply_offset(year, mon, day, hour, min, sec, off); end
    def force_zone!(t, zone, offset = T.unsafe(nil)); end
    def make_time(date, year, yday, mon, day, hour, min, sec, sec_fraction, zone, now); end
    def month_days(y, m); end
    def zone_utc?(zone); end
  end
end

class TracePoint
  def binding; end
  def callee_id; end
  def defined_class; end
  def disable; end
  def enable(target: T.unsafe(nil), target_line: T.unsafe(nil), target_thread: T.unsafe(nil)); end
  def enabled?; end
  def eval_script; end
  def event; end
  def inspect; end
  def instruction_sequence; end
  def lineno; end
  def method_id; end
  def parameters; end
  def path; end
  def raised_exception; end
  def return_value; end
  def self; end

  class << self
    def allow_reentry; end
    def new(*events); end
    def stat; end
    def trace(*events); end
  end
end

class TrueClass
  def &(_arg0); end
  def ===(_arg0); end
  def ^(_arg0); end
  def inspect; end
  def pretty_print(q); end
  def pretty_print_cycle(q); end
  def to_s; end
  def |(_arg0); end
end

class TypeError < ::StandardError
  include ::ErrorHighlight::CoreExt
end

class UnboundMethod
  def ==(_arg0); end
  def arity; end
  def bind(_arg0); end
  def bind_call(*_arg0); end
  def clone; end
  def eql?(_arg0); end
  def hash; end
  def inspect; end
  def name; end
  def original_name; end
  def owner; end
  def parameters; end
  def source_location; end
  def super_method; end
  def to_s; end
end

class UncaughtThrowError < ::ArgumentError
  def initialize(*_arg0); end

  def tag; end
  def to_s; end
  def value; end
end

module UnicodeNormalize; end

module Warning
  extend ::Warning

  def warn(*_arg0); end

  class << self
    def [](_arg0); end
    def []=(_arg0, _arg1); end
  end
end

class ZeroDivisionError < ::StandardError; end
