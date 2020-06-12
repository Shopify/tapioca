# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   tapioca sync

# typed: true

module Kernel

  private

  def describe(desc, *additional_desc, &block); end
end

module Minitest
  def self.__run(reporter, options); end
  def self.after_run(&block); end
  def self.autorun; end
  def self.backtrace_filter; end
  def self.backtrace_filter=(_); end
  def self.clock_time; end
  def self.extensions; end
  def self.extensions=(_); end
  def self.filter_backtrace(bt); end
  def self.info_signal; end
  def self.info_signal=(_); end
  def self.init_plugins(options); end
  def self.load_plugins; end
  def self.parallel_executor; end
  def self.parallel_executor=(_); end
  def self.process_args(args = _); end
  def self.reporter; end
  def self.reporter=(_); end
  def self.run(args = _); end
  def self.run_one_method(klass, method_name); end
end

class Minitest::AbstractReporter
  include(::Mutex_m)

  def lock; end
  def locked?; end
  def passed?; end
  def prerecord(klass, name); end
  def record(result); end
  def report; end
  def start; end
  def synchronize(&block); end
  def try_lock; end
  def unlock; end
end

class Minitest::Assertion < ::Exception
  def error; end
  def location; end
  def result_code; end
  def result_label; end
end

module Minitest::Assertions
  def _synchronize; end
  def assert(test, msg = _); end
  def assert_empty(obj, msg = _); end
  def assert_equal(exp, act, msg = _); end
  def assert_in_delta(exp, act, delta = _, msg = _); end
  def assert_in_epsilon(exp, act, epsilon = _, msg = _); end
  def assert_includes(collection, obj, msg = _); end
  def assert_instance_of(cls, obj, msg = _); end
  def assert_kind_of(cls, obj, msg = _); end
  def assert_match(matcher, obj, msg = _); end
  def assert_nil(obj, msg = _); end
  def assert_operator(o1, op, o2 = _, msg = _); end
  def assert_output(stdout = _, stderr = _); end
  def assert_path_exists(path, msg = _); end
  def assert_predicate(o1, op, msg = _); end
  def assert_raises(*exp); end
  def assert_respond_to(obj, meth, msg = _); end
  def assert_same(exp, act, msg = _); end
  def assert_send(send_ary, m = _); end
  def assert_silent; end
  def assert_throws(sym, msg = _); end
  def capture_io; end
  def capture_subprocess_io; end
  def diff(exp, act); end
  def exception_details(e, msg); end
  def fail_after(y, m, d, msg); end
  def flunk(msg = _); end
  def message(msg = _, ending = _, &default); end
  def mu_pp(obj); end
  def mu_pp_for_diff(obj); end
  def pass(_msg = _); end
  def refute(test, msg = _); end
  def refute_empty(obj, msg = _); end
  def refute_equal(exp, act, msg = _); end
  def refute_in_delta(exp, act, delta = _, msg = _); end
  def refute_in_epsilon(a, b, epsilon = _, msg = _); end
  def refute_includes(collection, obj, msg = _); end
  def refute_instance_of(cls, obj, msg = _); end
  def refute_kind_of(cls, obj, msg = _); end
  def refute_match(matcher, obj, msg = _); end
  def refute_nil(obj, msg = _); end
  def refute_operator(o1, op, o2 = _, msg = _); end
  def refute_path_exists(path, msg = _); end
  def refute_predicate(o1, op, msg = _); end
  def refute_respond_to(obj, meth, msg = _); end
  def refute_same(exp, act, msg = _); end
  def skip(msg = _, bt = _); end
  def skip_until(y, m, d, msg); end
  def skipped?; end
  def things_to_diff(exp, act); end

  def self.diff; end
  def self.diff=(o); end
end

Minitest::Assertions::E = T.let(T.unsafe(nil), String)

Minitest::Assertions::UNDEFINED = T.let(T.unsafe(nil), Object)

class Minitest::BacktraceFilter
  def filter(bt); end
end

Minitest::BacktraceFilter::MT_RE = T.let(T.unsafe(nil), Regexp)

class Minitest::CompositeReporter < ::Minitest::AbstractReporter
  def initialize(*reporters); end

  def <<(reporter); end
  def io; end
  def passed?; end
  def prerecord(klass, name); end
  def record(result); end
  def report; end
  def reporters; end
  def reporters=(_); end
  def start; end
end

Minitest::ENCS = T.let(T.unsafe(nil), TrueClass)

