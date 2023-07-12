# typed: __STDLIB_INTERNAL

module Forwardable
  def def_delegator(accessor, method, ali = T.unsafe(nil)); end
  def def_delegators(accessor, *methods); end
  def def_instance_delegator(accessor, method, ali = T.unsafe(nil)); end
  def def_instance_delegators(accessor, *methods); end
  def delegate(hash); end
  def instance_delegate(hash); end

  class << self
    def _compile_method(src, file, line); end
    def _delegator_method(obj, accessor, method, ali); end
    def _valid_method?(method); end
    def debug; end
    def debug=(_arg0); end
  end
end

module Racc; end

class Racc::Accept
  def inspect; end
end

class Racc::ActionTable
  def initialize(rt, st); end

  def accept; end
  def each_reduce(&block); end
  def each_shift(&block); end
  def error; end
  def init; end
  def reduce(i); end
  def reduce_n; end
  def shift(i); end
  def shift_n; end
end

class Racc::CompileError < ::Racc::Error; end
class Racc::CparseParams; end

class Racc::DebugFlags
  def initialize(parse = T.unsafe(nil), rule = T.unsafe(nil), token = T.unsafe(nil), state = T.unsafe(nil), la = T.unsafe(nil), prec = T.unsafe(nil), conf = T.unsafe(nil)); end

  def any?; end
  def la; end
  def parse; end
  def prec; end
  def rule; end
  def state; end
  def status_logging; end
  def token; end

  class << self
    def parse_option_string(s); end
  end
end

class Racc::Error < ::StandardError
  def inspect; end
end

class Racc::Goto
  def initialize(ident, sym, from, to); end

  def from_state; end
  def ident; end
  def inspect; end
  def symbol; end
  def to_state; end
end

class Racc::Grammar
  def initialize(debug_flags = T.unsafe(nil)); end

  def [](x); end
  def add(rule); end
  def added?(sym); end
  def declare_precedence(assoc, syms); end
  def dfa; end
  def each(&block); end
  def each_index(&block); end
  def each_nonterminal(*args, **_arg1, &block); end
  def each_rule(&block); end
  def each_symbol(*args, **_arg1, &block); end
  def each_terminal(*args, **_arg1, &block); end
  def each_useless_nonterminal; end
  def each_useless_rule; end
  def each_with_index(&block); end
  def end_precedence_declaration(reverse); end
  def init; end
  def intern(value, dummy = T.unsafe(nil)); end
  def n_expected_srconflicts; end
  def n_expected_srconflicts=(_arg0); end
  def n_useless_nonterminals; end
  def n_useless_rules; end
  def nfa; end
  def nonterminal_base; end
  def parser_class; end
  def size; end
  def start; end
  def start_symbol=(s); end
  def state_transition_table; end
  def states; end
  def symbols; end
  def symboltable; end
  def to_s; end
  def useless_nonterminal_exist?; end
  def useless_rule_exist?; end
  def write_log(path); end

  private

  def _compute_expand(t, set, lock); end
  def add_start_rule; end
  def check_rules_nullable(rules); end
  def check_rules_useless(rules); end
  def check_symbols_nullable(symbols); end
  def check_symbols_useless(s); end
  def compute_expand(t); end
  def compute_hash; end
  def compute_heads; end
  def compute_locate; end
  def compute_nullable; end
  def compute_nullable_0; end
  def compute_useless; end
  def determine_terminals; end
  def fix_ident; end

  class << self
    def define(&block); end
  end
end

class Racc::Grammar::DefinitionEnv
  def initialize; end

  def _(&block); end
  def _add(target, x); end
  def _added?(sym); end
  def _delayed_add(rule); end
  def _intern(x); end
  def action(&block); end
  def flush_delayed; end
  def grammar; end
  def many(sym, &block); end
  def many1(sym, &block); end
  def method_missing(mid, *args, &block); end
  def null(&block); end
  def option(sym, default = T.unsafe(nil), &block); end
  def precedence_table(&block); end
  def separated_by(sep, sym, &block); end
  def separated_by1(sep, sym, &block); end
  def seq(*list, &block); end

  private

  def _defmetasyntax(type, id, action, &block); end
  def _register(target_name); end
  def _wrap(target_name, sym, block); end
