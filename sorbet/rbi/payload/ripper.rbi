# typed: __STDLIB_INTERNAL

class Ripper
  def initialize(*_arg0); end

  def column; end
  def debug_output; end
  def debug_output=(_arg0); end
  def encoding; end
  def end_seen?; end
  def error?; end
  def filename; end
  def lineno; end
  def parse; end
  def state; end
  def token; end
  def yydebug; end
  def yydebug=(_arg0); end

  private

  def _dispatch_0; end
  def _dispatch_1(a); end
  def _dispatch_2(a, b); end
  def _dispatch_3(a, b, c); end
  def _dispatch_4(a, b, c, d); end
  def _dispatch_5(a, b, c, d, e); end
  def _dispatch_6(a, b, c, d, e, f); end
  def _dispatch_7(a, b, c, d, e, f, g); end
  def compile_error(msg); end
  def dedent_string(_arg0, _arg1); end
  def on_BEGIN(a); end
  def on_CHAR(a); end
  def on_END(a); end
  def on___end__(a); end
  def on_alias(a, b); end
  def on_alias_error(a, b); end
  def on_aref(a, b); end
  def on_aref_field(a, b); end
  def on_arg_ambiguous(a); end
  def on_arg_paren(a); end
  def on_args_add(a, b); end
  def on_args_add_block(a, b); end
  def on_args_add_star(a, b); end
  def on_args_forward; end
  def on_args_new; end
  def on_array(a); end
  def on_aryptn(a, b, c, d); end
  def on_assign(a, b); end
  def on_assign_error(a, b); end
  def on_assoc_new(a, b); end
  def on_assoc_splat(a); end
  def on_assoclist_from_args(a); end
  def on_backref(a); end
  def on_backtick(a); end
  def on_bare_assoc_hash(a); end
  def on_begin(a); end
  def on_binary(a, b, c); end
  def on_block_var(a, b); end
  def on_blockarg(a); end
  def on_bodystmt(a, b, c, d); end
  def on_brace_block(a, b); end
  def on_break(a); end
  def on_call(a, b, c); end
  def on_case(a, b); end
  def on_class(a, b, c); end
  def on_class_name_error(a, b); end
  def on_comma(a); end
  def on_command(a, b); end
  def on_command_call(a, b, c, d); end
  def on_comment(a); end
  def on_const(a); end
  def on_const_path_field(a, b); end
  def on_const_path_ref(a, b); end
  def on_const_ref(a); end
  def on_cvar(a); end
  def on_def(a, b, c); end
  def on_defined(a); end
  def on_defs(a, b, c, d, e); end
  def on_do_block(a, b); end
  def on_dot2(a, b); end
  def on_dot3(a, b); end
  def on_dyna_symbol(a); end
  def on_else(a); end
  def on_elsif(a, b, c); end
  def on_embdoc(a); end
  def on_embdoc_beg(a); end
  def on_embdoc_end(a); end
  def on_embexpr_beg(a); end
  def on_embexpr_end(a); end
  def on_embvar(a); end
  def on_ensure(a); end
  def on_excessed_comma; end
  def on_fcall(a); end
  def on_field(a, b, c); end
  def on_float(a); end
  def on_fndptn(a, b, c, d); end
  def on_for(a, b, c); end
  def on_gvar(a); end
  def on_hash(a); end
  def on_heredoc_beg(a); end
  def on_heredoc_dedent(a, b); end
  def on_heredoc_end(a); end
  def on_hshptn(a, b, c); end
  def on_ident(a); end
  def on_if(a, b, c); end
  def on_if_mod(a, b); end
  def on_ifop(a, b, c); end
  def on_ignored_nl(a); end
  def on_imaginary(a); end
  def on_in(a, b, c); end
  def on_int(a); end
  def on_ivar(a); end
  def on_kw(a); end
  def on_kwrest_param(a); end
  def on_label(a); end
  def on_label_end(a); end
  def on_lambda(a, b); end
  def on_lbrace(a); end
  def on_lbracket(a); end
  def on_lparen(a); end
  def on_magic_comment(a, b); end
  def on_massign(a, b); end
  def on_method_add_arg(a, b); end
  def on_method_add_block(a, b); end
  def on_mlhs_add(a, b); end
  def on_mlhs_add_post(a, b); end
  def on_mlhs_add_star(a, b); end
  def on_mlhs_new; end
  def on_mlhs_paren(a); end
  def on_module(a, b); end
  def on_mrhs_add(a, b); end
  def on_mrhs_add_star(a, b); end
  def on_mrhs_new; end
  def on_mrhs_new_from_args(a); end
  def on_next(a); end
  def on_nl(a); end
  def on_nokw_param(a); end
  def on_op(a); end
  def on_opassign(a, b, c); end
  def on_operator_ambiguous(a, b); end
  def on_param_error(a, b); end
  def on_params(a, b, c, d, e, f, g); end
  def on_paren(a); end
  def on_parse_error(a); end
  def on_period(a); end
  def on_program(a); end
  def on_qsymbols_add(a, b); end
  def on_qsymbols_beg(a); end
  def on_qsymbols_new; end
  def on_qwords_add(a, b); end
  def on_qwords_beg(a); end
  def on_qwords_new; end
  def on_rational(a); end
  def on_rbrace(a); end
  def on_rbracket(a); end
  def on_redo; end
  def on_regexp_add(a, b); end
  def on_regexp_beg(a); end
  def on_regexp_end(a); end
  def on_regexp_literal(a, b); end
  def on_regexp_new; end
  def on_rescue(a, b, c, d); end
  def on_rescue_mod(a, b); end
  def on_rest_param(a); end
  def on_retry; end
  def on_return(a); end
  def on_return0; end
  def on_rparen(a); end
  def on_sclass(a, b); end
  def on_semicolon(a); end
  def on_sp(a); end
  def on_stmts_add(a, b); end
  def on_stmts_new; end
  def on_string_add(a, b); end
  def on_string_concat(a, b); end
  def on_string_content; end
  def on_string_dvar(a); end
  def on_string_embexpr(a); end
  def on_string_literal(a); end
  def on_super(a); end
  def on_symbeg(a); end
  def on_symbol(a); end
  def on_symbol_literal(a); end
  def on_symbols_add(a, b); end
  def on_symbols_beg(a); end
  def on_symbols_new; end
  def on_tlambda(a); end
  def on_tlambeg(a); end
  def on_top_const_field(a); end
  def on_top_const_ref(a); end
  def on_tstring_beg(a); end
  def on_tstring_content(a); end
  def on_tstring_end(a); end
  def on_unary(a, b); end
  def on_undef(a); end
  def on_unless(a, b, c); end
  def on_unless_mod(a, b); end
  def on_until(a, b); end
  def on_until_mod(a, b); end
  def on_var_alias(a, b); end
  def on_var_field(a); end
  def on_var_ref(a); end
  def on_vcall(a); end
  def on_void_stmt; end
  def on_when(a, b, c); end
  def on_while(a, b); end
  def on_while_mod(a, b); end
  def on_word_add(a, b); end
  def on_word_new; end
  def on_words_add(a, b); end
  def on_words_beg(a); end
  def on_words_new; end
  def on_words_sep(a); end
  def on_xstring_add(a, b); end
  def on_xstring_literal(a); end
  def on_xstring_new; end
  def on_yield(a); end
  def on_yield0; end
  def on_zsuper; end
  def warn(fmt, *args); end
  def warning(fmt, *args); end

  class << self
    def dedent_string(_arg0, _arg1); end
    def lex(src, filename = T.unsafe(nil), lineno = T.unsafe(nil), **kw); end
    def lex_state_name(_arg0); end
    def parse(src, filename = T.unsafe(nil), lineno = T.unsafe(nil)); end
    def sexp(src, filename = T.unsafe(nil), lineno = T.unsafe(nil), raise_errors: T.unsafe(nil)); end
    def sexp_raw(src, filename = T.unsafe(nil), lineno = T.unsafe(nil), raise_errors: T.unsafe(nil)); end
    def slice(src, pattern, n = T.unsafe(nil)); end
    def token_match(src, pattern); end
    def tokenize(src, filename = T.unsafe(nil), lineno = T.unsafe(nil), **kw); end
  end