class Minitest::Expectation < ::Struct
  def ctx; end
  def ctx=(_); end
  def must_be(*args); end
  def must_be_close_to(*args); end
  def must_be_empty(*args); end
  def must_be_instance_of(*args); end
  def must_be_kind_of(*args); end
  def must_be_nil(*args); end
  def must_be_same_as(*args); end
  def must_be_silent(*args); end
  def must_be_within_delta(*args); end
  def must_be_within_epsilon(*args); end
  def must_equal(*args); end
  def must_include(*args); end
  def must_match(*args); end
  def must_output(*args); end
  def must_raise(*args); end
  def must_respond_to(*args); end
  def must_throw(*args); end
  def path_must_exist(*args); end
  def path_wont_exist(*args); end
  def target; end
  def target=(_); end
  def wont_be(*args); end
  def wont_be_close_to(*args); end
  def wont_be_empty(*args); end
  def wont_be_instance_of(*args); end
  def wont_be_kind_of(*args); end
  def wont_be_nil(*args); end
  def wont_be_same_as(*args); end
  def wont_be_within_delta(*args); end
  def wont_be_within_epsilon(*args); end
  def wont_equal(*args); end
  def wont_include(*args); end
  def wont_match(*args); end
  def wont_respond_to(*args); end

  def self.[](*_); end
  def self.inspect; end
  def self.members; end
  def self.new(*_); end
end

module Minitest::Expectations
  def must_be(*args); end
  def must_be_close_to(*args); end
  def must_be_empty(*args); end
  def must_be_instance_of(*args); end
  def must_be_kind_of(*args); end
  def must_be_nil(*args); end
  def must_be_same_as(*args); end
  def must_be_silent(*args); end
  def must_be_within_delta(*args); end
  def must_be_within_epsilon(*args); end
  def must_equal(*args); end
  def must_include(*args); end
  def must_match(*args); end
  def must_output(*args); end
  def must_raise(*args); end
  def must_respond_to(*args); end
  def must_throw(*args); end
  def path_must_exist(*args); end
  def path_wont_exist(*args); end
  def wont_be(*args); end
  def wont_be_close_to(*args); end
  def wont_be_empty(*args); end
  def wont_be_instance_of(*args); end
  def wont_be_kind_of(*args); end
  def wont_be_nil(*args); end
  def wont_be_same_as(*args); end
  def wont_be_within_delta(*args); end
  def wont_be_within_epsilon(*args); end
  def wont_equal(*args); end
  def wont_include(*args); end
  def wont_match(*args); end
  def wont_respond_to(*args); end
end

module Minitest::Guard
  def jruby?(platform = _); end
  def maglev?(platform = _); end
  def mri?(platform = _); end
  def osx?(platform = _); end
  def rubinius?(platform = _); end
  def windows?(platform = _); end
end

module Minitest::Parallel
end

class Minitest::Parallel::Executor
  def initialize(size); end

  def <<(work); end
  def shutdown; end
  def size; end
  def start; end
end

module Minitest::Parallel::Test
  def _synchronize; end
end

module Minitest::Parallel::Test::ClassMethods
  def run_one_method(klass, method_name, reporter); end
  def test_order; end
end

class Minitest::ProgressReporter < ::Minitest::Reporter
  def prerecord(klass, name); end
  def record(result); end
end

module Minitest::Reportable
  def class_name; end
  def error?; end
  def location; end
  def passed?; end
  def result_code; end
  def skipped?; end
end

class Minitest::Reporter < ::Minitest::AbstractReporter
  def initialize(io = _, options = _); end

  def io; end
  def io=(_); end
  def options; end
  def options=(_); end
end

class Minitest::Result < ::Minitest::Runnable
  include(::Minitest::Reportable)

  def class_name; end
  def klass; end
  def klass=(_); end
  def source_location; end
  def source_location=(_); end
  def to_s; end

  def self.from(runnable); end
end

class Minitest::Runnable
  def initialize(name); end

  def assertions; end
  def assertions=(_); end
  def failure; end
  def failures; end
  def failures=(_); end
  def marshal_dump; end
  def marshal_load(ary); end
  def name; end
  def name=(o); end
  def passed?; end
  def result_code; end
  def run; end
  def skipped?; end
  def time; end
  def time=(_); end
  def time_it; end

  def self.inherited(klass); end
  def self.methods_matching(re); end
  def self.on_signal(name, action); end
  def self.reset; end
  def self.run(reporter, options = _); end
  def self.run_one_method(klass, method_name, reporter); end
  def self.runnable_methods; end
  def self.runnables; end
  def self.with_info_handler(reporter, &block); end