end

class Racc::Grammar::PrecedenceDefinitionEnv
  def initialize(g); end

  def higher; end
  def left(*syms); end
  def lower; end
  def nonassoc(*syms); end
  def reverse; end
  def right(*syms); end
end

class Racc::GrammarFileParser < ::Racc::Parser
  def initialize(debug_flags = T.unsafe(nil)); end

  def _racc_action_10(list, _, x); end
  def _racc_action_12(*_arg0); end
  def _racc_action_13(*_arg0); end
  def _racc_action_14(*_arg0); end
  def _racc_action_15(_, sym); end
  def _racc_action_16(_, syms); end
  def _racc_action_17(_, syms); end
  def _racc_action_18(_, num); end
  def _racc_action_19(x); end
  def _racc_action_2; end
  def _racc_action_20(list, x); end
  def _racc_action_21(x); end
  def _racc_action_22(list, x); end
  def _racc_action_23(sym, code); end
  def _racc_action_24(_, syms); end
  def _racc_action_25(_, syms); end
  def _racc_action_26(_, syms); end
  def _racc_action_27(sym); end
  def _racc_action_28(list, sym); end
  def _racc_action_3(list, x); end
  def _racc_action_30(sym); end
  def _racc_action_31(str); end
  def _racc_action_32(syms); end
  def _racc_action_33; end
  def _racc_action_34(list, x); end
  def _racc_action_35(list); end
  def _racc_action_36; end
  def _racc_action_38(sym); end
  def _racc_action_39(list, i); end
  def _racc_action_4; end
  def _racc_action_40(list, *_arg1); end
  def _racc_action_41(list, *_arg1); end
  def _racc_action_43(*_arg0); end
  def _racc_action_44(_, sym); end
  def _racc_action_45(src); end
  def _racc_action_6(name); end
  def _racc_action_7(c, _, s); end
  def _racc_action_8(syms); end
  def _racc_action_9(x); end
  def _reduce_0(vals, vstack); end
  def _reduce_1(vals, vstack); end
  def _reduce_10(vals, vstack); end
  def _reduce_11(vals, vstack); end
  def _reduce_12(vals, vstack); end
  def _reduce_13(vals, vstack); end
  def _reduce_14(vals, vstack); end
  def _reduce_15(vals, vstack); end
  def _reduce_16(vals, vstack); end
  def _reduce_17(vals, vstack); end
  def _reduce_18(vals, vstack); end
  def _reduce_19(vals, vstack); end
  def _reduce_2(vals, vstack); end
  def _reduce_20(vals, vstack); end
  def _reduce_21(vals, vstack); end
  def _reduce_22(vals, vstack); end
  def _reduce_23(vals, vstack); end
  def _reduce_24(vals, vstack); end
  def _reduce_25(vals, vstack); end
  def _reduce_26(vals, vstack); end
  def _reduce_27(vals, vstack); end
  def _reduce_28(vals, vstack); end
  def _reduce_29(vals, vstack); end
  def _reduce_3(vals, vstack); end
  def _reduce_30(vals, vstack); end
  def _reduce_31(vals, vstack); end
  def _reduce_32(vals, vstack); end
  def _reduce_33(vals, vstack); end
  def _reduce_34(vals, vstack); end
  def _reduce_35(vals, vstack); end
  def _reduce_36(vals, vstack); end
  def _reduce_37(vals, vstack); end
  def _reduce_38(vals, vstack); end
  def _reduce_39(vals, vstack); end
  def _reduce_4(vals, vstack); end
  def _reduce_40(vals, vstack); end
  def _reduce_41(vals, vstack); end
  def _reduce_42(vals, vstack); end
  def _reduce_43(vals, vstack); end
  def _reduce_44(vals, vstack); end
  def _reduce_45(vals, vstack); end
  def _reduce_5(vals, vstack); end
  def _reduce_6(vals, vstack); end
  def _reduce_7(vals, vstack); end
  def _reduce_8(vals, vstack); end
  def _reduce_9(vals, vstack); end
  def _reduce_none(vals, vstack); end
  def parse(src, filename = T.unsafe(nil), lineno = T.unsafe(nil)); end

  private

  def add_rule(target, list, sprec); end
  def add_rule_block(list); end
  def add_user_code(label, src); end
  def canonical_label(src); end
  def embedded_action(act); end
  def location; end
  def next_token; end
  def on_error(tok, val, _values); end
  def parse_user_code; end

  class << self
    def parse(src, filename = T.unsafe(nil), lineno = T.unsafe(nil)); end
    def parse_file(filename); end
  end
