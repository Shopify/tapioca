# typed: __STDLIB_INTERNAL

module Readline
  private

  def readline(*_arg0); end

  class << self
    def basic_quote_characters; end
    def basic_quote_characters=(_arg0); end
    def basic_word_break_characters; end
    def basic_word_break_characters=(_arg0); end
    def completer_quote_characters; end
    def completer_quote_characters=(_arg0); end
    def completer_word_break_characters; end
    def completer_word_break_characters=(_arg0); end
    def completion_append_character; end
    def completion_append_character=(_arg0); end
    def completion_case_fold; end
    def completion_case_fold=(_arg0); end
    def completion_proc; end
    def completion_proc=(_arg0); end
    def completion_quote_character; end
    def delete_text(*_arg0); end
    def emacs_editing_mode; end
    def emacs_editing_mode?; end
    def filename_quote_characters; end
    def filename_quote_characters=(_arg0); end
    def get_screen_size; end
    def input=(_arg0); end
    def insert_text(_arg0); end
    def line_buffer; end
    def output=(_arg0); end
    def point; end
    def point=(_arg0); end
    def pre_input_hook; end
    def pre_input_hook=(_arg0); end
    def quoting_detection_proc; end
    def quoting_detection_proc=(_arg0); end
    def readline(*_arg0); end
    def redisplay; end
    def refresh_line; end
    def set_screen_size(_arg0, _arg1); end
    def special_prefixes; end
    def special_prefixes=(_arg0); end
    def vi_editing_mode; end
    def vi_editing_mode?; end
  end
end