end

Minitest::Runnable::SIGNALS = T.let(T.unsafe(nil), Hash)

class Minitest::Skip < ::Minitest::Assertion
  def result_label; end
end

class Minitest::Spec < ::Minitest::Test
  include(::Minitest::Spec::DSL::InstanceMethods)
  extend(::Minitest::Spec::DSL)

  def initialize(name); end

  def self.current; end
end

module Minitest::Spec::DSL
  def after(_type = _, &block); end
  def before(_type = _, &block); end
  def children; end
  def create(name, desc); end
  def desc; end
  def describe_stack; end
  def it(desc = _, &block); end
  def let(name, &block); end
  def name; end
  def nuke_test_methods!; end
  def register_spec_type(*args, &block); end
  def spec_type(desc, *additional); end
  def specify(desc = _, &block); end
  def subject(&block); end
  def to_s; end

  def self.extended(obj); end
end

module Minitest::Spec::DSL::InstanceMethods
  def _(value = _, &block); end
  def before_setup; end
  def expect(value = _, &block); end
  def value(value = _, &block); end
end

Minitest::Spec::DSL::TYPES = T.let(T.unsafe(nil), Array)

Minitest::Spec::TYPES = T.let(T.unsafe(nil), Array)

class Minitest::StatisticsReporter < ::Minitest::Reporter
  def initialize(io = _, options = _); end

  def assertions; end
  def assertions=(_); end
  def count; end
  def count=(_); end
  def errors; end
  def errors=(_); end
  def failures; end
  def failures=(_); end
  def passed?; end
  def record(result); end
  def report; end
  def results; end
  def results=(_); end
  def skips; end
  def skips=(_); end
  def start; end
  def start_time; end
  def start_time=(_); end
  def total_time; end
  def total_time=(_); end
end

class Minitest::SummaryReporter < ::Minitest::StatisticsReporter
  def aggregated_results(io); end
  def old_sync; end
  def old_sync=(_); end
  def report; end
  def start; end
  def statistics; end
  def summary; end
  def sync; end
  def sync=(_); end
  def to_s; end

  private

  def binary_string; end
end

class Minitest::Test < ::Minitest::Runnable
  include(::Minitest::Assertions)
  include(::Minitest::Reportable)
  include(::Minitest::Test::LifecycleHooks)
  include(::Minitest::Guard)
  extend(::Minitest::Guard)

  def capture_exceptions; end
  def class_name; end
  def run; end
  def with_info_handler(&block); end

  def self.i_suck_and_my_tests_are_order_dependent!; end
  def self.io_lock; end
  def self.io_lock=(_); end
  def self.make_my_diffs_pretty!; end
  def self.parallelize_me!; end
  def self.runnable_methods; end
  def self.test_order; end
end

module Minitest::Test::LifecycleHooks
  def after_setup; end
  def after_teardown; end
  def before_setup; end
  def before_teardown; end
  def setup; end
  def teardown; end
end

Minitest::Test::PASSTHROUGH_EXCEPTIONS = T.let(T.unsafe(nil), Array)

Minitest::Test::TEARDOWN_METHODS = T.let(T.unsafe(nil), Array)

class Minitest::UnexpectedError < ::Minitest::Assertion
  def initialize(error); end

  def backtrace; end
  def error; end
  def error=(_); end
  def message; end
  def result_label; end
end

class Minitest::Unit
  def self.after_tests(&b); end
  def self.autorun; end
end

class Minitest::Unit::TestCase < ::Minitest::Test
  def self.inherited(klass); end
end

Minitest::Unit::VERSION = T.let(T.unsafe(nil), String)

Minitest::VERSION = T.let(T.unsafe(nil), String)

class Module
  include(::Module::Concerning)
  include(::ActiveSupport::Dependencies::ModuleConstMissing)

  def infect_an_assertion(meth, new_name, dont_flip = _); end
end

Module::DELEGATION_RESERVED_KEYWORDS = T.let(T.unsafe(nil), Array)

Module::DELEGATION_RESERVED_METHOD_NAMES = T.let(T.unsafe(nil), Set)

Module::RUBY_RESERVED_KEYWORDS = T.let(T.unsafe(nil), Array)
