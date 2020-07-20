# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `minitest-fork_executor` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

module Minitest
  class << self
    def __run(reporter, options); end
    def after_run(&block); end
    def autorun; end
    def backtrace_filter; end
    def backtrace_filter=(_); end
    def clock_time; end
    def extensions; end
    def extensions=(_); end
    def filter_backtrace(bt); end
    def info_signal; end
    def info_signal=(_); end
    def init_plugins(options); end
    def load_plugins; end
    def parallel_executor; end
    def parallel_executor=(_); end
    def process_args(args = _); end
    def reporter; end
    def reporter=(_); end
    def run(args = _); end
    def run_one_method(klass, method_name); end
  end
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

  class << self
    def [](*_); end
    def inspect; end
    def members; end
    def new(*_); end
  end
end

class Minitest::ForkExecutor
  def shutdown; end
  def start; end
end

Minitest::VERSION = T.let(T.unsafe(nil), String)
