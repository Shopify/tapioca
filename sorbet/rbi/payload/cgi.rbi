# typed: __STDLIB_INTERNAL

class CGI
  include ::CGI::Escape
  extend ::CGI::Escape

  def initialize(options = T.unsafe(nil), &block); end

  def accept_charset; end
  def header(options = T.unsafe(nil)); end
  def http_header(options = T.unsafe(nil)); end
  def nph?; end
  def out(options = T.unsafe(nil)); end
  def print(*options); end

  private

  def _header_for_hash(options); end
  def _header_for_modruby(buf); end
  def _header_for_string(content_type); end
  def _no_crlf_check(str); end
  def env_table; end
  def stdinput; end
  def stdoutput; end

  class << self
    def accept_charset; end
    def accept_charset=(accept_charset); end
    def parse(query); end
  end
end

class CGI::Cookie < ::Array
  def initialize(name = T.unsafe(nil), *value); end

  def domain; end
  def domain=(str); end
  def expires; end
  def expires=(_arg0); end
  def httponly; end
  def httponly=(val); end
  def inspect; end
  def name; end
  def name=(str); end
  def path; end
  def path=(str); end
  def secure; end
  def secure=(val); end
  def to_s; end
  def value; end
  def value=(val); end

  class << self
    def parse(raw_cookie); end
  end
end

module CGI::Escape
  def escape(_arg0); end
  def escapeHTML(_arg0); end
  def escapeURIComponent(_arg0); end
  def unescape(*_arg0); end
  def unescapeHTML(_arg0); end
  def unescapeURIComponent(*_arg0); end
end

class CGI::HTML3
  include ::CGI::TagMaker
end

class CGI::HTML4
  include ::CGI::TagMaker
end

class CGI::HTML4Fr
  include ::CGI::TagMaker
end

class CGI::HTML4Tr
  include ::CGI::TagMaker
end

class CGI::HTML5
  include ::CGI::TagMaker
end

module CGI::Html3
  def a(attributes = T.unsafe(nil), &block); end
  def address(attributes = T.unsafe(nil), &block); end
  def applet(attributes = T.unsafe(nil), &block); end
  def area(attributes = T.unsafe(nil), &block); end
  def b(attributes = T.unsafe(nil), &block); end
  def base(attributes = T.unsafe(nil), &block); end
  def basefont(attributes = T.unsafe(nil), &block); end
  def big(attributes = T.unsafe(nil), &block); end
  def blockquote(attributes = T.unsafe(nil), &block); end
  def body(attributes = T.unsafe(nil), &block); end
  def br(attributes = T.unsafe(nil), &block); end
  def caption(attributes = T.unsafe(nil), &block); end
  def center(attributes = T.unsafe(nil), &block); end
  def cite(attributes = T.unsafe(nil), &block); end
  def code(attributes = T.unsafe(nil), &block); end
  def dd(attributes = T.unsafe(nil), &block); end
  def dfn(attributes = T.unsafe(nil), &block); end
  def dir(attributes = T.unsafe(nil), &block); end
  def div(attributes = T.unsafe(nil), &block); end
  def dl(attributes = T.unsafe(nil), &block); end
  def doctype; end
  def dt(attributes = T.unsafe(nil), &block); end
  def em(attributes = T.unsafe(nil), &block); end
  def font(attributes = T.unsafe(nil), &block); end
  def form(attributes = T.unsafe(nil), &block); end
  def h1(attributes = T.unsafe(nil), &block); end
  def h2(attributes = T.unsafe(nil), &block); end
  def h3(attributes = T.unsafe(nil), &block); end
  def h4(attributes = T.unsafe(nil), &block); end
  def h5(attributes = T.unsafe(nil), &block); end
  def h6(attributes = T.unsafe(nil), &block); end
  def head(attributes = T.unsafe(nil), &block); end
  def hr(attributes = T.unsafe(nil), &block); end
  def html(attributes = T.unsafe(nil), &block); end
  def i(attributes = T.unsafe(nil), &block); end
  def img(attributes = T.unsafe(nil), &block); end
  def input(attributes = T.unsafe(nil), &block); end
  def isindex(attributes = T.unsafe(nil), &block); end
  def kbd(attributes = T.unsafe(nil), &block); end
  def li(attributes = T.unsafe(nil), &block); end
  def link(attributes = T.unsafe(nil), &block); end
  def listing(attributes = T.unsafe(nil), &block); end
  def map(attributes = T.unsafe(nil), &block); end
  def menu(attributes = T.unsafe(nil), &block); end
  def meta(attributes = T.unsafe(nil), &block); end
  def ol(attributes = T.unsafe(nil), &block); end
  def option(attributes = T.unsafe(nil), &block); end
  def p(attributes = T.unsafe(nil), &block); end
  def param(attributes = T.unsafe(nil), &block); end
  def plaintext(attributes = T.unsafe(nil), &block); end
  def pre(attributes = T.unsafe(nil), &block); end
  def samp(attributes = T.unsafe(nil), &block); end
  def script(attributes = T.unsafe(nil), &block); end
  def select(attributes = T.unsafe(nil), &block); end
  def small(attributes = T.unsafe(nil), &block); end
  def strike(attributes = T.unsafe(nil), &block); end
  def strong(attributes = T.unsafe(nil), &block); end
  def style(attributes = T.unsafe(nil), &block); end
  def sub(attributes = T.unsafe(nil), &block); end
  def sup(attributes = T.unsafe(nil), &block); end
  def table(attributes = T.unsafe(nil), &block); end
  def td(attributes = T.unsafe(nil), &block); end
  def textarea(attributes = T.unsafe(nil), &block); end
  def th(attributes = T.unsafe(nil), &block); end
  def title(attributes = T.unsafe(nil), &block); end
  def tr(attributes = T.unsafe(nil), &block); end
  def tt(attributes = T.unsafe(nil), &block); end
  def u(attributes = T.unsafe(nil), &block); end
  def ul(attributes = T.unsafe(nil), &block); end
  def var(attributes = T.unsafe(nil), &block); end
  def xmp(attributes = T.unsafe(nil), &block); end
end

