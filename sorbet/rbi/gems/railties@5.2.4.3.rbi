# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `railties` gem.
# Please instead update this file by running `tapioca generate`.

# typed: true

module Rails
  extend(::ActiveSupport::Autoload)

  class << self
    def app_class; end
    def app_class=(_); end
    def application; end
    def application=(_); end
    def backtrace_cleaner; end
    def cache; end
    def cache=(_); end
    def configuration; end
    def env; end
    def env=(environment); end
    def gem_version; end
    def groups(*groups); end
    def initialize!(*args, &block); end
    def initialized?(*args, &block); end
    def logger; end
    def logger=(_); end
    def public_path; end
    def root; end
    def version; end
  end
end

class Rails::Application < ::Rails::Engine
  def initialize(initial_variable_values = _, &block); end

  def asset_precompiled?(logical_path); end
  def assets; end
  def assets=(_); end
  def assets_manifest; end
  def assets_manifest=(_); end
  def build_middleware_stack; end
  def config; end
  def config=(configuration); end
  def config_for(name, env: _); end
  def console(&blk); end
  def credentials; end
  def default_url_options(*args, &block); end
  def default_url_options=(arg); end
  def encrypted(path, key_path: _, env_key: _); end
  def env_config; end
  def executor; end
  def generators(&blk); end
  def helpers_paths; end
  def initialize!(group = _); end
  def initialized?; end
  def initializer(name, opts = _, &block); end
  def initializers; end
  def isolate_namespace(mod); end
  def key_generator; end
  def message_verifier(verifier_name); end
  def migration_railties; end
  def precompiled_assets(clear_cache = _); end
  def rake_tasks(&block); end
  def reload_routes!; end
  def reloader; end
  def reloaders; end
  def require_environment!; end
  def routes_reloader; end
  def run_load_hooks!; end
  def runner(&blk); end
  def sandbox; end
  def sandbox=(_); end
  def sandbox?; end
  def secret_key_base; end
  def secrets; end
  def secrets=(secrets); end
  def to_app; end
  def watchable_args; end

  protected

  def default_middleware_stack; end
  def ordered_railties; end
  def railties_initializers(current); end
  def run_console_blocks(app); end
  def run_generators_blocks(app); end
  def run_runner_blocks(app); end
  def run_tasks_blocks(app); end
  def validate_secret_key_base(secret_key_base); end

  private

  def build_middleware; end
  def build_request(env); end
  def generate_development_secret; end

  class << self
    def add_lib_to_load_path!(root); end
    def create(initial_variable_values = _, &block); end
    def find_root(from); end
    def inherited(base); end
    def instance; end
  end
end

module Rails::Application::Bootstrap
  include(::Rails::Initializable)
  extend(::Rails::Initializable::ClassMethods)
end

class Rails::Application::Configuration < ::Rails::Engine::Configuration
  def initialize(*_); end

  def allow_concurrency; end
  def allow_concurrency=(_); end
  def annotations; end
  def api_only; end
  def api_only=(value); end
  def asset_host; end
  def asset_host=(_); end
  def autoflush_log; end
  def autoflush_log=(_); end
  def beginning_of_week; end
  def beginning_of_week=(_); end
  def cache_classes; end
  def cache_classes=(_); end
  def cache_store; end
  def cache_store=(_); end
  def colorize_logging; end
  def colorize_logging=(val); end
  def consider_all_requests_local; end
  def consider_all_requests_local=(_); end
  def console; end
  def console=(_); end
  def content_security_policy(&block); end
  def content_security_policy_nonce_generator; end
  def content_security_policy_nonce_generator=(_); end
  def content_security_policy_report_only; end
  def content_security_policy_report_only=(_); end
  def database_configuration; end
  def debug_exception_response_format; end
  def debug_exception_response_format=(value); end
  def eager_load; end
  def eager_load=(_); end
  def enable_dependency_loading; end
  def enable_dependency_loading=(_); end
  def encoding; end
  def encoding=(value); end
  def exceptions_app; end
  def exceptions_app=(_); end
  def file_watcher; end
  def file_watcher=(_); end
  def filter_parameters; end
  def filter_parameters=(_); end
  def filter_redirect; end
  def filter_redirect=(_); end
  def force_ssl; end
  def force_ssl=(_); end
  def helpers_paths; end
  def helpers_paths=(_); end
  def load_defaults(target_version); end
  def loaded_config_version; end
  def log_formatter; end
  def log_formatter=(_); end
  def log_level; end
  def log_level=(_); end
  def log_tags; end
  def log_tags=(_); end
  def logger; end
  def logger=(_); end
  def paths; end
  def public_file_server; end
  def public_file_server=(_); end
  def railties_order; end
  def railties_order=(_); end
  def read_encrypted_secrets; end
  def read_encrypted_secrets=(_); end
  def relative_url_root; end
  def relative_url_root=(_); end
  def reload_classes_only_on_change; end
  def reload_classes_only_on_change=(_); end
  def require_master_key; end
  def require_master_key=(_); end
  def secret_key_base; end
  def secret_key_base=(_); end
  def secret_token; end
  def secret_token=(_); end
  def session_options; end
  def session_options=(_); end
  def session_store(new_session_store = _, **options); end
  def session_store?; end
  def ssl_options; end
  def ssl_options=(_); end
  def time_zone; end
  def time_zone=(_); end
  def x; end
  def x=(_); end
