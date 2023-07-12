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