module CGI::Html4
  def a(attributes = T.unsafe(nil), &block); end
  def abbr(attributes = T.unsafe(nil), &block); end
  def acronym(attributes = T.unsafe(nil), &block); end
  def address(attributes = T.unsafe(nil), &block); end
  def area(attributes = T.unsafe(nil), &block); end
  def b(attributes = T.unsafe(nil), &block); end
  def base(attributes = T.unsafe(nil), &block); end
  def bdo(attributes = T.unsafe(nil), &block); end
  def big(attributes = T.unsafe(nil), &block); end
  def blockquote(attributes = T.unsafe(nil), &block); end
  def body(attributes = T.unsafe(nil), &block); end
  def br(attributes = T.unsafe(nil), &block); end
  def button(attributes = T.unsafe(nil), &block); end
  def caption(attributes = T.unsafe(nil), &block); end
  def cite(attributes = T.unsafe(nil), &block); end
  def code(attributes = T.unsafe(nil), &block); end
  def col(attributes = T.unsafe(nil), &block); end
  def colgroup(attributes = T.unsafe(nil), &block); end
  def dd(attributes = T.unsafe(nil), &block); end
  def del(attributes = T.unsafe(nil), &block); end
  def dfn(attributes = T.unsafe(nil), &block); end
  def div(attributes = T.unsafe(nil), &block); end
  def dl(attributes = T.unsafe(nil), &block); end
  def doctype; end
  def dt(attributes = T.unsafe(nil), &block); end
  def em(attributes = T.unsafe(nil), &block); end
  def fieldset(attributes = T.unsafe(nil), &block); end
  def form(attributes = T.unsafe(nil), &block); end
  def h1(attributes = T.unsafe(nil), &block); end
  def h2(attributes = T.unsafe(nil), &block); end
  def h3(attributes = T.unsafe(nil), &block); end
  def h4(attributes = T.unsafe(nil), &block); end
  def h5(attributes = T.unsafe(nil), &block); end
  def h6(attributes = T.unsafe(nil), &block); end
  def head(attributes = T.unsafe(nil), &block); end
  def hr(attributes = T.unsafe(nil), &block); end
  def html(attributes = T.unsafe(nil), &block); end
  def i(attributes = T.unsafe(nil), &block); end
  def img(attributes = T.unsafe(nil), &block); end
  def input(attributes = T.unsafe(nil), &block); end
  def ins(attributes = T.unsafe(nil), &block); end
  def kbd(attributes = T.unsafe(nil), &block); end
  def label(attributes = T.unsafe(nil), &block); end
  def legend(attributes = T.unsafe(nil), &block); end
  def li(attributes = T.unsafe(nil), &block); end
  def link(attributes = T.unsafe(nil), &block); end
  def map(attributes = T.unsafe(nil), &block); end
  def meta(attributes = T.unsafe(nil), &block); end
  def noscript(attributes = T.unsafe(nil), &block); end
  def object(attributes = T.unsafe(nil), &block); end
  def ol(attributes = T.unsafe(nil), &block); end
  def optgroup(attributes = T.unsafe(nil), &block); end
  def option(attributes = T.unsafe(nil), &block); end
  def p(attributes = T.unsafe(nil), &block); end
  def param(attributes = T.unsafe(nil), &block); end
  def pre(attributes = T.unsafe(nil), &block); end
  def q(attributes = T.unsafe(nil), &block); end
  def samp(attributes = T.unsafe(nil), &block); end
  def script(attributes = T.unsafe(nil), &block); end
  def select(attributes = T.unsafe(nil), &block); end
  def small(attributes = T.unsafe(nil), &block); end
  def span(attributes = T.unsafe(nil), &block); end
  def strong(attributes = T.unsafe(nil), &block); end
  def style(attributes = T.unsafe(nil), &block); end
  def sub(attributes = T.unsafe(nil), &block); end
  def sup(attributes = T.unsafe(nil), &block); end
  def table(attributes = T.unsafe(nil), &block); end
  def tbody(attributes = T.unsafe(nil), &block); end
  def td(attributes = T.unsafe(nil), &block); end
  def textarea(attributes = T.unsafe(nil), &block); end
  def tfoot(attributes = T.unsafe(nil), &block); end
  def th(attributes = T.unsafe(nil), &block); end
  def thead(attributes = T.unsafe(nil), &block); end
  def title(attributes = T.unsafe(nil), &block); end
  def tr(attributes = T.unsafe(nil), &block); end
  def tt(attributes = T.unsafe(nil), &block); end
  def ul(attributes = T.unsafe(nil), &block); end
  def var(attributes = T.unsafe(nil), &block); end
end

module CGI::Html4Fr
  def doctype; end
  def frame(attributes = T.unsafe(nil), &block); end
  def frameset(attributes = T.unsafe(nil), &block); end
end

