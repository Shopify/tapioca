# typed: false

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `logger` gem.
# Please instead update this file by running `bin/tapioca gem logger`.


# \Class \Logger provides a simple but sophisticated logging utility that
# you can use to create one or more
# {event logs}[https://en.wikipedia.org/wiki/Logging_(software)#Event_logs]
# for your program.
# Each such log contains a chronological sequence of entries
# that provides a record of the program's activities.
#
# == About the Examples
#
# All examples on this page assume that \Logger has been required:
#
#   require 'logger'
#
# == Synopsis
#
# Create a log with Logger.new:
#
#   # Single log file.
#   logger = Logger.new('t.log')
#   # Size-based rotated logging: 3 10-megabyte files.
#   logger = Logger.new('t.log', 3, 10485760)
#   # Period-based rotated logging: daily (also allowed: 'weekly', 'monthly').
#   logger = Logger.new('t.log', 'daily')
#   # Log to an IO stream.
#   logger = Logger.new($stdout)
#
# Add entries (level, message) with Logger#add:
#
#   logger.add(Logger::DEBUG, 'Maximal debugging info')
#   logger.add(Logger::INFO, 'Non-error information')
#   logger.add(Logger::WARN, 'Non-error warning')
#   logger.add(Logger::ERROR, 'Non-fatal error')
#   logger.add(Logger::FATAL, 'Fatal error')
#   logger.add(Logger::UNKNOWN, 'Most severe')
#
# Close the log with Logger#close:
#
#   logger.close
#
# == Entries
#
# You can add entries with method Logger#add:
#
#   logger.add(Logger::DEBUG, 'Maximal debugging info')
#   logger.add(Logger::INFO, 'Non-error information')
#   logger.add(Logger::WARN, 'Non-error warning')
#   logger.add(Logger::ERROR, 'Non-fatal error')
#   logger.add(Logger::FATAL, 'Fatal error')
#   logger.add(Logger::UNKNOWN, 'Most severe')
#
# These shorthand methods also add entries:
#
#   logger.debug('Maximal debugging info')
#   logger.info('Non-error information')
#   logger.warn('Non-error warning')
#   logger.error('Non-fatal error')
#   logger.fatal('Fatal error')
#   logger.unknown('Most severe')
#
# When you call any of these methods,
# the entry may or may not be written to the log,
# depending on the entry's severity and on the log level;
# see {Log Level}[rdoc-ref:Logger@Log+Level]
#
# An entry always has:
#
# - A severity (the required argument to #add).
# - An automatically created timestamp.
#
# And may also have:
#
# - A message.
# - A program name.
#
# Example:
#
#   logger = Logger.new($stdout)
#   logger.add(Logger::INFO, 'My message.', 'mung')
#   # => I, [2022-05-07T17:21:46.536234 #20536]  INFO -- mung: My message.
#
# The default format for an entry is:
#
#   "%s, [%s #%d] %5s -- %s: %s\n"
#
# where the values to be formatted are:
#
# - \Severity (one letter).
# - Timestamp.
# - Process id.
# - \Severity (word).
# - Program name.
# - Message.
#
# You can use a different entry format by:
#
# - Setting a custom format proc (affects following entries);
#   see {formatter=}[Logger.html#attribute-i-formatter].
# - Calling any of the methods above with a block
#   (affects only the one entry).
#   Doing so can have two benefits:
#
#   - Context: the block can evaluate the entire program context
#     and create a context-dependent message.
#   - Performance: the block is not evaluated unless the log level
#     permits the entry actually to be written:
#
#       logger.error { my_slow_message_generator }
#
#     Contrast this with the string form, where the string is
#     always evaluated, regardless of the log level:
#
#       logger.error("#{my_slow_message_generator}")
#
# === \Severity
#
# The severity of a log entry has two effects:
#
# - Determines whether the entry is selected for inclusion in the log;
#   see {Log Level}[rdoc-ref:Logger@Log+Level].
# - Indicates to any log reader (whether a person or a program)
#   the relative importance of the entry.
#
# === Timestamp
#
# The timestamp for a log entry is generated automatically
# when the entry is created.
#
# The logged timestamp is formatted by method
# {Time#strftime}[https://docs.ruby-lang.org/en/master/Time.html#method-i-strftime]
# using this format string:
#
#   '%Y-%m-%dT%H:%M:%S.%6N'
#
# Example:
#
#   logger = Logger.new($stdout)
#   logger.add(Logger::INFO)
#   # => I, [2022-05-07T17:04:32.318331 #20536]  INFO -- : nil
#
# You can set a different format using method #datetime_format=.
#
# === Message
#
# The message is an optional argument to an entry method:
#
#   logger = Logger.new($stdout)
#   logger.add(Logger::INFO, 'My message')
#   # => I, [2022-05-07T18:15:37.647581 #20536]  INFO -- : My message
#
# For the default entry formatter, <tt>Logger::Formatter</tt>,
# the message object may be:
#
# - A string: used as-is.
# - An Exception: <tt>message.message</tt> is used.
# - Anything else: <tt>message.inspect</tt> is used.
#
# *Note*: Logger::Formatter does not escape or sanitize
# the message passed to it.
# Developers should be aware that malicious data (user input)
# may be in the message, and should explicitly escape untrusted data.
#
# You can use a custom formatter to escape message data;
# see the example at {formatter=}[Logger.html#attribute-i-formatter].
#
# === Program Name
#
# The program name is an optional argument to an entry method:
#
#   logger = Logger.new($stdout)
#   logger.add(Logger::INFO, 'My message', 'mung')
#   # => I, [2022-05-07T18:17:38.084716 #20536]  INFO -- mung: My message
#
# The default program name for a new logger may be set in the call to
# Logger.new via optional keyword argument +progname+:
#
#   logger = Logger.new('t.log', progname: 'mung')
#
# The default program name for an existing logger may be set
# by a call to method #progname=:
#
#   logger.progname = 'mung'
#
# The current program name may be retrieved with method
# {progname}[Logger.html#attribute-i-progname]:
#
#   logger.progname # => "mung"
#
# == Log Level
#
# The log level setting determines whether an entry is actually
# written to the log, based on the entry's severity.
#
# These are the defined severities (least severe to most severe):
#
#   logger = Logger.new($stdout)
#   logger.add(Logger::DEBUG, 'Maximal debugging info')
#   # => D, [2022-05-07T17:57:41.776220 #20536] DEBUG -- : Maximal debugging info
#   logger.add(Logger::INFO, 'Non-error information')
#   # => I, [2022-05-07T17:59:14.349167 #20536]  INFO -- : Non-error information
#   logger.add(Logger::WARN, 'Non-error warning')
#   # => W, [2022-05-07T18:00:45.337538 #20536]  WARN -- : Non-error warning
#   logger.add(Logger::ERROR, 'Non-fatal error')
#   # => E, [2022-05-07T18:02:41.592912 #20536] ERROR -- : Non-fatal error
#   logger.add(Logger::FATAL, 'Fatal error')
#   # => F, [2022-05-07T18:05:24.703931 #20536] FATAL -- : Fatal error
#   logger.add(Logger::UNKNOWN, 'Most severe')
#   # => A, [2022-05-07T18:07:54.657491 #20536]   ANY -- : Most severe
#
# The default initial level setting is Logger::DEBUG, the lowest level,
# which means that all entries are to be written, regardless of severity:
#
#   logger = Logger.new($stdout)
#   logger.level # => 0
#   logger.add(0, "My message")
#   # => D, [2022-05-11T15:10:59.773668 #20536] DEBUG -- : My message
#
# You can specify a different setting in a new logger
# using keyword argument +level+ with an appropriate value:
#
#   logger = Logger.new($stdout, level: Logger::ERROR)
#   logger = Logger.new($stdout, level: 'error')
#   logger = Logger.new($stdout, level: :error)
#   logger.level # => 3
#
# With this level, entries with severity Logger::ERROR and higher
# are written, while those with lower severities are not written:
#
#   logger = Logger.new($stdout, level: Logger::ERROR)
#   logger.add(3)
#   # => E, [2022-05-11T15:17:20.933362 #20536] ERROR -- : nil
#   logger.add(2) # Silent.
#
# You can set the log level for an existing logger
# with method #level=:
#
#   logger.level = Logger::ERROR
#
# These shorthand methods also set the level:
#
#   logger.debug! # => 0
#   logger.info!  # => 1
#   logger.warn!  # => 2
#   logger.error! # => 3
#   logger.fatal! # => 4
#
# You can retrieve the log level with method #level.
#
#   logger.level = Logger::ERROR
#   logger.level # => 3
#
# These methods return whether a given
# level is to be written:
#
#   logger.level = Logger::ERROR
#   logger.debug? # => false
#   logger.info?  # => false
#   logger.warn?  # => false
#   logger.error? # => true
#   logger.fatal? # => true
#
# == Log File Rotation
#
# By default, a log file is a single file that grows indefinitely
# (until explicitly closed); there is no file rotation.
#
# To keep log files to a manageable size,
# you can use _log_ _file_ _rotation_, which uses multiple log files:
#
# - Each log file has entries for a non-overlapping
#   time interval.
# - Only the most recent log file is open and active;
#   the others are closed and inactive.
#
# === Size-Based Rotation
#
# For size-based log file rotation, call Logger.new with:
#
# - Argument +logdev+ as a file path.
# - Argument +shift_age+ with a positive integer:
#   the number of log files to be in the rotation.
# - Argument +shift_size+ as a positive integer:
#   the maximum size (in bytes) of each log file;
#   defaults to 1048576 (1 megabyte).
#
# Examples:
#
#   logger = Logger.new('t.log', 3)           # Three 1-megabyte files.
#   logger = Logger.new('t.log', 5, 10485760) # Five 10-megabyte files.
#
# For these examples, suppose:
#
#   logger = Logger.new('t.log', 3)
#
# Logging begins in the new log file, +t.log+;
# the log file is "full" and ready for rotation
# when a new entry would cause its size to exceed +shift_size+.
#
# The first time +t.log+ is full:
#
# - +t.log+ is closed and renamed to +t.log.0+.
# - A new file +t.log+ is opened.
#
# The second time +t.log+ is full:
#
# - +t.log.0 is renamed as +t.log.1+.
# - +t.log+ is closed and renamed to +t.log.0+.
# - A new file +t.log+ is opened.
#
# Each subsequent time that +t.log+ is full,
# the log files are rotated:
#
# - +t.log.1+ is removed.
# - +t.log.0 is renamed as +t.log.1+.
# - +t.log+ is closed and renamed to +t.log.0+.
# - A new file +t.log+ is opened.
#
# === Periodic Rotation
#
# For periodic rotation, call Logger.new with:
#
# - Argument +logdev+ as a file path.
# - Argument +shift_age+ as a string period indicator.
#
# Examples:
#
#   logger = Logger.new('t.log', 'daily')   # Rotate log files daily.
#   logger = Logger.new('t.log', 'weekly')  # Rotate log files weekly.
#   logger = Logger.new('t.log', 'monthly') # Rotate log files monthly.
#
# Example:
#
#   logger = Logger.new('t.log', 'daily')
#
# When the given period expires:
#
# - The base log file, +t.log+ is closed and renamed
#   with a date-based suffix such as +t.log.20220509+.
# - A new log file +t.log+ is opened.
# - Nothing is removed.
#
# The default format for the suffix is <tt>'%Y%m%d'</tt>,
# which produces a suffix similar to the one above.
# You can set a different format using create-time option
# +shift_period_suffix+;
# see details and suggestions at
# {Time#strftime}[https://docs.ruby-lang.org/en/master/Time.html#method-i-strftime].
#
# source://logger//lib/logger/version.rb#3
class Logger
  include ::Logger::Severity

  # :call-seq:
  #    Logger.new(logdev, shift_age = 0, shift_size = 1048576, **options)
  #
  # With the single argument +logdev+,
  # returns a new logger with all default options:
  #
  #   Logger.new('t.log') # => #<Logger:0x000001e685dc6ac8>
  #
  # Argument +logdev+ must be one of:
  #
  # - A string filepath: entries are to be written
  #   to the file at that path; if the file at that path exists,
  #   new entries are appended.
  # - An IO stream (typically +$stdout+, +$stderr+. or an open file):
  #   entries are to be written to the given stream.
  # - +nil+ or +File::NULL+: no entries are to be written.
  #
  # Examples:
  #
  #   Logger.new('t.log')
  #   Logger.new($stdout)
  #
  # The keyword options are:
  #
  # - +level+: sets the log level; default value is Logger::DEBUG.
  #   See {Log Level}[rdoc-ref:Logger@Log+Level]:
  #
  #     Logger.new('t.log', level: Logger::ERROR)
  #
  # - +progname+: sets the default program name; default is +nil+.
  #   See {Program Name}[rdoc-ref:Logger@Program+Name]:
  #
  #     Logger.new('t.log', progname: 'mung')
  #
  # - +formatter+: sets the entry formatter; default is +nil+.
  #   See {formatter=}[Logger.html#attribute-i-formatter].
  # - +datetime_format+: sets the format for entry timestamp;
  #   default is +nil+.
  #   See #datetime_format=.
  # - +binmode+: sets whether the logger writes in binary mode;
  #   default is +false+.
  # - +shift_period_suffix+: sets the format for the filename suffix
  #   for periodic log file rotation; default is <tt>'%Y%m%d'</tt>.
  #   See {Periodic Rotation}[rdoc-ref:Logger@Periodic+Rotation].
  # - +reraise_write_errors+: An array of exception classes, which will
  #   be reraised if there is an error when writing to the log device.
  #   The default is to swallow all exceptions raised.
  #
  # @return [Logger] a new instance of Logger
  #
  # source://logger//lib/logger.rb#581
  def initialize(logdev, shift_age = T.unsafe(nil), shift_size = T.unsafe(nil), level: T.unsafe(nil), progname: T.unsafe(nil), formatter: T.unsafe(nil), datetime_format: T.unsafe(nil), binmode: T.unsafe(nil), shift_period_suffix: T.unsafe(nil), reraise_write_errors: T.unsafe(nil)); end

  # Writes the given +msg+ to the log with no formatting;
  # returns the number of characters written,
  # or +nil+ if no log device exists:
  #
  #   logger = Logger.new($stdout)
  #   logger << 'My message.' # => 10
  #
  # Output:
  #
  #   My message.
  #
  # source://logger//lib/logger.rb#689
  def <<(msg); end

  # Creates a log entry, which may or may not be written to the log,
  # depending on the entry's severity and on the log level.
  # See {Log Level}[rdoc-ref:Logger@Log+Level]
  # and {Entries}[rdoc-ref:Logger@Entries] for details.
  #
  # Examples:
  #
  #   logger = Logger.new($stdout, progname: 'mung')
  #   logger.add(Logger::INFO)
  #   logger.add(Logger::ERROR, 'No good')
  #   logger.add(Logger::ERROR, 'No good', 'gnum')
  #
  # Output:
  #
  #   I, [2022-05-12T16:25:31.469726 #36328]  INFO -- mung: mung
  #   E, [2022-05-12T16:25:55.349414 #36328] ERROR -- mung: No good
  #   E, [2022-05-12T16:26:35.841134 #36328] ERROR -- gnum: No good
  #
  # These convenience methods have implicit severity:
  #
  # - #debug.
  # - #info.
  # - #warn.
  # - #error.
  # - #fatal.
  # - #unknown.
  #
  # source://logger//lib/logger.rb#656
  def add(severity, message = T.unsafe(nil), progname = T.unsafe(nil)); end

  # Closes the logger; returns +nil+:
  #
  #   logger = Logger.new('t.log')
  #   logger.close       # => nil
  #   logger.info('foo') # Prints "log writing failed. closed stream"
  #
  # Related: Logger#reopen.
  #
  # source://logger//lib/logger.rb#736
  def close; end

  # Returns the date-time format; see #datetime_format=.
  #
  # source://logger//lib/logger.rb#438
  def datetime_format; end

  # Sets the date-time format.
  #
  # Argument +datetime_format+ should be either of these:
  #
  # - A string suitable for use as a format for method
  #   {Time#strftime}[https://docs.ruby-lang.org/en/master/Time.html#method-i-strftime].
  # - +nil+: the logger uses <tt>'%Y-%m-%dT%H:%M:%S.%6N'</tt>.
  #
  # source://logger//lib/logger.rb#432
  def datetime_format=(datetime_format); end

  # Equivalent to calling #add with severity <tt>Logger::DEBUG</tt>.
  #
  # source://logger//lib/logger.rb#695
  def debug(progname = T.unsafe(nil), &block); end

  # Sets the log level to Logger::DEBUG.
  # See {Log Level}[rdoc-ref:Logger@Log+Level].
  #
  # source://logger//lib/logger.rb#487
  def debug!; end

  # Returns +true+ if the log level allows entries with severity
  # Logger::DEBUG to be written, +false+ otherwise.
  # See {Log Level}[rdoc-ref:Logger@Log+Level].
  #
  # @return [Boolean]
  #
  # source://logger//lib/logger.rb#482
  def debug?; end

  # Equivalent to calling #add with severity <tt>Logger::ERROR</tt>.
  #
  # source://logger//lib/logger.rb#713
  def error(progname = T.unsafe(nil), &block); end

  # Sets the log level to Logger::ERROR.
  # See {Log Level}[rdoc-ref:Logger@Log+Level].
  #
  # source://logger//lib/logger.rb#520
  def error!; end

  # Returns +true+ if the log level allows entries with severity
  # Logger::ERROR to be written, +false+ otherwise.
  # See {Log Level}[rdoc-ref:Logger@Log+Level].
  #
  # @return [Boolean]
  #
  # source://logger//lib/logger.rb#515
  def error?; end

  # Equivalent to calling #add with severity <tt>Logger::FATAL</tt>.
  #
  # source://logger//lib/logger.rb#719
  def fatal(progname = T.unsafe(nil), &block); end

  # Sets the log level to Logger::FATAL.
  # See {Log Level}[rdoc-ref:Logger@Log+Level].
  #
  # source://logger//lib/logger.rb#531
  def fatal!; end

  # Returns +true+ if the log level allows entries with severity
  # Logger::FATAL to be written, +false+ otherwise.
  # See {Log Level}[rdoc-ref:Logger@Log+Level].
  #
  # @return [Boolean]
  #
  # source://logger//lib/logger.rb#526
  def fatal?; end

  # Sets or retrieves the logger entry formatter proc.
  #
  # When +formatter+ is +nil+, the logger uses Logger::Formatter.
  #
  # When +formatter+ is a proc, a new entry is formatted by the proc,
  # which is called with four arguments:
  #
  # - +severity+: The severity of the entry.
  # - +time+: A Time object representing the entry's timestamp.
  # - +progname+: The program name for the entry.
  # - +msg+: The message for the entry (string or string-convertible object).
  #
  # The proc should return a string containing the formatted entry.
  #
  # This custom formatter uses
  # {String#dump}[https://docs.ruby-lang.org/en/master/String.html#method-i-dump]
  # to escape the message string:
  #
  #   logger = Logger.new($stdout, progname: 'mung')
  #   original_formatter = logger.formatter || Logger::Formatter.new
  #   logger.formatter = proc { |severity, time, progname, msg|
  #     original_formatter.call(severity, time, progname, msg.dump)
  #   }
  #   logger.add(Logger::INFO, "hello \n ''")
  #   logger.add(Logger::INFO, "\f\x00\xff\\\"")
  #
  # Output:
  #
  #   I, [2022-05-13T13:16:29.637488 #8492]  INFO -- mung: "hello \n ''"
  #   I, [2022-05-13T13:16:29.637610 #8492]  INFO -- mung: "\f\x00\xFF\\\""
  #
  # source://logger//lib/logger.rb#473
  def formatter; end

  # Sets or retrieves the logger entry formatter proc.
  #
  # When +formatter+ is +nil+, the logger uses Logger::Formatter.
  #
  # When +formatter+ is a proc, a new entry is formatted by the proc,
  # which is called with four arguments:
  #
  # - +severity+: The severity of the entry.
  # - +time+: A Time object representing the entry's timestamp.
  # - +progname+: The program name for the entry.
  # - +msg+: The message for the entry (string or string-convertible object).
  #
  # The proc should return a string containing the formatted entry.
  #
  # This custom formatter uses
  # {String#dump}[https://docs.ruby-lang.org/en/master/String.html#method-i-dump]
  # to escape the message string:
  #
  #   logger = Logger.new($stdout, progname: 'mung')
  #   original_formatter = logger.formatter || Logger::Formatter.new
  #   logger.formatter = proc { |severity, time, progname, msg|
  #     original_formatter.call(severity, time, progname, msg.dump)
  #   }
  #   logger.add(Logger::INFO, "hello \n ''")
  #   logger.add(Logger::INFO, "\f\x00\xff\\\"")
  #
  # Output:
  #
  #   I, [2022-05-13T13:16:29.637488 #8492]  INFO -- mung: "hello \n ''"
  #   I, [2022-05-13T13:16:29.637610 #8492]  INFO -- mung: "\f\x00\xFF\\\""
  #
  # source://logger//lib/logger.rb#473
  def formatter=(_arg0); end

  # Equivalent to calling #add with severity <tt>Logger::INFO</tt>.
  #
  # source://logger//lib/logger.rb#701
  def info(progname = T.unsafe(nil), &block); end

  # Sets the log level to Logger::INFO.
  # See {Log Level}[rdoc-ref:Logger@Log+Level].
  #
  # source://logger//lib/logger.rb#498
  def info!; end

  # Returns +true+ if the log level allows entries with severity
  # Logger::INFO to be written, +false+ otherwise.
  # See {Log Level}[rdoc-ref:Logger@Log+Level].
  #
  # @return [Boolean]
  #
  # source://logger//lib/logger.rb#493
  def info?; end

  # Logging severity threshold (e.g. <tt>Logger::INFO</tt>).
  #
  # source://logger//lib/logger.rb#383
  def level; end

  # Sets the log level; returns +severity+.
  # See {Log Level}[rdoc-ref:Logger@Log+Level].
  #
  # Argument +severity+ may be an integer, a string, or a symbol:
  #
  #   logger.level = Logger::ERROR # => 3
  #   logger.level = 3             # => 3
  #   logger.level = 'error'       # => "error"
  #   logger.level = :error        # => :error
  #
  # Logger#sev_threshold= is an alias for Logger#level=.
  #
  # source://logger//lib/logger.rb#399
  def level=(severity); end

  # Creates a log entry, which may or may not be written to the log,
  # depending on the entry's severity and on the log level.
  # See {Log Level}[rdoc-ref:Logger@Log+Level]
  # and {Entries}[rdoc-ref:Logger@Entries] for details.
  #
  # Examples:
  #
  #   logger = Logger.new($stdout, progname: 'mung')
  #   logger.add(Logger::INFO)
  #   logger.add(Logger::ERROR, 'No good')
  #   logger.add(Logger::ERROR, 'No good', 'gnum')
  #
  # Output:
  #
  #   I, [2022-05-12T16:25:31.469726 #36328]  INFO -- mung: mung
  #   E, [2022-05-12T16:25:55.349414 #36328] ERROR -- mung: No good
  #   E, [2022-05-12T16:26:35.841134 #36328] ERROR -- gnum: No good
  #
  # These convenience methods have implicit severity:
  #
  # - #debug.
  # - #info.
  # - #warn.
  # - #error.
  # - #fatal.
  # - #unknown.
  #
  # source://logger//lib/logger.rb#676
  def log(severity, message = T.unsafe(nil), progname = T.unsafe(nil)); end

  # Program name to include in log messages.
  #
  # source://logger//lib/logger.rb#422
  def progname; end

  # Program name to include in log messages.
  #
  # source://logger//lib/logger.rb#422
  def progname=(_arg0); end

  # Sets the logger's output stream:
  #
  # - If +logdev+ is +nil+, reopens the current output stream.
  # - If +logdev+ is a filepath, opens the indicated file for append.
  # - If +logdev+ is an IO stream
  #   (usually <tt>$stdout</tt>, <tt>$stderr</tt>, or an open File object),
  #   opens the stream for append.
  #
  # Example:
  #
  #   logger = Logger.new('t.log')
  #   logger.add(Logger::ERROR, 'one')
  #   logger.close
  #   logger.add(Logger::ERROR, 'two') # Prints 'log writing failed. closed stream'
  #   logger.reopen
  #   logger.add(Logger::ERROR, 'three')
  #   logger.close
  #   File.readlines('t.log')
  #   # =>
  #   # ["# Logfile created on 2022-05-12 14:21:19 -0500 by logger.rb/v1.5.0\n",
  #   #  "E, [2022-05-12T14:21:27.596726 #22428] ERROR -- : one\n",
  #   #  "E, [2022-05-12T14:23:05.847241 #22428] ERROR -- : three\n"]
  #
  # source://logger//lib/logger.rb#624
  def reopen(logdev = T.unsafe(nil)); end

  # Logging severity threshold (e.g. <tt>Logger::INFO</tt>).
  #
  # source://logger//lib/logger.rb#475
  def sev_threshold; end

  # Sets the log level; returns +severity+.
  # See {Log Level}[rdoc-ref:Logger@Log+Level].
  #
  # Argument +severity+ may be an integer, a string, or a symbol:
  #
  #   logger.level = Logger::ERROR # => 3
  #   logger.level = 3             # => 3
  #   logger.level = 'error'       # => "error"
  #   logger.level = :error        # => :error
  #
  # Logger#sev_threshold= is an alias for Logger#level=.
  #
  # source://logger//lib/logger.rb#476
  def sev_threshold=(severity); end

  # Equivalent to calling #add with severity <tt>Logger::UNKNOWN</tt>.
  #
  # source://logger//lib/logger.rb#725
  def unknown(progname = T.unsafe(nil), &block); end

  # Equivalent to calling #add with severity <tt>Logger::WARN</tt>.
  #
  # source://logger//lib/logger.rb#707
  def warn(progname = T.unsafe(nil), &block); end

  # Sets the log level to Logger::WARN.
  # See {Log Level}[rdoc-ref:Logger@Log+Level].
  #
  # source://logger//lib/logger.rb#509
  def warn!; end

  # Returns +true+ if the log level allows entries with severity
  # Logger::WARN to be written, +false+ otherwise.
  # See {Log Level}[rdoc-ref:Logger@Log+Level].
  #
  # @return [Boolean]
  #
  # source://logger//lib/logger.rb#504
  def warn?; end

  # Adjust the log level during the block execution for the current Fiber only
  #
  #   logger.with_level(:debug) do
  #     logger.debug { "Hello" }
  #   end
  #
  # source://logger//lib/logger.rb#408
  def with_level(severity); end

  private

  # source://logger//lib/logger.rb#758
  def format_message(severity, datetime, progname, msg); end

  # source://logger//lib/logger.rb#745
  def format_severity(severity); end

  # source://logger//lib/logger.rb#754
  def level_key; end

  # Guarantee the existence of this ivar even when subclasses don't call the superclass constructor.
  #
  # source://logger//lib/logger.rb#750
  def level_override; end
