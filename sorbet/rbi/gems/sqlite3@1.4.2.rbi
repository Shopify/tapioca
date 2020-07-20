# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `sqlite3` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

module SQLite3
  class << self
    def const_missing(name); end
    def libversion; end
    def sqlcipher?; end
    def threadsafe; end
    def threadsafe?; end
  end
end

class SQLite3::AbortException < ::SQLite3::Exception
end

class SQLite3::AuthorizationException < ::SQLite3::Exception
end

class SQLite3::Backup
  def initialize(_, _, _, _); end

  def finish; end
  def pagecount; end
  def remaining; end
  def step(_); end
end

class SQLite3::Blob < ::String
end

class SQLite3::BusyException < ::SQLite3::Exception
end

class SQLite3::CantOpenException < ::SQLite3::Exception
end

module SQLite3::Constants
end

module SQLite3::Constants::ColumnType
end

SQLite3::Constants::ColumnType::BLOB = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ColumnType::FLOAT = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ColumnType::INTEGER = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ColumnType::NULL = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ColumnType::TEXT = T.let(T.unsafe(nil), Integer)

module SQLite3::Constants::ErrorCode
end

SQLite3::Constants::ErrorCode::ABORT = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::AUTH = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::BUSY = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::CANTOPEN = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::CONSTRAINT = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::CORRUPT = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::DONE = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::EMPTY = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::ERROR = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::FULL = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::INTERNAL = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::INTERRUPT = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::IOERR = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::LOCKED = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::MISMATCH = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::MISUSE = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::NOLFS = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::NOMEM = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::NOTFOUND = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::OK = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::PERM = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::PROTOCOL = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::READONLY = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::ROW = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::SCHEMA = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::ErrorCode::TOOBIG = T.let(T.unsafe(nil), Integer)

module SQLite3::Constants::Open
end

SQLite3::Constants::Open::AUTOPROXY = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::CREATE = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::DELETEONCLOSE = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::EXCLUSIVE = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::FULLMUTEX = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::MAIN_DB = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::MAIN_JOURNAL = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::MASTER_JOURNAL = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::MEMORY = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::NOMUTEX = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::PRIVATECACHE = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::READONLY = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::READWRITE = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::SHAREDCACHE = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::SUBJOURNAL = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::TEMP_DB = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::TEMP_JOURNAL = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::TRANSIENT_DB = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::URI = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::Open::WAL = T.let(T.unsafe(nil), Integer)

module SQLite3::Constants::TextRep
end

SQLite3::Constants::TextRep::ANY = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::TextRep::DETERMINISTIC = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::TextRep::UTF16 = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::TextRep::UTF16BE = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::TextRep::UTF16LE = T.let(T.unsafe(nil), Integer)

SQLite3::Constants::TextRep::UTF8 = T.let(T.unsafe(nil), Integer)

class SQLite3::ConstraintException < ::SQLite3::Exception
end

class SQLite3::CorruptException < ::SQLite3::Exception
end

class SQLite3::Database
  include(::SQLite3::Pragmas)

  def initialize(file, options = _, zvfs = _); end

  def authorizer(&block); end
  def authorizer=(_); end
  def busy_handler(*_); end
  def busy_timeout(_); end
  def busy_timeout=(_); end
  def changes; end
  def close; end
  def closed?; end
  def collation(_, _); end
  def collations; end
  def commit; end
  def complete?(_); end
  def create_aggregate(name, arity, step = _, finalize = _, text_rep = _, &block); end
  def create_aggregate_handler(handler); end
  def create_function(name, arity, text_rep = _, &block); end
  def define_aggregator(name, aggregator); end
  def define_function(_); end
  def define_function_with_flags(_, _); end
  def enable_load_extension(_); end
  def encoding; end
  def errcode; end
  def errmsg; end
  def execute(sql, bind_vars = _, *args, &block); end
  def execute2(sql, *bind_vars); end
  def execute_batch(sql, bind_vars = _, *args); end
  def execute_batch2(sql, &block); end
  def extended_result_codes=(_); end
  def filename(db_name = _); end
  def get_first_row(sql, *bind_vars); end
  def get_first_value(sql, *bind_vars); end
  def interrupt; end
  def last_insert_row_id; end
  def load_extension(_); end
  def prepare(sql); end
  def query(sql, bind_vars = _, *args); end
  def readonly?; end
  def results_as_hash; end
  def results_as_hash=(_); end
  def rollback; end
  def total_changes; end
  def trace(*_); end
  def transaction(mode = _); end
  def transaction_active?; end
  def translate_from_db(types, row); end
  def translator; end
  def type_translation; end
  def type_translation=(value); end

  private

  def db_filename(_); end
  def define_aggregator2(_, _); end
  def exec_batch(_, _); end
  def make_type_translator(should_translate); end
  def open16(_); end
  def open_v2(_, _, _); end

  class << self
    def open(*_); end
    def quote(string); end
  end