end

class Ripper::Filter
  def initialize(src, filename = T.unsafe(nil), lineno = T.unsafe(nil)); end

  def column; end
  def filename; end
  def lineno; end
  def parse(init = T.unsafe(nil)); end
  def state; end

  private

  def on_default(event, token, data); end
end

class Ripper::Lexer < ::Ripper
  def errors; end
  def lex(**kw); end
  def parse(raise_errors: T.unsafe(nil)); end
  def scan(**kw); end
  def tokenize(**kw); end

  private

  def _push_token(tok); end
  def compile_error(mesg); end
  def on_CHAR(tok); end
  def on___end__(tok); end
  def on_alias_error(mesg, elem); end
  def on_assign_error(mesg, elem); end
  def on_backref(tok); end
  def on_backtick(tok); end
  def on_class_name_error(mesg, elem); end
  def on_comma(tok); end
  def on_comment(tok); end
  def on_const(tok); end
  def on_cvar(tok); end
  def on_embdoc(tok); end
  def on_embdoc_beg(tok); end
  def on_embdoc_end(tok); end
  def on_embexpr_beg(tok); end
  def on_embexpr_end(tok); end
  def on_embvar(tok); end
  def on_error1(mesg); end
  def on_error2(mesg, elem); end
  def on_float(tok); end
  def on_gvar(tok); end
  def on_heredoc_beg(tok); end
  def on_heredoc_dedent(v, w); end
  def on_heredoc_end(tok); end
  def on_ident(tok); end
  def on_ignored_nl(tok); end
  def on_ignored_sp(tok); end
  def on_imaginary(tok); end
  def on_int(tok); end
  def on_ivar(tok); end
  def on_kw(tok); end
  def on_label(tok); end
  def on_label_end(tok); end
  def on_lbrace(tok); end
  def on_lbracket(tok); end
  def on_lparen(tok); end
  def on_nl(tok); end
  def on_op(tok); end
  def on_param_error(mesg, elem); end
  def on_parse_error(mesg); end
  def on_period(tok); end
  def on_qsymbols_beg(tok); end
  def on_qwords_beg(tok); end
  def on_rational(tok); end
  def on_rbrace(tok); end
  def on_rbracket(tok); end
  def on_regexp_beg(tok); end
  def on_regexp_end(tok); end
  def on_rparen(tok); end
  def on_semicolon(tok); end
  def on_sp(tok); end
  def on_symbeg(tok); end
  def on_symbols_beg(tok); end
  def on_tlambda(tok); end
  def on_tlambeg(tok); end
  def on_tstring_beg(tok); end
  def on_tstring_content(tok); end
  def on_tstring_end(tok); end
  def on_words_beg(tok); end
  def on_words_sep(tok); end
