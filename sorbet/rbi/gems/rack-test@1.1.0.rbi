# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   tapioca sync

# typed: true

class Rack::MockSession
  def initialize(app, default_host = _); end

  def after_request(&block); end
  def clear_cookies; end
  def cookie_jar; end
  def cookie_jar=(_); end
  def default_host; end
  def last_request; end
  def last_response; end
  def request(uri, env); end
  def set_cookie(cookie, uri = _); end
end

module Rack::Test
  def self.encoding_aware_strings?; end
end

class Rack::Test::Cookie
  include(::Rack::Utils)

  def initialize(raw, uri = _, default_host = _); end

  def <=>(other); end
  def domain; end
  def empty?; end
  def expired?; end
  def expires; end
  def http_only?; end
  def matches?(uri); end
  def name; end
  def path; end
  def raw; end
  def replaces?(other); end
  def secure?; end
  def to_h; end
  def to_hash; end
  def valid?(uri); end
  def value; end

  protected

  def default_uri; end
end

class Rack::Test::CookieJar
  def initialize(cookies = _, default_host = _); end

  def <<(new_cookie); end
  def [](name); end
  def []=(name, value); end
  def delete(name); end
  def for(uri); end
  def get_cookie(name); end
  def merge(raw_cookies, uri = _); end
  def to_hash; end

  protected

  def hash_for(uri = _); end
end

Rack::Test::CookieJar::DELIMITER = T.let(T.unsafe(nil), String)

Rack::Test::DEFAULT_HOST = T.let(T.unsafe(nil), String)

class Rack::Test::Error < ::StandardError
end

Rack::Test::MULTIPART_BOUNDARY = T.let(T.unsafe(nil), String)

module Rack::Test::Methods
  extend(::Forwardable)

  def _current_session_names; end
  def authorize(*args, &block); end
  def basic_authorize(*args, &block); end
  def build_rack_mock_session; end
  def build_rack_test_session(name); end
  def clear_cookies(*args, &block); end
  def current_session; end
  def custom_request(*args, &block); end
  def delete(*args, &block); end
  def digest_authorize(*args, &block); end
  def env(*args, &block); end
  def follow_redirect!(*args, &block); end
  def get(*args, &block); end
  def head(*args, &block); end
  def header(*args, &block); end
  def last_request(*args, &block); end
  def last_response(*args, &block); end
  def options(*args, &block); end
  def patch(*args, &block); end
  def post(*args, &block); end
  def put(*args, &block); end
  def rack_mock_session(name = _); end
  def rack_test_session(name = _); end
  def request(*args, &block); end
  def set_cookie(*args, &block); end
  def with_session(name); end
end

Rack::Test::Methods::METHODS = T.let(T.unsafe(nil), Array)

class Rack::Test::MockDigestRequest
  def initialize(params); end

  def method; end
  def method_missing(sym); end
  def response(password); end
end

class Rack::Test::Session
  include(::Rack::Utils)
  include(::Rack::Test::Utils)
  extend(::Forwardable)

  def initialize(mock_session); end

  def authorize(username, password); end
  def basic_authorize(username, password); end
  def clear_cookies(*args, &block); end
  def custom_request(verb, uri, params = _, env = _, &block); end
  def delete(uri, params = _, env = _, &block); end
  def digest_authorize(username, password); end
  def env(name, value); end
  def follow_redirect!; end
  def get(uri, params = _, env = _, &block); end
  def head(uri, params = _, env = _, &block); end
  def header(name, value); end
  def last_request(*args, &block); end
  def last_response(*args, &block); end
  def options(uri, params = _, env = _, &block); end
  def patch(uri, params = _, env = _, &block); end
  def post(uri, params = _, env = _, &block); end
  def put(uri, params = _, env = _, &block); end
  def request(uri, env = _, &block); end
  def set_cookie(*args, &block); end

  private

  def default_env; end
  def digest_auth_configured?; end
  def digest_auth_header; end
  def env_for(uri, env); end
  def headers_for_env; end
  def params_to_string(params); end
  def parse_uri(path, env); end
  def process_request(uri, env); end
  def retry_with_digest_auth?(env); end
end

class Rack::Test::UploadedFile
  def initialize(content, content_type = _, binary = _, original_filename: _); end

  def content_type; end
  def content_type=(_); end
  def local_path; end
  def method_missing(method_name, *args, &block); end
  def original_filename; end
  def path; end
  def tempfile; end

  private

  def initialize_from_file_path(path); end
  def initialize_from_stringio(stringio, original_filename); end
  def respond_to_missing?(method_name, include_private = _); end

  def self.actually_finalize(file); end
  def self.finalize(file); end
end

module Rack::Test::Utils
  include(::Rack::Utils)
  extend(::Rack::Utils)


  private

  def build_file_part(parameter_name, uploaded_file); end
  def build_multipart(params, first = _, multipart = _); end
  def build_nested_query(value, prefix = _); end
  def build_parts(parameters); end
  def build_primitive_part(parameter_name, value); end
  def get_parts(parameters); end

  def self.build_file_part(parameter_name, uploaded_file); end
  def self.build_multipart(params, first = _, multipart = _); end
  def self.build_nested_query(value, prefix = _); end
  def self.build_parts(parameters); end
  def self.build_primitive_part(parameter_name, value); end
  def self.get_parts(parameters); end
end

Rack::Test::VERSION = T.let(T.unsafe(nil), String)