end

class Rails::Application::Configuration::Custom
  def initialize; end

  def method_missing(method, *args); end

  private

  def respond_to_missing?(symbol, *_); end
end

class Rails::Application::DefaultMiddlewareStack
  def initialize(app, config, paths); end

  def app; end
  def build_stack; end
  def config; end
  def paths; end

  private

  def load_rack_cache; end
  def show_exceptions_app; end
end

module Rails::Application::Finisher
  include(::Rails::Initializable)
  extend(::Rails::Initializable::ClassMethods)
end

module Rails::Application::Finisher::InterlockHook
  class << self
    def complete(_state); end
    def run; end
  end
end

class Rails::Application::Finisher::MutexHook
  def initialize(mutex = _); end

  def complete(_state); end
  def run; end
end

Rails::Application::INITIAL_VARIABLES = T.let(T.unsafe(nil), Array)

class Rails::Application::RoutesReloader
  def initialize; end

  def eager_load; end
  def eager_load=(_); end
  def execute(*args, &block); end
  def execute_if_updated(*args, &block); end
  def paths; end
  def reload!; end
  def route_sets; end
  def updated?(*args, &block); end

  private

  def clear!; end
  def finalize!; end
  def load_paths; end
  def revert; end
  def updater; end
end

class Rails::ApplicationController < ::ActionController::Base

  private

  def _layout(formats); end
  def disable_content_security_policy_nonce!; end
  def local_request?; end
  def require_local!; end

  class << self
    def __callbacks; end
    def _helpers; end
    def _layout; end
    def _layout_conditions; end
    def _view_paths; end
    def middleware_stack; end
  end
end

module Rails::Configuration
end

class Rails::Configuration::Generators
  def initialize; end

  def aliases; end
  def aliases=(_); end
  def api_only; end
  def api_only=(_); end
  def colorize_logging; end
  def colorize_logging=(_); end
  def fallbacks; end
  def fallbacks=(_); end
  def hidden_namespaces; end
  def hide_namespace(namespace); end
  def method_missing(method, *args); end
  def options; end
  def options=(_); end
  def templates; end
  def templates=(_); end

  private

  def initialize_copy(source); end
end

class Rails::Configuration::MiddlewareStackProxy
  def initialize(operations = _, delete_operations = _); end

  def +(other); end
  def delete(*args, &block); end
  def insert(*args, &block); end
  def insert_after(*args, &block); end
  def insert_before(*args, &block); end
  def merge_into(other); end
  def swap(*args, &block); end
  def unshift(*args, &block); end
  def use(*args, &block); end

  protected

  def delete_operations; end
  def operations; end
end

class Rails::Engine < ::Rails::Railtie
  def initialize; end

  def app; end
  def call(env); end
  def config; end
  def eager_load!; end
  def endpoint; end
  def engine_name(*args, &block); end
  def env_config; end
  def helpers; end
  def helpers_paths; end
  def isolated?(*args, &block); end
  def load_console(app = _); end
  def load_generators(app = _); end
  def load_runner(app = _); end
  def load_seed; end
  def load_tasks(app = _); end
  def middleware(*args, &block); end
  def paths(*args, &block); end
  def railties; end
  def root(*args, &block); end
  def routes(&block); end
  def routes?; end

  protected

  def run_tasks_blocks(*_); end

  private

  def _all_autoload_once_paths; end
  def _all_autoload_paths; end
  def _all_load_paths; end
  def build_middleware; end
  def build_request(env); end
  def default_middleware_stack; end
  def has_migrations?; end
  def load_config_initializer(initializer); end
  def with_inline_jobs; end

  class << self
    def called_from; end
    def called_from=(_); end
    def eager_load!(*args, &block); end
    def endpoint(endpoint = _); end
    def engine_name(name = _); end
    def find(path); end
    def find_root(from); end
    def find_root_with_flag(flag, root_path, default = _); end
    def inherited(base); end
    def isolate_namespace(mod); end
    def isolated; end
    def isolated=(_); end
    def isolated?; end
  end