module CGI::Html4Tr
  def a(attributes = T.unsafe(nil), &block); end
  def abbr(attributes = T.unsafe(nil), &block); end
  def acronym(attributes = T.unsafe(nil), &block); end
  def address(attributes = T.unsafe(nil), &block); end
  def applet(attributes = T.unsafe(nil), &block); end
  def area(attributes = T.unsafe(nil), &block); end
  def b(attributes = T.unsafe(nil), &block); end
  def base(attributes = T.unsafe(nil), &block); end
  def basefont(attributes = T.unsafe(nil), &block); end
  def bdo(attributes = T.unsafe(nil), &block); end
  def big(attributes = T.unsafe(nil), &block); end
  def blockquote(attributes = T.unsafe(nil), &block); end
  def body(attributes = T.unsafe(nil), &block); end
  def br(attributes = T.unsafe(nil), &block); end
  def button(attributes = T.unsafe(nil), &block); end
  def caption(attributes = T.unsafe(nil), &block); end
  def center(attributes = T.unsafe(nil), &block); end
  def cite(attributes = T.unsafe(nil), &block); end
  def code(attributes = T.unsafe(nil), &block); end
  def col(attributes = T.unsafe(nil), &block); end
  def colgroup(attributes = T.unsafe(nil), &block); end
  def dd(attributes = T.unsafe(nil), &block); end
  def del(attributes = T.unsafe(nil), &block); end
  def dfn(attributes = T.unsafe(nil), &block); end
  def dir(attributes = T.unsafe(nil), &block); end
  def div(attributes = T.unsafe(nil), &block); end
  def dl(attributes = T.unsafe(nil), &block); end
  def doctype; end
  def dt(attributes = T.unsafe(nil), &block); end
  def em(attributes = T.unsafe(nil), &block); end
  def fieldset(attributes = T.unsafe(nil), &block); end
  def font(attributes = T.unsafe(nil), &block); end
  def form(attributes = T.unsafe(nil), &block); end
  def h1(attributes = T.unsafe(nil), &block); end
  def h2(attributes = T.unsafe(nil), &block); end
  def h3(attributes = T.unsafe(nil), &block); end
  def h4(attributes = T.unsafe(nil), &block); end
  def h5(attributes = T.unsafe(nil), &block); end
  def h6(attributes = T.unsafe(nil), &block); end
  def head(attributes = T.unsafe(nil), &block); end
  def hr(attributes = T.unsafe(nil), &block); end
  def html(attributes = T.unsafe(nil), &block); end
  def i(attributes = T.unsafe(nil), &block); end
  def iframe(attributes = T.unsafe(nil), &block); end
  def img(attributes = T.unsafe(nil), &block); end
  def input(attributes = T.unsafe(nil), &block); end
  def ins(attributes = T.unsafe(nil), &block); end
  def isindex(attributes = T.unsafe(nil), &block); end
  def kbd(attributes = T.unsafe(nil), &block); end
  def label(attributes = T.unsafe(nil), &block); end
  def legend(attributes = T.unsafe(nil), &block); end
  def li(attributes = T.unsafe(nil), &block); end
  def link(attributes = T.unsafe(nil), &block); end
  def map(attributes = T.unsafe(nil), &block); end
  def menu(attributes = T.unsafe(nil), &block); end
  def meta(attributes = T.unsafe(nil), &block); end
  def noframes(attributes = T.unsafe(nil), &block); end
  def noscript(attributes = T.unsafe(nil), &block); end
  def object(attributes = T.unsafe(nil), &block); end
  def ol(attributes = T.unsafe(nil), &block); end
  def optgroup(attributes = T.unsafe(nil), &block); end
  def option(attributes = T.unsafe(nil), &block); end
  def p(attributes = T.unsafe(nil), &block); end
  def param(attributes = T.unsafe(nil), &block); end
  def pre(attributes = T.unsafe(nil), &block); end
  def q(attributes = T.unsafe(nil), &block); end
  def s(attributes = T.unsafe(nil), &block); end
  def samp(attributes = T.unsafe(nil), &block); end
  def script(attributes = T.unsafe(nil), &block); end
  def select(attributes = T.unsafe(nil), &block); end
  def small(attributes = T.unsafe(nil), &block); end
  def span(attributes = T.unsafe(nil), &block); end
  def strike(attributes = T.unsafe(nil), &block); end
  def strong(attributes = T.unsafe(nil), &block); end
  def style(attributes = T.unsafe(nil), &block); end
  def sub(attributes = T.unsafe(nil), &block); end
  def sup(attributes = T.unsafe(nil), &block); end
  def table(attributes = T.unsafe(nil), &block); end
  def tbody(attributes = T.unsafe(nil), &block); end
  def td(attributes = T.unsafe(nil), &block); end
  def textarea(attributes = T.unsafe(nil), &block); end
  def tfoot(attributes = T.unsafe(nil), &block); end
  def th(attributes = T.unsafe(nil), &block); end
  def thead(attributes = T.unsafe(nil), &block); end
  def title(attributes = T.unsafe(nil), &block); end
  def tr(attributes = T.unsafe(nil), &block); end
  def tt(attributes = T.unsafe(nil), &block); end
  def u(attributes = T.unsafe(nil), &block); end
  def ul(attributes = T.unsafe(nil), &block); end
  def var(attributes = T.unsafe(nil), &block); end
end