end

class Racc::GrammarFileParser::Result
  def initialize(grammar); end

  def grammar; end
  def params; end
end

class Racc::GrammarFileScanner
  def initialize(str, filename = T.unsafe(nil)); end

  def debug; end
  def debug=(_arg0); end
  def epilogue; end
  def lineno; end
  def yylex(&block); end

  private

  def atom_symbol(token); end
  def get_quoted_re(left); end
  def literal_head?(pre, post); end
  def next_line; end
  def read(len); end
  def reads(re); end
  def scan_action; end
  def scan_error!(msg); end
  def scan_quoted(left, tag = T.unsafe(nil)); end
  def skip_comment; end
  def yylex0; end
end

class Racc::ISet
  def initialize(a = T.unsafe(nil)); end

  def [](key); end
  def []=(key, val); end
  def add(i); end
  def clear; end
  def delete(key); end
  def dup; end
  def each(&block); end
  def empty?; end
  def include?(key); end
  def inspect; end
  def key?(key); end
  def set; end
  def size; end
  def to_a; end
  def to_s; end
  def update(other); end
  def update_a(a); end
end

class Racc::Item
  def initialize(rule, la); end

  def each_la(tbl); end
  def la; end
  def rule; end
end

class Racc::LocationPointer
  def initialize(rule, i, sym); end

  def ==(ot); end
  def before(len); end
  def dereference; end
  def eql?(ot); end
  def hash; end
  def head?; end
  def ident; end
  def increment; end
  def index; end
  def inspect; end
  def next; end
  def reduce; end
  def reduce?; end
  def rule; end
  def symbol; end
  def to_s; end

  private

  def ptr_bug!; end
end

class Racc::LogFileGenerator
  def initialize(states, debug_flags = T.unsafe(nil)); end

  def action_out(f, state); end
  def outact(f, t, act); end
  def output(out); end
  def output_conflict(out); end
  def output_rule(out); end
  def output_state(out); end
  def output_token(out); end
  def output_useless(out); end
  def outrrconf(f, confs); end
  def outsrconf(f, confs); end
  def pointer_out(out, ptr); end
  def symbol_locations(locs); end
end

class Racc::OrMark
  def initialize(lineno); end

  def inspect; end
  def lineno; end
  def name; end
end

class Racc::ParseError < ::StandardError; end

class Racc::Parser
  def _racc_do_parse_rb(arg, in_debug); end
  def _racc_do_reduce(arg, act); end
  def _racc_evalact(act, arg); end
  def _racc_init_sysvars; end
  def _racc_setup; end
  def _racc_yyparse_rb(recv, mid, arg, c_debug); end
  def do_parse; end
  def next_token; end
  def on_error(t, val, vstack); end
  def racc_accept; end
  def racc_e_pop(state, tstack, vstack); end
  def racc_next_state(curstate, state); end
  def racc_print_stacks(t, v); end
  def racc_print_states(s); end
  def racc_read_token(t, tok, val); end
  def racc_reduce(toks, sim, tstack, vstack); end
  def racc_shift(tok, tstack, vstack); end
  def racc_token2str(tok); end
  def token_to_str(t); end
  def yyaccept; end
  def yyerrok; end
  def yyerror; end
  def yyparse(recv, mid); end

  private

  def _racc_do_parse_c(_arg0, _arg1); end
  def _racc_yyparse_c(_arg0, _arg1, _arg2, _arg3); end

  class << self
    def racc_runtime_type; end
  end