end

class Ripper::Lexer::Elem
  def initialize(pos, event, tok, state, message = T.unsafe(nil)); end

  def [](index); end
  def event; end
  def event=(_arg0); end
  def inspect; end
  def message; end
  def message=(_arg0); end
  def pos; end
  def pos=(_arg0); end
  def pretty_print(q); end
  def state; end
  def state=(_arg0); end
  def to_a; end
  def to_s; end
  def tok; end
  def tok=(_arg0); end
end

class Ripper::Lexer::State
  def initialize(i); end

  def &(i); end
  def ==(i); end
  def [](index); end
  def allbits?(i); end
  def anybits?(i); end
  def inspect; end
  def nobits?(i); end
  def pretty_print(q); end
  def to_i; end
  def to_int; end
  def to_s; end
  def |(i); end
end

class Ripper::SexpBuilder < ::Ripper
  def error; end
  def on_BEGIN(*args); end
  def on_CHAR(tok); end
  def on_END(*args); end
  def on___end__(tok); end
  def on_alias(*args); end
  def on_alias_error(*args); end
  def on_aref(*args); end
  def on_aref_field(*args); end
  def on_arg_ambiguous(*args); end
  def on_arg_paren(*args); end
  def on_args_add(*args); end
  def on_args_add_block(*args); end
  def on_args_add_star(*args); end
  def on_args_forward(*args); end
  def on_args_new(*args); end
  def on_array(*args); end
  def on_aryptn(*args); end
  def on_assign(*args); end
  def on_assign_error(*args); end
  def on_assoc_new(*args); end
  def on_assoc_splat(*args); end
  def on_assoclist_from_args(*args); end
  def on_backref(tok); end
  def on_backtick(tok); end
  def on_bare_assoc_hash(*args); end
  def on_begin(*args); end
  def on_binary(*args); end
  def on_block_var(*args); end
  def on_blockarg(*args); end
  def on_bodystmt(*args); end
  def on_brace_block(*args); end
  def on_break(*args); end
  def on_call(*args); end
  def on_case(*args); end
  def on_class(*args); end
  def on_class_name_error(*args); end
  def on_comma(tok); end
  def on_command(*args); end
  def on_command_call(*args); end
  def on_comment(tok); end
  def on_const(tok); end
  def on_const_path_field(*args); end
  def on_const_path_ref(*args); end
  def on_const_ref(*args); end
  def on_cvar(tok); end
  def on_def(*args); end
  def on_defined(*args); end
  def on_defs(*args); end
  def on_do_block(*args); end
  def on_dot2(*args); end
  def on_dot3(*args); end
  def on_dyna_symbol(*args); end
  def on_else(*args); end
  def on_elsif(*args); end
  def on_embdoc(tok); end
  def on_embdoc_beg(tok); end
  def on_embdoc_end(tok); end
  def on_embexpr_beg(tok); end
  def on_embexpr_end(tok); end
  def on_embvar(tok); end
  def on_ensure(*args); end
  def on_excessed_comma(*args); end
  def on_fcall(*args); end
  def on_field(*args); end
  def on_float(tok); end
  def on_fndptn(*args); end
  def on_for(*args); end
  def on_gvar(tok); end
  def on_hash(*args); end
  def on_heredoc_beg(tok); end
  def on_heredoc_end(tok); end
  def on_hshptn(*args); end
  def on_ident(tok); end
  def on_if(*args); end
  def on_if_mod(*args); end
  def on_ifop(*args); end
  def on_ignored_nl(tok); end
  def on_ignored_sp(tok); end
  def on_imaginary(tok); end
  def on_in(*args); end
  def on_int(tok); end
  def on_ivar(tok); end
  def on_kw(tok); end
  def on_kwrest_param(*args); end
  def on_label(tok); end
  def on_label_end(tok); end
  def on_lambda(*args); end
  def on_lbrace(tok); end
  def on_lbracket(tok); end
  def on_lparen(tok); end
  def on_magic_comment(*args); end
  def on_massign(*args); end
  def on_method_add_arg(*args); end
  def on_method_add_block(*args); end
  def on_mlhs_add(*args); end
  def on_mlhs_add_post(*args); end
  def on_mlhs_add_star(*args); end
  def on_mlhs_new(*args); end
  def on_mlhs_paren(*args); end
  def on_module(*args); end
  def on_mrhs_add(*args); end
  def on_mrhs_add_star(*args); end
  def on_mrhs_new(*args); end
  def on_mrhs_new_from_args(*args); end
  def on_next(*args); end
  def on_nl(tok); end
  def on_nokw_param(*args); end
  def on_op(tok); end
  def on_opassign(*args); end
  def on_operator_ambiguous(*args); end
  def on_param_error(*args); end
  def on_params(*args); end
  def on_paren(*args); end
  def on_period(tok); end
  def on_program(*args); end
  def on_qsymbols_add(*args); end
  def on_qsymbols_beg(tok); end
  def on_qsymbols_new(*args); end
  def on_qwords_add(*args); end
  def on_qwords_beg(tok); end
  def on_qwords_new(*args); end
  def on_rational(tok); end
  def on_rbrace(tok); end
  def on_rbracket(tok); end
  def on_redo(*args); end
  def on_regexp_add(*args); end
  def on_regexp_beg(tok); end
  def on_regexp_end(tok); end
  def on_regexp_literal(*args); end
  def on_regexp_new(*args); end
  def on_rescue(*args); end
  def on_rescue_mod(*args); end
  def on_rest_param(*args); end
  def on_retry(*args); end
  def on_return(*args); end
  def on_return0(*args); end
  def on_rparen(tok); end
  def on_sclass(*args); end
  def on_semicolon(tok); end
  def on_sp(tok); end
  def on_stmts_add(*args); end
  def on_stmts_new(*args); end
  def on_string_add(*args); end
  def on_string_concat(*args); end
  def on_string_content(*args); end
  def on_string_dvar(*args); end
  def on_string_embexpr(*args); end
  def on_string_literal(*args); end
  def on_super(*args); end
  def on_symbeg(tok); end
  def on_symbol(*args); end
  def on_symbol_literal(*args); end
  def on_symbols_add(*args); end
  def on_symbols_beg(tok); end
  def on_symbols_new(*args); end
  def on_tlambda(tok); end
  def on_tlambeg(tok); end
  def on_top_const_field(*args); end
  def on_top_const_ref(*args); end
  def on_tstring_beg(tok); end
  def on_tstring_content(tok); end
  def on_tstring_end(tok); end
  def on_unary(*args); end
  def on_undef(*args); end
  def on_unless(*args); end
  def on_unless_mod(*args); end
  def on_until(*args); end
  def on_until_mod(*args); end
  def on_var_alias(*args); end
  def on_var_field(*args); end
  def on_var_ref(*args); end
  def on_vcall(*args); end
  def on_void_stmt(*args); end
  def on_when(*args); end
  def on_while(*args); end
  def on_while_mod(*args); end
  def on_word_add(*args); end
  def on_word_new(*args); end
  def on_words_add(*args); end
  def on_words_beg(tok); end
  def on_words_new(*args); end
  def on_words_sep(tok); end
  def on_xstring_add(*args); end
  def on_xstring_literal(*args); end
  def on_xstring_new(*args); end
  def on_yield(*args); end
  def on_yield0(*args); end
  def on_zsuper(*args); end

  private

  def compile_error(mesg); end
  def dedent_element(e, width); end
  def on_error(mesg); end
  def on_heredoc_dedent(val, width); end
  def on_parse_error(mesg); end