end

class Rails::Engine::Configuration < ::Rails::Railtie::Configuration
  def initialize(root = _); end

  def autoload_once_paths; end
  def autoload_once_paths=(_); end
  def autoload_paths; end
  def autoload_paths=(_); end
  def eager_load_paths; end
  def eager_load_paths=(_); end
  def generators; end
  def middleware; end
  def middleware=(_); end
  def paths; end
  def root; end
  def root=(value); end
end

class Rails::Engine::Railties
  include(::Enumerable)

  def initialize; end

  def -(others); end
  def _all; end
  def each(*args, &block); end
end

module Rails::Info
  def properties; end
  def properties=(obj); end

  class << self
    def inspect; end
    def properties; end
    def properties=(obj); end
    def property(name, value = _); end
    def to_html; end
    def to_s; end
  end
end

class Rails::InfoController < ::Rails::ApplicationController
  def index; end
  def properties; end
  def routes; end

  protected

  def _layout_from_proc; end

  private

  def _layout(formats); end
  def match_route; end
  def with_leading_slash(path); end

  class << self
    def __callbacks; end
    def _helpers; end
    def _layout; end
    def _layout_conditions; end
    def _view_paths; end
    def middleware_stack; end
  end
end

module Rails::Initializable
  mixes_in_class_methods(::Rails::Initializable::ClassMethods)

  def initializers; end
  def run_initializers(group = _, *args); end

  class << self
    def included(base); end
  end
end

module Rails::Initializable::ClassMethods
  def initializer(name, opts = _, &blk); end
  def initializers; end
  def initializers_chain; end
  def initializers_for(binding); end
end

class Rails::Initializable::Collection < ::Array
  include(::TSort)

  def +(other); end
  def tsort_each_child(initializer, &block); end
  def tsort_each_node; end
end

class Rails::Initializable::Initializer
  def initialize(name, context, options, &block); end

  def after; end
  def before; end
  def belongs_to?(group); end
  def bind(context); end
  def block; end
  def context_class; end
  def name; end
  def run(*args); end
end

module Rails::LineFiltering
  def run(reporter, options = _); end
end

class Rails::MailersController < ::Rails::ApplicationController
  def index; end
  def preview; end

  private

  def _layout(formats); end
  def find_part(format); end
  def find_preferred_part(*formats); end
  def find_preview; end
  def locale_query(locale); end
  def part_query(mime_type); end
  def set_locale; end
  def show_previews?; end

  class << self
    def __callbacks; end
    def _helper_methods; end
    def _helpers; end
    def _view_paths; end
    def middleware_stack; end
  end
end

module Rails::Paths
end

class Rails::Paths::Path
  include(::Enumerable)

  def initialize(root, current, paths, options = _); end

  def <<(path); end
  def absolute_current; end
  def autoload!; end
  def autoload?; end
  def autoload_once!; end
  def autoload_once?; end
  def children; end
  def concat(paths); end
  def each(&block); end
  def eager_load!; end
  def eager_load?; end
  def existent; end
  def existent_directories; end
  def expanded; end
  def extensions; end
  def first; end
  def glob; end
  def glob=(_); end
  def last; end
  def load_path!; end
  def load_path?; end
  def push(path); end
  def skip_autoload!; end
  def skip_autoload_once!; end
  def skip_eager_load!; end
  def skip_load_path!; end
  def to_a; end
  def to_ary; end
  def unshift(*paths); end
end

class Rails::Paths::Root
  def initialize(path); end

  def [](path); end
  def []=(path, value); end
  def add(path, options = _); end
  def all_paths; end
  def autoload_once; end
  def autoload_paths; end
  def eager_load; end
  def keys; end
  def load_paths; end
  def path; end
  def path=(_); end
  def values; end
  def values_at(*list); end

  private

  def filter_by(&block); end
end

module Rails::Rack
end

class Rails::Rack::Logger < ::ActiveSupport::LogSubscriber
  def initialize(app, taggers = _); end

  def call(env); end

  private

  def call_app(request, env); end
  def compute_tags(request); end
  def finish(request); end
  def logger; end
  def started_request_message(request); end