end

class Racc::ParserClassGenerator
  def initialize(states); end

  def generate; end

  private

  def define_actions(c); end
end

class Racc::ParserFileGenerator
  def initialize(states, params); end

  def generate_parser; end
  def generate_parser_file(destpath); end
  def put_state_transition_table(f); end

  private

  def actions; end
  def cref_pop; end
  def cref_push(name); end
  def detab(str, ts = T.unsafe(nil)); end
  def embed_library(src); end
  def footer; end
  def header; end
  def i_i_sym_list(name, table); end
  def indent; end
  def indent_re(n); end
  def init_line_conversion_system; end
  def inner; end
  def integer_list(name, table); end
  def line(str = T.unsafe(nil)); end
  def make_delimiter(body); end
  def make_separator(src); end
  def minimum_indent(lines); end
  def n_indent(line); end
  def notice; end
  def parser_class(classname, superclass); end
  def parser_file; end
  def put(src, convert_line = T.unsafe(nil)); end
  def remove_blank_lines(src); end
  def replace_location(src); end
  def require(feature); end
  def runtime_source; end
  def shebang(path); end
  def state_transition_table; end
  def string_list(name, list); end
  def sym_int_hash(name, h); end
  def toplevel?; end
  def unindent_auto(str); end
  def unique_separator(id); end
end

class Racc::ParserFileGenerator::Params
  def initialize; end

  def classname; end
  def classname=(_arg0); end
  def convert_line=(b); end
  def convert_line?; end
  def convert_line_all=(b); end
  def convert_line_all?; end
  def debug_parser=(b); end
  def debug_parser?; end
  def embed_runtime=(b); end
  def embed_runtime?; end
  def filename; end
  def filename=(_arg0); end
  def footer; end
  def footer=(_arg0); end
  def header; end
  def header=(_arg0); end
  def inner; end
  def inner=(_arg0); end
  def interpreter; end
  def interpreter=(_arg0); end
  def make_executable=(b); end
  def make_executable?; end
  def omit_action_call=(b); end
  def omit_action_call?; end
  def result_var=(b); end
  def result_var?; end
  def superclass; end
  def superclass=(_arg0); end

  class << self
    def bool_attr(name); end
  end
end

class Racc::Prec
  def initialize(symbol, lineno); end

  def inspect; end
  def lineno; end
  def name; end
  def symbol; end
end

class Racc::RRconflict
  def initialize(sid, high, low, tok); end

  def high_prec; end
  def low_prec; end
  def stateid; end
  def to_s; end
  def token; end
end

class Racc::Reduce
  def initialize(rule); end

  def decref; end
  def incref; end
  def inspect; end
  def refn; end
  def rule; end
  def ruleid; end
end

class Racc::Rule
  def initialize(target, syms, act); end

  def ==(other); end
  def [](idx); end
  def accept?; end
  def action; end
  def each(&block); end
  def each_rule(&block); end
  def empty?; end
  def hash; end
  def hash=(n); end
  def ident; end
  def ident=(_arg0); end
  def inspect; end
  def null=(n); end
  def nullable?; end
  def prec(sym, &block); end
  def precedence; end
  def precedence=(sym); end
  def ptrs; end
  def replace(src, dest); end
  def rule; end
  def size; end
  def specified_prec; end
  def specified_prec=(_arg0); end
  def symbols; end
  def target; end
  def target=(_arg0); end
  def to_s; end
  def useless=(u); end
  def useless?; end
  def |(x); end