module CGI::Html5
  def a(attributes = T.unsafe(nil), &block); end
  def abbr(attributes = T.unsafe(nil), &block); end
  def address(attributes = T.unsafe(nil), &block); end
  def area(attributes = T.unsafe(nil), &block); end
  def article(attributes = T.unsafe(nil), &block); end
  def aside(attributes = T.unsafe(nil), &block); end
  def audio(attributes = T.unsafe(nil), &block); end
  def b(attributes = T.unsafe(nil), &block); end
  def base(attributes = T.unsafe(nil), &block); end
  def bdi(attributes = T.unsafe(nil), &block); end
  def bdo(attributes = T.unsafe(nil), &block); end
  def blockquote(attributes = T.unsafe(nil), &block); end
  def body(attributes = T.unsafe(nil), &block); end
  def br(attributes = T.unsafe(nil), &block); end
  def button(attributes = T.unsafe(nil), &block); end
  def canvas(attributes = T.unsafe(nil), &block); end
  def caption(attributes = T.unsafe(nil), &block); end
  def cite(attributes = T.unsafe(nil), &block); end
  def code(attributes = T.unsafe(nil), &block); end
  def col(attributes = T.unsafe(nil), &block); end
  def colgroup(attributes = T.unsafe(nil), &block); end
  def command(attributes = T.unsafe(nil), &block); end
  def datalist(attributes = T.unsafe(nil), &block); end
  def dd(attributes = T.unsafe(nil), &block); end
  def del(attributes = T.unsafe(nil), &block); end
  def details(attributes = T.unsafe(nil), &block); end
  def dfn(attributes = T.unsafe(nil), &block); end
  def dialog(attributes = T.unsafe(nil), &block); end
  def div(attributes = T.unsafe(nil), &block); end
  def dl(attributes = T.unsafe(nil), &block); end
  def doctype; end
  def dt(attributes = T.unsafe(nil), &block); end
  def em(attributes = T.unsafe(nil), &block); end
  def embed(attributes = T.unsafe(nil), &block); end
  def fieldset(attributes = T.unsafe(nil), &block); end
  def figcaption(attributes = T.unsafe(nil), &block); end
  def figure(attributes = T.unsafe(nil), &block); end
  def footer(attributes = T.unsafe(nil), &block); end
  def form(attributes = T.unsafe(nil), &block); end
  def h1(attributes = T.unsafe(nil), &block); end
  def h2(attributes = T.unsafe(nil), &block); end
  def h3(attributes = T.unsafe(nil), &block); end
  def h4(attributes = T.unsafe(nil), &block); end
  def h5(attributes = T.unsafe(nil), &block); end
  def h6(attributes = T.unsafe(nil), &block); end
  def head(attributes = T.unsafe(nil), &block); end
  def header(attributes = T.unsafe(nil), &block); end
  def hgroup(attributes = T.unsafe(nil), &block); end
  def hr(attributes = T.unsafe(nil), &block); end
  def html(attributes = T.unsafe(nil), &block); end
  def i(attributes = T.unsafe(nil), &block); end
  def iframe(attributes = T.unsafe(nil), &block); end
  def img(attributes = T.unsafe(nil), &block); end
  def input(attributes = T.unsafe(nil), &block); end
  def ins(attributes = T.unsafe(nil), &block); end
  def kbd(attributes = T.unsafe(nil), &block); end
  def keygen(attributes = T.unsafe(nil), &block); end
  def label(attributes = T.unsafe(nil), &block); end
  def legend(attributes = T.unsafe(nil), &block); end
  def li(attributes = T.unsafe(nil), &block); end
  def link(attributes = T.unsafe(nil), &block); end
  def map(attributes = T.unsafe(nil), &block); end
  def mark(attributes = T.unsafe(nil), &block); end
  def menu(attributes = T.unsafe(nil), &block); end
  def meta(attributes = T.unsafe(nil), &block); end
  def meter(attributes = T.unsafe(nil), &block); end
  def nav(attributes = T.unsafe(nil), &block); end
  def noscript(attributes = T.unsafe(nil), &block); end
  def object(attributes = T.unsafe(nil), &block); end
  def ol(attributes = T.unsafe(nil), &block); end
  def optgroup(attributes = T.unsafe(nil), &block); end
  def option(attributes = T.unsafe(nil), &block); end
  def output(attributes = T.unsafe(nil), &block); end
  def p(attributes = T.unsafe(nil), &block); end
  def param(attributes = T.unsafe(nil), &block); end
  def pre(attributes = T.unsafe(nil), &block); end
  def progress(attributes = T.unsafe(nil), &block); end
  def q(attributes = T.unsafe(nil), &block); end
  def rp(attributes = T.unsafe(nil), &block); end
  def rt(attributes = T.unsafe(nil), &block); end
  def ruby(attributes = T.unsafe(nil), &block); end
  def s(attributes = T.unsafe(nil), &block); end
  def samp(attributes = T.unsafe(nil), &block); end
  def script(attributes = T.unsafe(nil), &block); end
  def section(attributes = T.unsafe(nil), &block); end
  def select(attributes = T.unsafe(nil), &block); end
  def small(attributes = T.unsafe(nil), &block); end
  def source(attributes = T.unsafe(nil), &block); end
  def span(attributes = T.unsafe(nil), &block); end
  def strong(attributes = T.unsafe(nil), &block); end
  def style(attributes = T.unsafe(nil), &block); end
  def sub(attributes = T.unsafe(nil), &block); end
  def summary(attributes = T.unsafe(nil), &block); end
  def sup(attributes = T.unsafe(nil), &block); end
  def table(attributes = T.unsafe(nil), &block); end
  def tbody(attributes = T.unsafe(nil), &block); end
  def td(attributes = T.unsafe(nil), &block); end
  def textarea(attributes = T.unsafe(nil), &block); end
  def tfoot(attributes = T.unsafe(nil), &block); end
  def th(attributes = T.unsafe(nil), &block); end
  def thead(attributes = T.unsafe(nil), &block); end
  def time(attributes = T.unsafe(nil), &block); end
  def title(attributes = T.unsafe(nil), &block); end
  def tr(attributes = T.unsafe(nil), &block); end
  def track(attributes = T.unsafe(nil), &block); end
  def u(attributes = T.unsafe(nil), &block); end
  def ul(attributes = T.unsafe(nil), &block); end
  def var(attributes = T.unsafe(nil), &block); end
  def video(attributes = T.unsafe(nil), &block); end
  def wbr(attributes = T.unsafe(nil), &block); end
end

module CGI::HtmlExtension
  def a(href = T.unsafe(nil)); end
  def base(href = T.unsafe(nil)); end
  def blockquote(cite = T.unsafe(nil)); end
  def caption(align = T.unsafe(nil)); end
  def checkbox(name = T.unsafe(nil), value = T.unsafe(nil), checked = T.unsafe(nil)); end
  def checkbox_group(name = T.unsafe(nil), *values); end
  def file_field(name = T.unsafe(nil), size = T.unsafe(nil), maxlength = T.unsafe(nil)); end
  def form(method = T.unsafe(nil), action = T.unsafe(nil), enctype = T.unsafe(nil)); end
  def hidden(name = T.unsafe(nil), value = T.unsafe(nil)); end
  def html(attributes = T.unsafe(nil)); end
  def image_button(src = T.unsafe(nil), name = T.unsafe(nil), alt = T.unsafe(nil)); end
  def img(src = T.unsafe(nil), alt = T.unsafe(nil), width = T.unsafe(nil), height = T.unsafe(nil)); end
  def multipart_form(action = T.unsafe(nil), enctype = T.unsafe(nil)); end
  def password_field(name = T.unsafe(nil), value = T.unsafe(nil), size = T.unsafe(nil), maxlength = T.unsafe(nil)); end
  def popup_menu(name = T.unsafe(nil), *values); end
  def radio_button(name = T.unsafe(nil), value = T.unsafe(nil), checked = T.unsafe(nil)); end
  def radio_group(name = T.unsafe(nil), *values); end
  def reset(value = T.unsafe(nil), name = T.unsafe(nil)); end
  def scrolling_list(name = T.unsafe(nil), *values); end
  def submit(value = T.unsafe(nil), name = T.unsafe(nil)); end
  def text_field(name = T.unsafe(nil), value = T.unsafe(nil), size = T.unsafe(nil), maxlength = T.unsafe(nil)); end
  def textarea(name = T.unsafe(nil), cols = T.unsafe(nil), rows = T.unsafe(nil)); end