end

class Rails::Railtie
  include(::Rails::Initializable)
  extend(::Rails::Initializable::ClassMethods)

  def initialize; end

  def config; end
  def configure(&block); end
  def railtie_name(*args, &block); end
  def railtie_namespace; end

  protected

  def run_console_blocks(app); end
  def run_generators_blocks(app); end
  def run_runner_blocks(app); end
  def run_tasks_blocks(app); end

  private

  def each_registered_block(type, &block); end

  class << self
    def abstract_railtie?; end
    def config(*args, &block); end
    def configure(&block); end
    def console(&blk); end
    def generators(&blk); end
    def inherited(base); end
    def instance; end
    def railtie_name(name = _); end
    def rake_tasks(&blk); end
    def runner(&blk); end
    def subclasses; end

    private

    def generate_railtie_name(string); end
    def method_missing(name, *args, &block); end
    def register_block_for(type, &blk); end
    def respond_to_missing?(name, _); end
  end
end

Rails::Railtie::ABSTRACT_RAILTIES = T.let(T.unsafe(nil), Array)

class Rails::Railtie::Configuration
  def initialize; end

  def after_initialize(&block); end
  def app_generators; end
  def app_middleware; end
  def before_configuration(&block); end
  def before_eager_load(&block); end
  def before_initialize(&block); end
  def eager_load_namespaces; end
  def respond_to?(name, include_private = _); end
  def to_prepare(&blk); end
  def to_prepare_blocks; end
  def watchable_dirs; end
  def watchable_files; end

  private

  def method_missing(name, *args, &blk); end

  class << self
    def eager_load_namespaces; end
  end
end

class Rails::Secrets
  class << self
    def decrypt(data); end
    def encrypt(data); end
    def key; end
    def parse(paths, env:); end
    def read; end
    def read_for_editing(&block); end
    def root=(_); end
    def write(contents); end

    private

    def encryptor; end
    def handle_missing_key; end
    def key_path; end
    def path; end
    def preprocess(path); end
    def read_key_file; end
    def writing(contents); end
  end
end

class Rails::Secrets::MissingKeyError < ::RuntimeError
  def initialize; end
end

module Rails::TestUnit
end

class Rails::TestUnit::CompositeFilter
  def initialize(runnable, filter, patterns); end

  def ===(method); end
  def named_filter; end

  private

  def derive_line_filters(patterns); end
  def derive_named_filter(filter); end
end

class Rails::TestUnit::Filter
  def initialize(runnable, file, line); end

  def ===(method); end

  private

  def definition_for(method); end
end

class Rails::TestUnit::Runner
  def filters; end

  class << self
    def attach_before_load_options(opts); end
    def compose_filter(runnable, filter); end
    def filters; end
    def load_tests(argv); end
    def parse_options(argv); end
    def rake_run(argv = _); end
    def run(argv = _); end

    private

    def extract_filters(argv); end
  end
end

class Rails::TestUnitRailtie < ::Rails::Railtie
end

module Rails::VERSION
end

Rails::VERSION::MAJOR = T.let(T.unsafe(nil), Integer)

Rails::VERSION::MINOR = T.let(T.unsafe(nil), Integer)

Rails::VERSION::PRE = T.let(T.unsafe(nil), String)

Rails::VERSION::STRING = T.let(T.unsafe(nil), String)

Rails::VERSION::TINY = T.let(T.unsafe(nil), Integer)

class Rails::WelcomeController < ::Rails::ApplicationController
  def index; end

  private

  def _layout(formats); end

  class << self
    def _helpers; end
    def _layout; end
    def _layout_conditions; end
    def middleware_stack; end
  end
end

class SourceAnnotationExtractor
  def initialize(tag); end

  def display(results, options = _); end
  def extract_annotations_from(file, pattern); end
  def find(dirs); end
  def find_in(dir); end
  def tag; end

  class << self
    def enumerate(tag, options = _); end
  end
end

class SourceAnnotationExtractor::Annotation < ::Struct
  def line; end
  def line=(_); end
  def tag; end
  def tag=(_); end
  def text; end
  def text=(_); end
  def to_s(options = _); end

  class << self
    def [](*_); end
    def directories; end
    def extensions; end
    def inspect; end
    def members; end
    def new(*_); end
    def register_directories(*dirs); end
    def register_extensions(*exts, &block); end
  end
end