end

class Racc::SRconflict
  def initialize(sid, shift, reduce); end

  def reduce; end
  def shift; end
  def stateid; end
  def to_s; end
end

class Racc::Shift
  def initialize(goto); end

  def goto_id; end
  def goto_state; end
  def inspect; end
end

class Racc::SourceText
  def initialize(text, filename, lineno); end

  def filename; end
  def lineno; end
  def location; end
  def text; end
  def to_s; end
end

class Racc::State
  def initialize(ident, core); end

  def ==(oth); end
  def action; end
  def check_la(la_rules); end
  def closure; end
  def conflict?; end
  def core; end
  def defact; end
  def defact=(_arg0); end
  def eql?(oth); end
  def goto_table; end
  def gotos; end
  def hash; end
  def ident; end
  def inspect; end
  def la=(la); end
  def make_closure(core); end
  def n_rrconflicts; end
  def n_srconflicts; end
  def ritems; end
  def rr_conflict(high, low, ctok); end
  def rrconf; end
  def rruleid(rule); end
  def rrules; end
  def sr_conflict(shift, reduce); end
  def srconf; end
  def stateid; end
  def stokens; end
  def to_s; end
end

class Racc::StateTransitionTable < ::Struct
  def initialize(states); end

  def action_check; end
  def action_check=(_); end
  def action_default; end
  def action_default=(_); end
  def action_pointer; end
  def action_pointer=(_); end
  def action_table; end
  def action_table=(_); end
  def debug_parser; end
  def debug_parser=(_); end
  def goto_check; end
  def goto_check=(_); end
  def goto_default; end
  def goto_default=(_); end
  def goto_pointer; end
  def goto_pointer=(_); end
  def goto_table; end
  def goto_table=(_); end
  def grammar; end
  def nt_base; end
  def nt_base=(_); end
  def parser_class; end
  def reduce_n; end
  def reduce_n=(_); end
  def reduce_table; end
  def reduce_table=(_); end
  def shift_n; end
  def shift_n=(_); end
  def states; end
  def token_table; end
  def token_table=(_); end
  def token_to_s_table; end
  def token_to_s_table=(_); end
  def token_value_table; end
  def use_result_var; end
  def use_result_var=(_); end

  class << self
    def [](*_arg0); end
    def generate(states); end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

class Racc::StateTransitionTableGenerator
  def initialize(states); end

  def act2actid(act); end
  def addent(all, arr, chkval, ptr); end
  def gen_action_tables(t, states); end
  def gen_goto_tables(t, grammar); end
  def generate; end
  def mkmapexp(arr); end
  def reduce_table(grammar); end
  def set_table(entries, dummy, tbl, chk, ptr); end
  def token_table(grammar); end
end

class Racc::States
  def initialize(grammar, debug_flags = T.unsafe(nil)); end

  def [](i); end
  def actions; end
  def dfa; end
  def each(&block); end
  def each_index(&block); end
  def each_state(&block); end
  def grammar; end
  def inspect; end
  def n_rrconflicts; end
  def n_srconflicts; end
  def nfa; end
  def nt_base(*args, **_arg1, &block); end
  def reduce_n(*args, **_arg1, &block); end
  def rrconflict_exist?; end
  def shift_n(*args, **_arg1, &block); end
  def should_report_srconflict?; end
  def size; end
  def srconflict_exist?; end
  def state_transition_table; end
  def to_s; end

  private

  def addrel(tbl, i, item); end
  def addsym(table, sym, ptr); end
  def check_useless; end
  def compute_dfa; end
  def compute_nfa; end
  def core_to_state(core); end
  def create_tmap(size); end
  def digraph(map, relation); end
  def do_resolve_sr(stok, rtok); end
  def each_t(tbl, set); end
  def fingerprint(arr); end
  def generate_states(state); end
  def lookahead; end
  def pack(state); end
  def print_atab(idx, tab); end
  def print_tab(idx, rel, tab); end
  def print_tab_i(idx, rel, tab, i); end
  def printb(i); end
  def record_path(begst, rule); end
  def resolve(state); end
  def resolve_rr(state, r); end
  def resolve_sr(state, s); end
  def set_accept; end
  def transpose(rel); end
  def traverse(i, index, vertices, map, relation); end
