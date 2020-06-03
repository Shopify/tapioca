# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   tapioca sync

# typed: true

module Rails
  extend(::ActiveSupport::Autoload)

  def self.app_class; end
  def self.app_class=(_); end
  def self.application; end
  def self.application=(_); end
  def self.backtrace_cleaner; end
  def self.cache; end
  def self.cache=(_); end
  def self.configuration; end
  def self.env; end
  def self.env=(environment); end
  def self.gem_version; end
  def self.groups(*groups); end
  def self.initialize!(*args, &block); end
  def self.initialized?(*args, &block); end
  def self.logger; end
  def self.logger=(_); end
  def self.public_path; end
  def self.root; end
  def self.version; end
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

  def self.add_lib_to_load_path!(root); end
  def self.create(initial_variable_values = _, &block); end
  def self.find_root(from); end
  def self.inherited(base); end
  def self.instance; end
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

Rails::Application::INITIAL_VARIABLES = T.let(T.unsafe(nil), Array)

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

  def self.called_from; end
  def self.called_from=(_); end
  def self.eager_load!(*args, &block); end
  def self.endpoint(endpoint = _); end
  def self.engine_name(name = _); end
  def self.find(path); end
  def self.find_root(from); end
  def self.find_root_with_flag(flag, root_path, default = _); end
  def self.inherited(base); end
  def self.isolate_namespace(mod); end
  def self.isolated; end
  def self.isolated=(_); end
  def self.isolated?; end
end

module Sprockets
  extend(::Sprockets::Utils)
  extend(::Sprockets::URIUtils)
  extend(::Sprockets::PathUtils)
  extend(::Sprockets::DigestUtils)
  extend(::Sprockets::PathDigestUtils)
  extend(::Sprockets::Dependencies)
  extend(::Sprockets::Compressing)
  extend(::Sprockets::ProcessorUtils)
  extend(::Sprockets::Processing)
  extend(::Sprockets::HTTPUtils)
  extend(::Sprockets::Transformers)
  extend(::Sprockets::Engines)
  extend(::Sprockets::Mime)
  extend(::Sprockets::Paths)
  extend(::Sprockets::Configuration)
end

Sprockets::Index = Sprockets::CachedEnvironment

module Sprockets::Rails
end

module Sprockets::Rails::Context
  include(::ActionView::Helpers::AssetUrlHelper)
  include(::ActionView::Helpers::CaptureHelper)
  include(::ActionView::Helpers::OutputSafetyHelper)
  include(::ActionView::Helpers::TagHelper)
  include(::ActionView::Helpers::AssetTagHelper)

  def compute_asset_path(path, options = _); end

  def self.included(klass); end
end

module Sprockets::Rails::Helper
  include(::ActionView::Helpers::AssetUrlHelper)
  include(::ActionView::Helpers::CaptureHelper)
  include(::ActionView::Helpers::OutputSafetyHelper)
  include(::ActionView::Helpers::TagHelper)
  include(::ActionView::Helpers::AssetTagHelper)
  include(::Sprockets::Rails::Utils)

  def asset_digest_path(path, options = _); end
  def asset_integrity(path, options = _); end
  def compute_asset_path(path, options = _); end
  def javascript_include_tag(*sources); end
  def resolve_asset_path(path, allow_non_precompiled = _); end
  def stylesheet_link_tag(*sources); end

  protected

  def asset_resolver_strategies; end
  def compute_integrity?(options); end
  def legacy_debug_path(path, debug); end
  def lookup_debug_asset(path, options = _); end
  def path_with_extname(path, options); end
  def request_debug_assets?; end
  def resolve_asset; end
  def secure_subresource_integrity_context?; end

  def self.extended(obj); end
  def self.included(klass); end
end

class Sprockets::Rails::Helper::AssetNotFound < ::StandardError
end

class Sprockets::Rails::Helper::AssetNotPrecompiled < ::StandardError
  include(::Sprockets::Rails::Utils)

  def initialize(source); end
end

Sprockets::Rails::Helper::VIEW_ACCESSORS = T.let(T.unsafe(nil), Array)

module Sprockets::Rails::HelperAssetResolvers
  def self.[](name); end
end

class Sprockets::Rails::HelperAssetResolvers::Environment
  def initialize(view); end

  def asset_path(path, digest, allow_non_precompiled = _); end
  def digest_path(path, allow_non_precompiled = _); end
  def find_debug_asset(path); end
  def integrity(path); end

  private

  def find_asset(path, options = _); end
  def precompiled?(path); end
  def raise_unless_precompiled_asset(path); end
end

class Sprockets::Rails::HelperAssetResolvers::Manifest
  def initialize(view); end

  def asset_path(path, digest, allow_non_precompiled = _); end
  def digest_path(path, allow_non_precompiled = _); end
  def find_debug_asset(path); end
  def integrity(path); end

  private

  def metadata(path); end
end

class Sprockets::Rails::QuietAssets
  def initialize(app); end

  def call(env); end
end

module Sprockets::Rails::RouteWrapper
  def internal?; end
  def internal_assets_path?; end

  def self.included(klass); end
end

module Sprockets::Rails::Utils
  def using_sprockets4?; end
end

Sprockets::Rails::VERSION = T.let(T.unsafe(nil), String)

class Sprockets::Railtie < ::Rails::Railtie
  include(::Sprockets::Rails::Utils)

  def build_environment(app, initialized = _); end

  def self.build_manifest(app); end
end

Sprockets::Railtie::LOOSE_APP_ASSETS = T.let(T.unsafe(nil), Proc)

class Sprockets::Railtie::ManifestNeededError < ::StandardError
  def initialize; end
end

class Sprockets::Railtie::OrderedOptions < ::ActiveSupport::OrderedOptions
  def configure(&block); end
end

Sprockets::SassFunctions = Sprockets::SassProcessor::Functions

Sprockets::VERSION = T.let(T.unsafe(nil), String)