end

# Default formatter for log messages.
#
# source://logger//lib/logger/formatter.rb#5
class Logger::Formatter
  # @return [Formatter] a new instance of Formatter
  #
  # source://logger//lib/logger/formatter.rb#11
  def initialize; end

  # source://logger//lib/logger/formatter.rb#15
  def call(severity, time, progname, msg); end

  # Returns the value of attribute datetime_format.
  #
  # source://logger//lib/logger/formatter.rb#9
  def datetime_format; end

  # Sets the attribute datetime_format
  #
  # @param value the value to set the attribute datetime_format to.
  #
  # source://logger//lib/logger/formatter.rb#9
  def datetime_format=(_arg0); end

  private

  # source://logger//lib/logger/formatter.rb#21
  def format_datetime(time); end

  # source://logger//lib/logger/formatter.rb#25
  def msg2str(msg); end
end

# source://logger//lib/logger/formatter.rb#7
Logger::Formatter::DatetimeFormat = T.let(T.unsafe(nil), String)

# source://logger//lib/logger/formatter.rb#6
Logger::Formatter::Format = T.let(T.unsafe(nil), String)

# Device used for logging messages.
#
# source://logger//lib/logger/log_device.rb#7
class Logger::LogDevice
  include ::Logger::Period
  include ::MonitorMixin

  # @return [LogDevice] a new instance of LogDevice
  #
  # source://logger//lib/logger/log_device.rb#14
  def initialize(log = T.unsafe(nil), shift_age: T.unsafe(nil), shift_size: T.unsafe(nil), shift_period_suffix: T.unsafe(nil), binmode: T.unsafe(nil), reraise_write_errors: T.unsafe(nil)); end

  # source://logger//lib/logger/log_device.rb#43
  def close; end

  # Returns the value of attribute dev.
  #
  # source://logger//lib/logger/log_device.rb#10
  def dev; end

  # Returns the value of attribute filename.
  #
  # source://logger//lib/logger/log_device.rb#11
  def filename; end

  # source://logger//lib/logger/log_device.rb#53
  def reopen(log = T.unsafe(nil)); end

  # source://logger//lib/logger/log_device.rb#32
  def write(message); end

  private

  # source://logger//lib/logger/log_device.rb#148
  def add_log_header(file); end

  # source://logger//lib/logger/log_device.rb#154
  def check_shift_log; end

  # source://logger//lib/logger/log_device.rb#124
  def create_logfile(filename); end

  # source://logger//lib/logger/log_device.rb#96
  def fixup_mode(dev, filename); end

  # source://logger//lib/logger/log_device.rb#140
  def handle_write_errors(mesg); end

  # source://logger//lib/logger/log_device.rb#169
  def lock_shift_log; end

  # source://logger//lib/logger/log_device.rb#111
  def open_logfile(filename); end

  # source://logger//lib/logger/log_device.rb#81
  def set_dev(log); end

  # source://logger//lib/logger/log_device.rb#198
  def shift_log_age; end

  # source://logger//lib/logger/log_device.rb#210
  def shift_log_period(period_end); end