end

class Racc::Sym
  def initialize(value, dummyp); end

  def assoc; end
  def assoc=(_arg0); end
  def dummy?; end
  def expand; end
  def expand=(v); end
  def hash; end
  def heads; end
  def ident; end
  def ident=(v); end
  def inspect; end
  def locate; end
  def nonterminal?; end
  def null=(n); end
  def nullable?; end
  def precedence; end
  def precedence=(_arg0); end
  def rule; end
  def self_null?; end
  def serialize; end
  def serialized=(_arg0); end
  def should_terminal; end
  def should_terminal?; end
  def snull=(v); end
  def string_symbol?; end
  def term=(t); end
  def terminal?; end
  def to_s; end
  def useless=(f); end
  def useless?; end
  def value; end
  def |(x); end

  class << self
    def once_writer(nm); end
  end
end

class Racc::SymbolTable
  def initialize; end

  def [](id); end
  def anchor; end
  def delete(sym); end
  def dummy; end
  def each(&block); end
  def each_nonterminal(&block); end
  def each_terminal(&block); end
  def error; end
  def fix; end
  def intern(val, dummy = T.unsafe(nil)); end
  def nonterminals; end
  def nt_base; end
  def nt_max; end
  def symbols; end
  def terminals(&block); end
  def to_a; end

  private

  def check_terminals; end
  def fix_ident; end
end

class Racc::UserAction
  def initialize(src, proc); end

  def empty?; end
  def inspect; end
  def name; end
  def proc; end
  def proc?; end
  def source; end
  def source?; end

  class << self
    def empty; end
    def proc(pr = T.unsafe(nil), &block); end
    def source_text(src); end

    private

    def new(*_arg0); end
  end
end

module SingleForwardable
  def def_delegator(accessor, method, ali = T.unsafe(nil)); end
  def def_delegators(accessor, *methods); end
  def def_single_delegator(accessor, method, ali = T.unsafe(nil)); end
  def def_single_delegators(accessor, *methods); end
  def delegate(hash); end
  def single_delegate(hash); end
end

class StringIO
  include ::Enumerable

  def initialize(*_arg0); end

  def binmode; end
  def close; end
  def close_read; end
  def close_write; end
  def closed?; end
  def closed_read?; end
  def closed_write?; end
  def each(*_arg0); end
  def each_byte; end
  def each_char; end
  def each_codepoint; end
  def each_line(*_arg0); end
  def eof; end
  def eof?; end
  def external_encoding; end
  def fcntl(*_arg0); end
  def fileno; end
  def flush; end
  def fsync; end
  def getbyte; end
  def getc; end
  def gets(*_arg0); end
  def internal_encoding; end
  def isatty; end
  def length; end
  def lineno; end
  def lineno=(_arg0); end
  def pid; end
  def pos; end
  def pos=(_arg0); end
  def putc(_arg0); end
  def read(*_arg0); end
  def readlines(*_arg0); end
  def reopen(*_arg0); end
  def rewind; end
  def seek(*_arg0); end
  def set_encoding(*_arg0); end
  def set_encoding_by_bom; end
  def size; end
  def string; end
  def string=(_arg0); end
  def sync; end
  def sync=(_arg0); end
  def tell; end
  def truncate(_arg0); end
  def tty?; end
  def ungetbyte(_arg0); end
  def ungetc(_arg0); end
  def write(*_arg0); end

  private

  def initialize_copy(_arg0); end

  class << self
    def new(*_arg0); end
    def open(*_arg0); end
  end
end