end

class Ripper::SexpBuilderPP < ::Ripper::SexpBuilder
  private

  def _dispatch_event_new; end
  def _dispatch_event_push(list, item); end
  def on_args_add(list, item); end
  def on_args_new; end
  def on_heredoc_dedent(val, width); end
  def on_mlhs_add(list, item); end
  def on_mlhs_add_post(list, post); end
  def on_mlhs_add_star(list, star); end
  def on_mlhs_new; end
  def on_mlhs_paren(list); end
  def on_mrhs_add(list, item); end
  def on_mrhs_new; end
  def on_qsymbols_add(list, item); end
  def on_qsymbols_new; end
  def on_qwords_add(list, item); end
  def on_qwords_new; end
  def on_regexp_add(list, item); end
  def on_regexp_new; end
  def on_stmts_add(list, item); end
  def on_stmts_new; end
  def on_string_add(list, item); end
  def on_symbols_add(list, item); end
  def on_symbols_new; end
  def on_word_add(list, item); end
  def on_word_new; end
  def on_words_add(list, item); end
  def on_words_new; end
  def on_xstring_add(list, item); end
  def on_xstring_new; end
end

class Ripper::TokenPattern
  def initialize(pattern); end

  def match(str); end
  def match_list(tokens); end

  private

  def compile(pattern); end
  def map_token(tok); end
  def map_tokens(tokens); end

  class << self
    def compile(*_arg0); end
  end
end

class Ripper::TokenPattern::CompileError < ::Ripper::TokenPattern::Error; end
class Ripper::TokenPattern::Error < ::StandardError; end

class Ripper::TokenPattern::MatchData
  def initialize(tokens, match); end

  def string(n = T.unsafe(nil)); end

  private

  def match(n = T.unsafe(nil)); end
end

class Ripper::TokenPattern::MatchError < ::Ripper::TokenPattern::Error; end