end

# :stopdoc:
#
# source://logger//lib/logger/log_device.rb#72
Logger::LogDevice::MODE = T.let(T.unsafe(nil), Integer)

# source://logger//lib/logger/log_device.rb#79
Logger::LogDevice::MODE_TO_CREATE = T.let(T.unsafe(nil), Integer)

# source://logger//lib/logger/log_device.rb#75
Logger::LogDevice::MODE_TO_OPEN = T.let(T.unsafe(nil), Integer)

# source://logger//lib/logger/period.rb#4
module Logger::Period
  private

  # source://logger//lib/logger/period.rb#9
  def next_rotate_time(now, shift_age); end

  # source://logger//lib/logger/period.rb#31
  def previous_period_end(now, shift_age); end

  class << self
    # source://logger//lib/logger/period.rb#9
    def next_rotate_time(now, shift_age); end

    # source://logger//lib/logger/period.rb#31
    def previous_period_end(now, shift_age); end
  end
end

# source://logger//lib/logger/period.rb#7
Logger::Period::SiD = T.let(T.unsafe(nil), Integer)

# \Severity label for logging (max 5 chars).
#
# source://logger//lib/logger.rb#743
Logger::SEV_LABEL = T.let(T.unsafe(nil), Array)

# Logging severity.
#
# source://logger//lib/logger/severity.rb#5
module Logger::Severity
  class << self
    # source://logger//lib/logger/severity.rb#29
    def coerce(severity); end
  end
end

# source://logger//lib/logger/severity.rb#19
Logger::Severity::LEVELS = T.let(T.unsafe(nil), Hash)