end

class CGI::InvalidEncoding < ::Exception; end

module CGI::QueryExtension
  def [](key); end
  def accept; end
  def accept_charset; end
  def accept_encoding; end
  def accept_language; end
  def auth_type; end
  def cache_control; end
  def content_length; end
  def content_type; end
  def cookies; end
  def cookies=(_arg0); end
  def create_body(is_large); end
  def files; end
  def from; end
  def gateway_interface; end
  def has_key?(*args); end
  def host; end
  def include?(*args); end
  def key?(*args); end
  def keys(*args); end
  def multipart?; end
  def negotiate; end
  def params; end
  def params=(hash); end
  def path_info; end
  def path_translated; end
  def pragma; end
  def query_string; end
  def raw_cookie; end
  def raw_cookie2; end
  def referer; end
  def remote_addr; end
  def remote_host; end
  def remote_ident; end
  def remote_user; end
  def request_method; end
  def script_name; end
  def server_name; end
  def server_port; end
  def server_protocol; end
  def server_software; end
  def unescape_filename?; end
  def user_agent; end

  private

  def initialize_query; end
  def read_from_cmdline; end
  def read_multipart(boundary, content_length); end
end

class CGI::Session
  def initialize(request, option = T.unsafe(nil)); end

  def [](key); end
  def []=(key, val); end
  def close; end
  def delete; end
  def new_session; end
  def new_store_file(option = T.unsafe(nil)); end
  def session_id; end
  def update; end

  private

  def create_new_id; end

  class << self
    def callback(dbman); end
  end
end

class CGI::Session::FileStore
  def initialize(session, option = T.unsafe(nil)); end

  def close; end
  def delete; end
  def restore; end
  def update; end
end

class CGI::Session::MemoryStore
  def initialize(session, option = T.unsafe(nil)); end

  def close; end
  def delete; end
  def restore; end
  def update; end
end

class CGI::Session::NoSession < ::RuntimeError; end

class CGI::Session::NullStore
  def initialize(session, option = T.unsafe(nil)); end

  def close; end
  def delete; end
  def restore; end
  def update; end
end

module CGI::TagMaker
  def nOE_element(element, attributes = T.unsafe(nil)); end
  def nOE_element_def(attributes = T.unsafe(nil), &block); end
  def nO_element(element, attributes = T.unsafe(nil)); end
  def nO_element_def(attributes = T.unsafe(nil), &block); end
  def nn_element(element, attributes = T.unsafe(nil)); end
  def nn_element_def(attributes = T.unsafe(nil), &block); end
end

module CGI::Util
  include ::CGI::Escape

  def escape(_arg0); end
  def escapeElement(string, *elements); end
  def escapeHTML(_arg0); end
  def escapeURIComponent(_arg0); end
  def escape_element(string, *elements); end
  def escape_html(_arg0); end
  def h(_arg0); end
  def pretty(string, shift = T.unsafe(nil)); end
  def rfc1123_date(time); end
  def unescape(*_arg0); end
  def unescapeElement(string, *elements); end
  def unescapeHTML(_arg0); end
  def unescapeURIComponent(*_arg0); end
  def unescape_element(string, *elements); end
  def unescape_html(_arg0); end
end

module Etc
  private

  def confstr(_arg0); end
  def endgrent; end
  def endpwent; end
  def getgrent; end
  def getgrgid(*_arg0); end
  def getgrnam(_arg0); end
  def getlogin; end
  def getpwent; end
  def getpwnam(_arg0); end
  def getpwuid(*_arg0); end
  def group; end
  def nprocessors; end
  def passwd; end
  def setgrent; end
  def setpwent; end
  def sysconf(_arg0); end
  def sysconfdir; end
  def systmpdir; end
  def uname; end

  class << self
    def confstr(_arg0); end
    def endgrent; end
    def endpwent; end
    def getgrent; end
    def getgrgid(*_arg0); end
    def getgrnam(_arg0); end
    def getlogin; end
    def getpwent; end
    def getpwnam(_arg0); end
    def getpwuid(*_arg0); end
    def group; end
    def nprocessors; end
    def passwd; end
    def setgrent; end
    def setpwent; end
    def sysconf(_arg0); end
    def sysconfdir; end
    def systmpdir; end
    def uname; end
  end
end

class Etc::Group < ::Struct
  extend ::Enumerable

  def gid; end
  def gid=(_); end
  def mem; end
  def mem=(_); end
  def name; end
  def name=(_); end
  def passwd; end
  def passwd=(_); end

  class << self
    def [](*_arg0); end
    def each; end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

class Etc::Passwd < ::Struct
  extend ::Enumerable

  def change; end
  def change=(_); end
  def dir; end
  def dir=(_); end
  def expire; end
  def expire=(_); end
  def gecos; end
  def gecos=(_); end
  def gid; end
  def gid=(_); end
  def name; end
  def name=(_); end
  def passwd; end
  def passwd=(_); end
  def shell; end
  def shell=(_); end
  def uclass; end
  def uclass=(_); end
  def uid; end
  def uid=(_); end

  class << self
    def [](*_arg0); end
    def each; end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