end

class SQLite3::Database::FunctionProxy
  def initialize; end

  def [](key); end
  def []=(key, value); end
  def count; end
  def result; end
  def result=(_); end
  def set_error(error); end
end

SQLite3::Database::NULL_TRANSLATOR = T.let(T.unsafe(nil), Proc)

class SQLite3::EmptyException < ::SQLite3::Exception
end

class SQLite3::Exception < ::StandardError
  def code; end
end

class SQLite3::FormatException < ::SQLite3::Exception
end

class SQLite3::FullException < ::SQLite3::Exception
end

class SQLite3::IOException < ::SQLite3::Exception
end

class SQLite3::InternalException < ::SQLite3::Exception
end

class SQLite3::InterruptException < ::SQLite3::Exception
end

class SQLite3::LockedException < ::SQLite3::Exception
end

class SQLite3::MemoryException < ::SQLite3::Exception
end

class SQLite3::MismatchException < ::SQLite3::Exception
end

class SQLite3::MisuseException < ::SQLite3::Exception
end

class SQLite3::NotADatabaseException < ::SQLite3::Exception
end

class SQLite3::NotFoundException < ::SQLite3::Exception
end

class SQLite3::PermissionException < ::SQLite3::Exception
end

module SQLite3::Pragmas
  def application_id; end
  def application_id=(integer); end
  def auto_vacuum; end
  def auto_vacuum=(mode); end
  def automatic_index; end
  def automatic_index=(mode); end
  def busy_timeout; end
  def busy_timeout=(milliseconds); end
  def cache_size; end
  def cache_size=(size); end
  def cache_spill; end
  def cache_spill=(mode); end
  def case_sensitive_like=(mode); end
  def cell_size_check; end
  def cell_size_check=(mode); end
  def checkpoint_fullfsync; end
  def checkpoint_fullfsync=(mode); end
  def collation_list(&block); end
  def compile_options(&block); end
  def count_changes; end
  def count_changes=(mode); end
  def data_version; end
  def database_list(&block); end
  def default_cache_size; end
  def default_cache_size=(size); end
  def default_synchronous; end
  def default_synchronous=(mode); end
  def default_temp_store; end
  def default_temp_store=(mode); end
  def defer_foreign_keys; end
  def defer_foreign_keys=(mode); end
  def encoding; end
  def encoding=(mode); end
  def foreign_key_check(*table, &block); end
  def foreign_key_list(table, &block); end
  def foreign_keys; end
  def foreign_keys=(mode); end
  def freelist_count; end
  def full_column_names; end
  def full_column_names=(mode); end
  def fullfsync; end
  def fullfsync=(mode); end
  def get_boolean_pragma(name); end
  def get_enum_pragma(name); end
  def get_int_pragma(name); end
  def get_query_pragma(name, *parms, &block); end
  def ignore_check_constraints=(mode); end
  def incremental_vacuum(pages, &block); end
  def index_info(index, &block); end
  def index_list(table, &block); end
  def index_xinfo(index, &block); end
  def integrity_check(*num_errors, &block); end
  def journal_mode; end
  def journal_mode=(mode); end
  def journal_size_limit; end
  def journal_size_limit=(size); end
  def legacy_file_format; end
  def legacy_file_format=(mode); end
  def locking_mode; end
  def locking_mode=(mode); end
  def max_page_count; end
  def max_page_count=(size); end
  def mmap_size; end
  def mmap_size=(size); end
  def page_count; end
  def page_size; end
  def page_size=(size); end
  def parser_trace=(mode); end
  def query_only; end
  def query_only=(mode); end
  def quick_check(*num_errors, &block); end
  def read_uncommitted; end
  def read_uncommitted=(mode); end
  def recursive_triggers; end
  def recursive_triggers=(mode); end
  def reverse_unordered_selects; end
  def reverse_unordered_selects=(mode); end
  def schema_cookie; end
  def schema_cookie=(cookie); end
  def schema_version; end
  def schema_version=(version); end
  def secure_delete; end
  def secure_delete=(mode); end
  def set_boolean_pragma(name, mode); end
  def set_enum_pragma(name, mode, enums); end
  def set_int_pragma(name, value); end
  def short_column_names; end
  def short_column_names=(mode); end
  def shrink_memory; end
  def soft_heap_limit; end
  def soft_heap_limit=(mode); end
  def stats(&block); end
  def synchronous; end
  def synchronous=(mode); end
  def table_info(table); end
  def temp_store; end
  def temp_store=(mode); end
  def threads; end
  def threads=(count); end
  def user_cookie; end
  def user_cookie=(cookie); end
  def user_version; end
  def user_version=(version); end
  def vdbe_addoptrace=(mode); end
  def vdbe_debug=(mode); end
  def vdbe_listing=(mode); end
  def vdbe_trace; end
  def vdbe_trace=(mode); end
  def wal_autocheckpoint; end
  def wal_autocheckpoint=(mode); end
  def wal_checkpoint; end
  def wal_checkpoint=(mode); end
  def writable_schema=(mode); end

  private

  def tweak_default(hash); end
  def version_compare(v1, v2); end
