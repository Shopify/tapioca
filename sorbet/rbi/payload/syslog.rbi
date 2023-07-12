# typed: __STDLIB_INTERNAL

class Logger
  def initialize(logdev, shift_age = T.unsafe(nil), shift_size = T.unsafe(nil), level: T.unsafe(nil), progname: T.unsafe(nil), formatter: T.unsafe(nil), datetime_format: T.unsafe(nil), binmode: T.unsafe(nil), shift_period_suffix: T.unsafe(nil)); end

  def <<(msg); end
  def add(severity, message = T.unsafe(nil), progname = T.unsafe(nil)); end
  def close; end
  def datetime_format; end
  def datetime_format=(datetime_format); end
  def debug(progname = T.unsafe(nil), &block); end
  def debug!; end
  def debug?; end
  def error(progname = T.unsafe(nil), &block); end
  def error!; end
  def error?; end
  def fatal(progname = T.unsafe(nil), &block); end
  def fatal!; end
  def fatal?; end
  def formatter; end
  def formatter=(_arg0); end
  def info(progname = T.unsafe(nil), &block); end
  def info!; end
  def info?; end
  def level; end
  def level=(severity); end
  def log(severity, message = T.unsafe(nil), progname = T.unsafe(nil)); end
  def progname; end
  def progname=(_arg0); end
  def reopen(logdev = T.unsafe(nil)); end
  def sev_threshold; end
  def sev_threshold=(severity); end
  def unknown(progname = T.unsafe(nil), &block); end
  def warn(progname = T.unsafe(nil), &block); end
  def warn!; end
  def warn?; end

  private

  def format_message(severity, datetime, progname, msg); end
  def format_severity(severity); end
end

class Logger::Error < ::RuntimeError; end

class Logger::Formatter
  def initialize; end

  def call(severity, time, progname, msg); end
  def datetime_format; end
  def datetime_format=(_arg0); end

  private

  def format_datetime(time); end
  def msg2str(msg); end
end

class Logger::LogDevice
  def initialize(log = T.unsafe(nil), shift_age: T.unsafe(nil), shift_size: T.unsafe(nil), shift_period_suffix: T.unsafe(nil), binmode: T.unsafe(nil)); end

  def close; end
  def dev; end
  def filename; end
  def reopen(log = T.unsafe(nil)); end
  def write(message); end

  private

  def add_log_header(file); end
  def check_shift_log; end
  def create_logfile(filename); end
  def lock_shift_log; end
  def open_logfile(filename); end
  def set_dev(log); end
  def shift_log_age; end
  def shift_log_period(period_end); end
end

module Logger::Period
  private

  def next_rotate_time(now, shift_age); end
  def previous_period_end(now, shift_age); end

  class << self
    def next_rotate_time(now, shift_age); end
    def previous_period_end(now, shift_age); end
  end
end

module Logger::Severity; end
class Logger::ShiftingError < ::Logger::Error; end

module Syslog
  include ::Syslog::Option
  include ::Syslog::Facility
  include ::Syslog::Level
  include ::Syslog::Macros
  extend ::Syslog::Macros

  private

  def alert(*_arg0); end
  def close; end
  def crit(*_arg0); end
  def debug(*_arg0); end
  def emerg(*_arg0); end
  def err(*_arg0); end
  def facility; end
  def ident; end
  def info(*_arg0); end
  def instance; end
  def log(*_arg0); end
  def mask; end
  def mask=(_arg0); end
  def notice(*_arg0); end
  def open(*_arg0); end
  def open!(*_arg0); end
  def opened?; end
  def options; end
  def reopen(*_arg0); end
  def warning(*_arg0); end

  class << self
    def alert(*_arg0); end
    def close; end
    def crit(*_arg0); end
    def debug(*_arg0); end
    def emerg(*_arg0); end
    def err(*_arg0); end
    def facility; end
    def ident; end
    def info(*_arg0); end
    def inspect; end
    def instance; end
    def log(*_arg0); end
    def mask; end
    def mask=(_arg0); end
    def notice(*_arg0); end
    def open(*_arg0); end
    def open!(*_arg0); end
    def opened?; end
    def options; end
    def reopen(*_arg0); end
    def warning(*_arg0); end
  end
end

module Syslog::Constants
  include ::Syslog::Option
  include ::Syslog::Facility
  include ::Syslog::Level
  extend ::Syslog::Macros

  mixes_in_class_methods ::Syslog::Macros

  class << self
    def included(_arg0); end
  end
end

module Syslog::Facility; end
module Syslog::Level; end

class Syslog::Logger
  def initialize(program_name = T.unsafe(nil), facility = T.unsafe(nil)); end

  def add(severity, message = T.unsafe(nil), progname = T.unsafe(nil), &block); end
  def debug(message = T.unsafe(nil), &block); end
  def debug?; end
  def error(message = T.unsafe(nil), &block); end
  def error?; end
  def facility; end
  def facility=(_arg0); end
  def fatal(message = T.unsafe(nil), &block); end
  def fatal?; end
  def formatter; end
  def formatter=(_arg0); end
  def info(message = T.unsafe(nil), &block); end
  def info?; end
  def level; end
  def level=(_arg0); end
  def unknown(message = T.unsafe(nil), &block); end
  def unknown?; end
  def warn(message = T.unsafe(nil), &block); end
  def warn?; end

  class << self
    def make_methods(meth); end
    def syslog; end
    def syslog=(syslog); end
  end
end

class Syslog::Logger::Formatter
  def call(severity, time, progname, msg); end

  private

  def clean(message); end
end

module Syslog::Macros
  def LOG_MASK(_arg0); end
  def LOG_UPTO(_arg0); end

  class << self
    def included(_arg0); end
  end
end

module Syslog::Option; end