module FileUtils
  private

  def apply_mask(mode, user_mask, op, mode_mask); end
  def cd(dir, verbose: T.unsafe(nil), &block); end
  def chdir(dir, verbose: T.unsafe(nil), &block); end
  def chmod(mode, list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def chmod_R(mode, list, noop: T.unsafe(nil), verbose: T.unsafe(nil), force: T.unsafe(nil)); end
  def chown(user, group, list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def chown_R(user, group, list, noop: T.unsafe(nil), verbose: T.unsafe(nil), force: T.unsafe(nil)); end
  def cmp(a, b); end
  def compare_file(a, b); end
  def compare_stream(a, b); end
  def copy(src, dest, preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def copy_entry(src, dest, preserve = T.unsafe(nil), dereference_root = T.unsafe(nil), remove_destination = T.unsafe(nil)); end
  def copy_file(src, dest, preserve = T.unsafe(nil), dereference = T.unsafe(nil)); end
  def copy_stream(src, dest); end
  def cp(src, dest, preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def cp_lr(src, dest, noop: T.unsafe(nil), verbose: T.unsafe(nil), dereference_root: T.unsafe(nil), remove_destination: T.unsafe(nil)); end
  def cp_r(src, dest, preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), dereference_root: T.unsafe(nil), remove_destination: T.unsafe(nil)); end
  def fu_clean_components(*comp); end
  def fu_each_src_dest(src, dest); end
  def fu_each_src_dest0(src, dest, target_directory = T.unsafe(nil)); end
  def fu_get_gid(group); end
  def fu_get_uid(user); end
  def fu_have_symlink?; end
  def fu_list(arg); end
  def fu_mkdir(path, mode); end
  def fu_mode(mode, path); end
  def fu_output_message(msg); end
  def fu_relative_components_from(target, base); end
  def fu_same?(a, b); end
  def fu_split_path(path); end
  def fu_starting_path?(path); end
  def fu_stat_identical_entry?(a, b); end
  def getwd; end
  def identical?(a, b); end
  def install(src, dest, mode: T.unsafe(nil), owner: T.unsafe(nil), group: T.unsafe(nil), preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def link(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def link_entry(src, dest, dereference_root = T.unsafe(nil), remove_destination = T.unsafe(nil)); end
  def ln(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def ln_s(src, dest, force: T.unsafe(nil), relative: T.unsafe(nil), target_directory: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def ln_sf(src, dest, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def ln_sr(src, dest, target_directory: T.unsafe(nil), force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def makedirs(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def mkdir(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def mkdir_p(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def mkpath(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def mode_to_s(mode); end
  def move(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
  def mv(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
  def pwd; end
  def remove(list, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def remove_dir(path, force = T.unsafe(nil)); end
  def remove_entry(path, force = T.unsafe(nil)); end
  def remove_entry_secure(path, force = T.unsafe(nil)); end
  def remove_file(path, force = T.unsafe(nil)); end
  def remove_trailing_slash(dir); end
  def rm(list, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def rm_f(list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def rm_r(list, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
  def rm_rf(list, noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
  def rmdir(list, parents: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def rmtree(list, noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
  def safe_unlink(list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def symbolic_modes_to_i(mode_sym, path); end
  def symlink(src, dest, force: T.unsafe(nil), relative: T.unsafe(nil), target_directory: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
  def touch(list, noop: T.unsafe(nil), verbose: T.unsafe(nil), mtime: T.unsafe(nil), nocreate: T.unsafe(nil)); end
  def uptodate?(new, old_list); end
  def user_mask(target); end

  class << self
    def cd(dir, verbose: T.unsafe(nil), &block); end
    def chdir(dir, verbose: T.unsafe(nil), &block); end
    def chmod(mode, list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def chmod_R(mode, list, noop: T.unsafe(nil), verbose: T.unsafe(nil), force: T.unsafe(nil)); end
    def chown(user, group, list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def chown_R(user, group, list, noop: T.unsafe(nil), verbose: T.unsafe(nil), force: T.unsafe(nil)); end
    def cmp(a, b); end
    def collect_method(opt); end
    def commands; end
    def compare_file(a, b); end
    def compare_stream(a, b); end
    def copy(src, dest, preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def copy_entry(src, dest, preserve = T.unsafe(nil), dereference_root = T.unsafe(nil), remove_destination = T.unsafe(nil)); end
    def copy_file(src, dest, preserve = T.unsafe(nil), dereference = T.unsafe(nil)); end
    def copy_stream(src, dest); end
    def cp(src, dest, preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def cp_lr(src, dest, noop: T.unsafe(nil), verbose: T.unsafe(nil), dereference_root: T.unsafe(nil), remove_destination: T.unsafe(nil)); end
    def cp_r(src, dest, preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), dereference_root: T.unsafe(nil), remove_destination: T.unsafe(nil)); end
    def getwd; end
    def have_option?(mid, opt); end
    def identical?(a, b); end
    def install(src, dest, mode: T.unsafe(nil), owner: T.unsafe(nil), group: T.unsafe(nil), preserve: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def link(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def link_entry(src, dest, dereference_root = T.unsafe(nil), remove_destination = T.unsafe(nil)); end
    def ln(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def ln_s(src, dest, force: T.unsafe(nil), relative: T.unsafe(nil), target_directory: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def ln_sf(src, dest, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def ln_sr(src, dest, target_directory: T.unsafe(nil), force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def makedirs(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def mkdir(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def mkdir_p(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def mkpath(list, mode: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def move(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
    def mv(src, dest, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
    def options; end
    def options_of(mid); end
    def private_module_function(name); end
    def pwd; end
    def remove(list, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def remove_dir(path, force = T.unsafe(nil)); end
    def remove_entry(path, force = T.unsafe(nil)); end
    def remove_entry_secure(path, force = T.unsafe(nil)); end
    def remove_file(path, force = T.unsafe(nil)); end
    def rm(list, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def rm_f(list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def rm_r(list, force: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
    def rm_rf(list, noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
    def rmdir(list, parents: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def rmtree(list, noop: T.unsafe(nil), verbose: T.unsafe(nil), secure: T.unsafe(nil)); end
    def safe_unlink(list, noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def symlink(src, dest, force: T.unsafe(nil), relative: T.unsafe(nil), target_directory: T.unsafe(nil), noop: T.unsafe(nil), verbose: T.unsafe(nil)); end
    def touch(list, noop: T.unsafe(nil), verbose: T.unsafe(nil), mtime: T.unsafe(nil), nocreate: T.unsafe(nil)); end
    def uptodate?(new, old_list); end

    private

    def apply_mask(mode, user_mask, op, mode_mask); end
    def fu_clean_components(*comp); end
    def fu_each_src_dest(src, dest); end
    def fu_each_src_dest0(src, dest, target_directory = T.unsafe(nil)); end
    def fu_get_gid(group); end
    def fu_get_uid(user); end
    def fu_have_symlink?; end
    def fu_list(arg); end
    def fu_mkdir(path, mode); end
    def fu_mode(mode, path); end
    def fu_output_message(msg); end
    def fu_relative_components_from(target, base); end
    def fu_same?(a, b); end
    def fu_split_path(path); end
    def fu_starting_path?(path); end
    def fu_stat_identical_entry?(a, b); end
    def mode_to_s(mode); end
    def remove_trailing_slash(dir); end
    def symbolic_modes_to_i(mode_sym, path); end
    def user_mask(target); end
  end
end

module FileUtils::DryRun
  include ::FileUtils::StreamUtils_
  extend ::FileUtils::StreamUtils_
  extend ::FileUtils
  extend ::FileUtils::LowMethods

  private

  def chmod(*args, **options); end
  def chmod_R(*args, **options); end
  def chown(*args, **options); end
  def chown_R(*args, **options); end
  def copy(*args, **options); end
  def cp(*args, **options); end
  def cp_lr(*args, **options); end
  def cp_r(*args, **options); end
  def install(*args, **options); end
  def link(*args, **options); end
  def ln(*args, **options); end
  def ln_s(*args, **options); end
  def ln_sf(*args, **options); end
  def ln_sr(*args, **options); end
  def makedirs(*args, **options); end
  def mkdir(*args, **options); end
  def mkdir_p(*args, **options); end
  def mkpath(*args, **options); end
  def move(*args, **options); end
  def mv(*args, **options); end
  def remove(*args, **options); end
  def rm(*args, **options); end
  def rm_f(*args, **options); end
  def rm_r(*args, **options); end
  def rm_rf(*args, **options); end
  def rmdir(*args, **options); end
  def rmtree(*args, **options); end
  def safe_unlink(*args, **options); end
  def symlink(*args, **options); end
  def touch(*args, **options); end

  class << self
    def cd(*_arg0); end
    def chdir(*_arg0); end
    def chmod(*args, **options); end
    def chmod_R(*args, **options); end
    def chown(*args, **options); end
    def chown_R(*args, **options); end
    def cmp(*_arg0); end
    def compare_file(*_arg0); end
    def compare_stream(*_arg0); end
    def copy(*args, **options); end
    def copy_entry(*_arg0); end
    def copy_file(*_arg0); end
    def copy_stream(*_arg0); end
    def cp(*args, **options); end
    def cp_lr(*args, **options); end
    def cp_r(*args, **options); end
    def getwd(*_arg0); end
    def identical?(*_arg0); end
    def install(*args, **options); end
    def link(*args, **options); end
    def link_entry(*_arg0); end
    def ln(*args, **options); end
    def ln_s(*args, **options); end
    def ln_sf(*args, **options); end
    def ln_sr(*args, **options); end
    def makedirs(*args, **options); end
    def mkdir(*args, **options); end
    def mkdir_p(*args, **options); end
    def mkpath(*args, **options); end
    def move(*args, **options); end
    def mv(*args, **options); end
    def pwd(*_arg0); end
    def remove(*args, **options); end
    def remove_dir(*_arg0); end
    def remove_entry(*_arg0); end
    def remove_entry_secure(*_arg0); end
    def remove_file(*_arg0); end
    def rm(*args, **options); end
    def rm_f(*args, **options); end
    def rm_r(*args, **options); end
    def rm_rf(*args, **options); end
    def rmdir(*args, **options); end
    def rmtree(*args, **options); end
    def safe_unlink(*args, **options); end
    def symlink(*args, **options); end
    def touch(*args, **options); end
    def uptodate?(*_arg0); end
  end
end

class FileUtils::Entry_
  def initialize(a, b = T.unsafe(nil), deref = T.unsafe(nil)); end

  def blockdev?; end
  def chardev?; end
  def chmod(mode); end
  def chown(uid, gid); end
  def copy(dest); end
  def copy_file(dest); end
  def copy_metadata(path); end
  def dereference?; end
  def directory?; end
  def door?; end
  def entries; end
  def exist?; end
  def file?; end
  def inspect; end
  def link(dest); end
  def lstat; end
  def lstat!; end
  def path; end
  def pipe?; end
  def platform_support; end
  def postorder_traverse; end
  def prefix; end
  def preorder_traverse; end
  def rel; end
  def remove; end
  def remove_dir1; end
  def remove_file; end
  def socket?; end
  def stat; end
  def stat!; end
  def symlink?; end
  def traverse; end
  def wrap_traverse(pre, post); end

  private

  def check_have_lchmod?; end
  def check_have_lchown?; end
  def descendant_directory?(descendant, ascendant); end
  def have_lchmod?; end
  def have_lchown?; end
  def join(dir, base); end
end

module FileUtils::LowMethods
  private

  def _do_nothing(*_arg0); end
  def cd(*_arg0); end
  def chdir(*_arg0); end
  def cmp(*_arg0); end
  def collect_method(*_arg0); end
  def commands(*_arg0); end
  def compare_file(*_arg0); end
  def compare_stream(*_arg0); end
  def copy_entry(*_arg0); end
  def copy_file(*_arg0); end
  def copy_stream(*_arg0); end
  def getwd(*_arg0); end
  def have_option?(*_arg0); end
  def identical?(*_arg0); end
  def link_entry(*_arg0); end
  def options(*_arg0); end
  def options_of(*_arg0); end
  def private_module_function(*_arg0); end
  def pwd(*_arg0); end
  def remove_dir(*_arg0); end
  def remove_entry(*_arg0); end
  def remove_entry_secure(*_arg0); end
  def remove_file(*_arg0); end
  def uptodate?(*_arg0); end
end

module FileUtils::NoWrite
  include ::FileUtils::StreamUtils_
  extend ::FileUtils::StreamUtils_
  extend ::FileUtils
  extend ::FileUtils::LowMethods

  private

  def chmod(*args, **options); end
  def chmod_R(*args, **options); end
  def chown(*args, **options); end
  def chown_R(*args, **options); end
  def copy(*args, **options); end
  def cp(*args, **options); end
  def cp_lr(*args, **options); end
  def cp_r(*args, **options); end
  def install(*args, **options); end
  def link(*args, **options); end
  def ln(*args, **options); end
  def ln_s(*args, **options); end
  def ln_sf(*args, **options); end
  def ln_sr(*args, **options); end
  def makedirs(*args, **options); end
  def mkdir(*args, **options); end
  def mkdir_p(*args, **options); end
  def mkpath(*args, **options); end
  def move(*args, **options); end
  def mv(*args, **options); end
  def remove(*args, **options); end
  def rm(*args, **options); end
  def rm_f(*args, **options); end
  def rm_r(*args, **options); end
  def rm_rf(*args, **options); end
  def rmdir(*args, **options); end
  def rmtree(*args, **options); end
  def safe_unlink(*args, **options); end
  def symlink(*args, **options); end
  def touch(*args, **options); end

  class << self
    def cd(*_arg0); end
    def chdir(*_arg0); end
    def chmod(*args, **options); end
    def chmod_R(*args, **options); end
    def chown(*args, **options); end
    def chown_R(*args, **options); end
    def cmp(*_arg0); end
    def compare_file(*_arg0); end
    def compare_stream(*_arg0); end
    def copy(*args, **options); end
    def copy_entry(*_arg0); end
    def copy_file(*_arg0); end
    def copy_stream(*_arg0); end
    def cp(*args, **options); end
    def cp_lr(*args, **options); end
    def cp_r(*args, **options); end
    def getwd(*_arg0); end
    def identical?(*_arg0); end
    def install(*args, **options); end
    def link(*args, **options); end
    def link_entry(*_arg0); end
    def ln(*args, **options); end
    def ln_s(*args, **options); end
    def ln_sf(*args, **options); end
    def ln_sr(*args, **options); end
    def makedirs(*args, **options); end
    def mkdir(*args, **options); end
    def mkdir_p(*args, **options); end
    def mkpath(*args, **options); end
    def move(*args, **options); end
    def mv(*args, **options); end
    def pwd(*_arg0); end
    def remove(*args, **options); end
    def remove_dir(*_arg0); end
    def remove_entry(*_arg0); end
    def remove_entry_secure(*_arg0); end
    def remove_file(*_arg0); end
    def rm(*args, **options); end
    def rm_f(*args, **options); end
    def rm_r(*args, **options); end
    def rm_rf(*args, **options); end
    def rmdir(*args, **options); end
    def rmtree(*args, **options); end
    def safe_unlink(*args, **options); end
    def symlink(*args, **options); end
    def touch(*args, **options); end
    def uptodate?(*_arg0); end
  end
end

module FileUtils::StreamUtils_
  private

  def fu_blksize(st); end
  def fu_copy_stream0(src, dest, blksize = T.unsafe(nil)); end
  def fu_default_blksize; end
  def fu_stream_blksize(*streams); end
  def fu_windows?; end
end

module FileUtils::Verbose
  include ::FileUtils::StreamUtils_
  extend ::FileUtils::StreamUtils_
  extend ::FileUtils

  private

  def cd(*args, **options); end
  def chdir(*args, **options); end
  def chmod(*args, **options); end
  def chmod_R(*args, **options); end
  def chown(*args, **options); end
  def chown_R(*args, **options); end
  def copy(*args, **options); end
  def cp(*args, **options); end
  def cp_lr(*args, **options); end
  def cp_r(*args, **options); end
  def install(*args, **options); end
  def link(*args, **options); end
  def ln(*args, **options); end
  def ln_s(*args, **options); end
  def ln_sf(*args, **options); end
  def ln_sr(*args, **options); end
  def makedirs(*args, **options); end
  def mkdir(*args, **options); end
  def mkdir_p(*args, **options); end
  def mkpath(*args, **options); end
  def move(*args, **options); end
  def mv(*args, **options); end
  def remove(*args, **options); end
  def rm(*args, **options); end
  def rm_f(*args, **options); end
  def rm_r(*args, **options); end
  def rm_rf(*args, **options); end
  def rmdir(*args, **options); end
  def rmtree(*args, **options); end
  def safe_unlink(*args, **options); end
  def symlink(*args, **options); end
  def touch(*args, **options); end

  class << self
    def cd(*args, **options); end
    def chdir(*args, **options); end
    def chmod(*args, **options); end
    def chmod_R(*args, **options); end
    def chown(*args, **options); end
    def chown_R(*args, **options); end
    def cmp(a, b); end
    def compare_file(a, b); end
    def compare_stream(a, b); end
    def copy(*args, **options); end
    def copy_entry(src, dest, preserve = T.unsafe(nil), dereference_root = T.unsafe(nil), remove_destination = T.unsafe(nil)); end
    def copy_file(src, dest, preserve = T.unsafe(nil), dereference = T.unsafe(nil)); end
    def copy_stream(src, dest); end
    def cp(*args, **options); end
    def cp_lr(*args, **options); end
    def cp_r(*args, **options); end
    def getwd; end
    def identical?(a, b); end
    def install(*args, **options); end
    def link(*args, **options); end
    def link_entry(src, dest, dereference_root = T.unsafe(nil), remove_destination = T.unsafe(nil)); end
    def ln(*args, **options); end
    def ln_s(*args, **options); end
    def ln_sf(*args, **options); end
    def ln_sr(*args, **options); end
    def makedirs(*args, **options); end
    def mkdir(*args, **options); end
    def mkdir_p(*args, **options); end
    def mkpath(*args, **options); end
    def move(*args, **options); end
    def mv(*args, **options); end
    def pwd; end
    def remove(*args, **options); end
    def remove_dir(path, force = T.unsafe(nil)); end
    def remove_entry(path, force = T.unsafe(nil)); end
    def remove_entry_secure(path, force = T.unsafe(nil)); end
    def remove_file(path, force = T.unsafe(nil)); end
    def rm(*args, **options); end
    def rm_f(*args, **options); end
    def rm_r(*args, **options); end
    def rm_rf(*args, **options); end
    def rmdir(*args, **options); end
    def rmtree(*args, **options); end
    def safe_unlink(*args, **options); end
    def symlink(*args, **options); end
    def touch(*args, **options); end
    def uptodate?(new, old_list); end
  end
end