end

SQLite3::Pragmas::AUTO_VACUUM_MODES = T.let(T.unsafe(nil), Array)

SQLite3::Pragmas::ENCODINGS = T.let(T.unsafe(nil), Array)

SQLite3::Pragmas::JOURNAL_MODES = T.let(T.unsafe(nil), Array)

SQLite3::Pragmas::LOCKING_MODES = T.let(T.unsafe(nil), Array)

SQLite3::Pragmas::SYNCHRONOUS_MODES = T.let(T.unsafe(nil), Array)

SQLite3::Pragmas::TEMP_STORE_MODES = T.let(T.unsafe(nil), Array)

SQLite3::Pragmas::WAL_CHECKPOINTS = T.let(T.unsafe(nil), Array)

class SQLite3::ProtocolException < ::SQLite3::Exception
end

class SQLite3::RangeException < ::SQLite3::Exception
end

class SQLite3::ReadOnlyException < ::SQLite3::Exception
end

class SQLite3::ResultSet
  include(::Enumerable)

  def initialize(db, stmt); end

  def close; end
  def closed?; end
  def columns; end
  def each; end
  def each_hash; end
  def eof?; end
  def next; end
  def next_hash; end
  def reset(*bind_params); end
  def types; end
end

class SQLite3::ResultSet::ArrayWithTypes < ::Array
  def types; end
  def types=(_); end
end

class SQLite3::ResultSet::ArrayWithTypesAndFields < ::Array
  def fields; end
  def fields=(_); end
  def types; end
  def types=(_); end
end

class SQLite3::ResultSet::HashWithTypesAndFields < ::Hash
  def [](key); end
  def fields; end
  def fields=(_); end
  def types; end
  def types=(_); end
end

class SQLite3::SQLException < ::SQLite3::Exception
end

SQLite3::SQLITE_VERSION = T.let(T.unsafe(nil), String)

SQLite3::SQLITE_VERSION_NUMBER = T.let(T.unsafe(nil), Integer)

class SQLite3::SchemaChangedException < ::SQLite3::Exception
end

class SQLite3::Statement
  include(::Enumerable)

  def initialize(_, _); end

  def active?; end
  def bind_param(_, _); end
  def bind_parameter_count; end
  def bind_params(*bind_vars); end
  def clear_bindings!; end
  def close; end
  def closed?; end
  def column_count; end
  def column_decltype(_); end
  def column_name(_); end
  def columns; end
  def database_name(_); end
  def done?; end
  def each; end
  def execute(*bind_vars); end
  def execute!(*bind_vars, &block); end
  def must_be_open!; end
  def remainder; end
  def reset!; end
  def step; end
  def types; end

  private

  def get_metadata; end
end

class SQLite3::TooBigException < ::SQLite3::Exception
end

class SQLite3::Translator
  def initialize; end

  def add_translator(type, &block); end
  def translate(type, value); end

  private

  def register_default_translators; end
  def type_name(type); end
end

class SQLite3::UnsupportedException < ::SQLite3::Exception
end

SQLite3::VERSION = T.let(T.unsafe(nil), String)

class SQLite3::Value
  def initialize(db, handle); end

  def handle; end
  def length(utf16 = _); end
  def null?; end
  def to_blob; end
  def to_f; end
  def to_i; end
  def to_int64; end
  def to_s(utf16 = _); end
  def type; end
end

module SQLite3::VersionProxy
end

SQLite3::VersionProxy::MAJOR = T.let(T.unsafe(nil), Integer)

SQLite3::VersionProxy::MINOR = T.let(T.unsafe(nil), Integer)

SQLite3::VersionProxy::STRING = T.let(T.unsafe(nil), String)

SQLite3::VersionProxy::TINY = T.let(T.unsafe(nil), Integer)

SQLite3::VersionProxy::VERSION = T.let(T.unsafe(nil), String)

class String
  include(::Comparable)
  include(::JSON::Ext::Generator::GeneratorMethods::String)
  extend(::JSON::Ext::Generator::GeneratorMethods::String::Extend)

  def to_blob; end
end

String::BLANK_RE = T.let(T.unsafe(nil), Regexp)

String::ENCODED_BLANKS = T.let(T.unsafe(nil), Concurrent::Map)
