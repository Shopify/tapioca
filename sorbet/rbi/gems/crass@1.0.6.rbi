# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `crass` gem.
# Please instead update this file by running `bin/tapioca gem crass`.

# typed: true

# A CSS parser based on the CSS Syntax Module Level 3 spec.
module Crass
  class << self
    # Parses _input_ as a CSS stylesheet and returns a parse tree.
    #
    # See {Tokenizer#initialize} for _options_.
    def parse(input, options = T.unsafe(nil)); end

    # Parses _input_ as a string of CSS properties (such as the contents of an
    # HTML element's `style` attribute) and returns a parse tree.
    #
    # See {Tokenizer#initialize} for _options_.
    def parse_properties(input, options = T.unsafe(nil)); end
  end
end

# Parses a CSS string or list of tokens.
#
# 5. http://dev.w3.org/csswg/css-syntax/#parsing
class Crass::Parser
  # Initializes a parser based on the given _input_, which may be a CSS string
  # or an array of tokens.
  #
  # See {Tokenizer#initialize} for _options_.
  def initialize(input, options = T.unsafe(nil)); end

  # Consumes an at-rule and returns it.
  #
  # 5.4.2. http://dev.w3.org/csswg/css-syntax-3/#consume-at-rule
  def consume_at_rule(input = T.unsafe(nil)); end

  # Consumes a component value and returns it, or `nil` if there are no more
  # tokens.
  #
  # 5.4.6. http://dev.w3.org/csswg/css-syntax-3/#consume-a-component-value
  def consume_component_value(input = T.unsafe(nil)); end

  # Consumes a declaration and returns it, or `nil` on parse error.
  #
  # 5.4.5. http://dev.w3.org/csswg/css-syntax-3/#consume-a-declaration
  def consume_declaration(input = T.unsafe(nil)); end

  # Consumes a list of declarations and returns them.
  #
  # By default, the returned list may include `:comment`, `:semicolon`, and
  # `:whitespace` nodes, which is non-standard.
  #
  # Options:
  #
  # * **:strict** - Set to `true` to exclude non-standard `:comment`,
  # `:semicolon`, and `:whitespace` nodes.
  #
  # 5.4.4. http://dev.w3.org/csswg/css-syntax/#consume-a-list-of-declarations
  def consume_declarations(input = T.unsafe(nil), options = T.unsafe(nil)); end

  # Consumes a function and returns it.
  #
  # 5.4.8. http://dev.w3.org/csswg/css-syntax-3/#consume-a-function
  def consume_function(input = T.unsafe(nil)); end

  # Consumes a qualified rule and returns it, or `nil` if a parse error
  # occurs.
  #
  # 5.4.3. http://dev.w3.org/csswg/css-syntax-3/#consume-a-qualified-rule
  def consume_qualified_rule(input = T.unsafe(nil)); end

  # Consumes a list of rules and returns them.
  #
  # 5.4.1. http://dev.w3.org/csswg/css-syntax/#consume-a-list-of-rules
  def consume_rules(flags = T.unsafe(nil)); end

  # Consumes and returns a simple block associated with the current input
  # token.
  #
  # 5.4.7. http://dev.w3.org/csswg/css-syntax/#consume-a-simple-block
  def consume_simple_block(input = T.unsafe(nil)); end

  # Creates and returns a new parse node with the given _properties_.
  def create_node(type, properties = T.unsafe(nil)); end

  # Parses the given _input_ tokens into a selector node and returns it.
  #
  # Doesn't bother splitting the selector list into individual selectors or
  # validating them. Feel free to do that yourself! It'll be fun!
  def create_selector(input); end

  # Creates a `:style_rule` node from the given qualified _rule_, and returns
  # it.
  def create_style_rule(rule); end

  # Parses a single component value and returns it.
  #
  # 5.3.7. http://dev.w3.org/csswg/css-syntax-3/#parse-a-component-value
  def parse_component_value(input = T.unsafe(nil)); end

  # Parses a list of component values and returns an array of parsed tokens.
  #
  # 5.3.8. http://dev.w3.org/csswg/css-syntax/#parse-a-list-of-component-values
  def parse_component_values(input = T.unsafe(nil)); end

  # Parses a single declaration and returns it.
  #
  # 5.3.5. http://dev.w3.org/csswg/css-syntax/#parse-a-declaration
  def parse_declaration(input = T.unsafe(nil)); end

  # Parses a list of declarations and returns them.
  #
  # See {#consume_declarations} for _options_.
  #
  # 5.3.6. http://dev.w3.org/csswg/css-syntax/#parse-a-list-of-declarations
  def parse_declarations(input = T.unsafe(nil), options = T.unsafe(nil)); end

  # Parses a list of declarations and returns an array of `:property` nodes
  # (and any non-declaration nodes that were in the input). This is useful for
  # parsing the contents of an HTML element's `style` attribute.
  def parse_properties(input = T.unsafe(nil)); end

  # Parses a single rule and returns it.
  #
  # 5.3.4. http://dev.w3.org/csswg/css-syntax-3/#parse-a-rule
  def parse_rule(input = T.unsafe(nil)); end

  # Returns the unescaped value of a selector name or property declaration.
  def parse_value(nodes); end

  # {TokenScanner} wrapping the tokens generated from this parser's input.
  def tokens; end

  class << self
    # Parses CSS properties (such as the contents of an HTML element's `style`
    # attribute) and returns a parse tree.
    #
    # See {Tokenizer#initialize} for _options_.
    #
    # 5.3.6. http://dev.w3.org/csswg/css-syntax/#parse-a-list-of-declarations
    def parse_properties(input, options = T.unsafe(nil)); end

    # Parses CSS rules (such as the content of a `@media` block) and returns a
    # parse tree. The only difference from {parse_stylesheet} is that CDO/CDC
    # nodes (`<!--` and `-->`) aren't ignored.
    #
    # See {Tokenizer#initialize} for _options_.
    #
    # 5.3.3. http://dev.w3.org/csswg/css-syntax/#parse-a-list-of-rules
    def parse_rules(input, options = T.unsafe(nil)); end

    # Parses a CSS stylesheet and returns a parse tree.
    #
    # See {Tokenizer#initialize} for _options_.
    #
    # 5.3.2. http://dev.w3.org/csswg/css-syntax/#parse-a-stylesheet
    def parse_stylesheet(input, options = T.unsafe(nil)); end

    # Converts a node or array of nodes into a CSS string based on their
    # original tokenized input.
    #
    # Options:
    #
    # * **:exclude_comments** - When `true`, comments will be excluded.
    def stringify(nodes, options = T.unsafe(nil)); end
  end
end

Crass::Parser::BLOCK_END_TOKENS = T.let(T.unsafe(nil), Hash)

# Similar to a StringScanner, but with extra functionality needed to tokenize
# CSS while preserving the original text.
class Crass::Scanner
  # Creates a Scanner instance for the given _input_ string or IO instance.
  def initialize(input); end

  # Consumes the next character and returns it, advancing the pointer, or
  # an empty string if the end of the string has been reached.
  def consume; end

  # Consumes the rest of the string and returns it, advancing the pointer to
  # the end of the string. Returns an empty string is the end of the string
  # has already been reached.
  def consume_rest; end

  # Current character, or `nil` if the scanner hasn't yet consumed a
  # character, or is at the end of the string.
  def current; end

  # Returns `true` if the end of the string has been reached, `false`
  # otherwise.
  def eos?; end

  # Sets the marker to the position of the next character that will be
  # consumed.
  def mark; end

  # Returns the substring between {#marker} and {#pos}, without altering the
  # pointer.
  def marked; end

  # Current marker position. Use {#marked} to get the substring between
  # {#marker} and {#pos}.
  def marker; end

  # Current marker position. Use {#marked} to get the substring between
  # {#marker} and {#pos}.
  def marker=(_arg0); end

  # Returns up to _length_ characters starting at the current position, but
  # doesn't consume them. The number of characters returned may be less than
  # _length_ if the end of the string is reached.
  def peek(length = T.unsafe(nil)); end

  # Position of the next character that will be consumed. This is a character
  # position, not a byte position, so it accounts for multi-byte characters.
  def pos; end

  # Position of the next character that will be consumed. This is a character
  # position, not a byte position, so it accounts for multi-byte characters.
  def pos=(_arg0); end

  # Moves the pointer back one character without changing the value of
  # {#current}. The next call to {#consume} will re-consume the current
  # character.
  def reconsume; end

  # Resets the pointer to the beginning of the string.
  def reset; end

  # Tries to match _pattern_ at the current position. If it matches, the
  # matched substring will be returned and the pointer will be advanced.
  # Otherwise, `nil` will be returned.
  def scan(pattern); end

  # Scans the string until the _pattern_ is matched. Returns the substring up
  # to and including the end of the match, and advances the pointer. If there
  # is no match, `nil` is returned and the pointer is not advanced.
  def scan_until(pattern); end

  # String being scanned.
  def string; end
end

# Like {Scanner}, but for tokens!
class Crass::TokenScanner
  def initialize(tokens); end

  # Executes the given block, collects all tokens that are consumed during its
  # execution, and returns them.
  def collect; end

  # Consumes the next token and returns it, advancing the pointer. Returns
  # `nil` if there is no next token.
  def consume; end

  # Returns the value of attribute current.
  def current; end

  # Returns the next token without consuming it, or `nil` if there is no next
  # token.
  def peek; end

  # Returns the value of attribute pos.
  def pos; end

  # Reconsumes the current token, moving the pointer back one position.
  #
  # http://www.w3.org/TR/2013/WD-css-syntax-3-20130919/#reconsume-the-current-input-token
  def reconsume; end

  # Resets the pointer to the first token in the list.
  def reset; end

  # Returns the value of attribute tokens.
  def tokens; end
end

# Tokenizes a CSS string.
#
# 4. http://dev.w3.org/csswg/css-syntax/#tokenization
class Crass::Tokenizer
  # Initializes a new Tokenizer.
  #
  # Options:
  #
  # * **:preserve_comments** - If `true`, comments will be preserved as
  # `:comment` tokens.
  #
  # * **:preserve_hacks** - If `true`, certain non-standard browser hacks
  # such as the IE "*" hack will be preserved even though they violate
  # CSS 3 syntax rules.
  def initialize(input, options = T.unsafe(nil)); end

  # Consumes a token and returns the token that was consumed.
  #
  # 4.3.1. http://dev.w3.org/csswg/css-syntax/#consume-a-token
  def consume; end

  # Consumes the remnants of a bad URL and returns the consumed text.
  #
  # 4.3.15. http://dev.w3.org/csswg/css-syntax/#consume-the-remnants-of-a-bad-url
  def consume_bad_url; end

  # Consumes comments and returns them, or `nil` if no comments were consumed.
  #
  # 4.3.2. http://dev.w3.org/csswg/css-syntax/#consume-comments
  def consume_comments; end

  # Consumes an escaped code point and returns its unescaped value.
  #
  # This method assumes that the `\` has already been consumed, and that the
  # next character in the input has already been verified not to be a newline
  # or EOF.
  #
  # 4.3.8. http://dev.w3.org/csswg/css-syntax/#consume-an-escaped-code-point
  def consume_escaped; end

  # Consumes an ident-like token and returns it.
  #
  # 4.3.4. http://dev.w3.org/csswg/css-syntax/#consume-an-ident-like-token
  def consume_ident; end

  # Consumes a name and returns it.
  #
  # 4.3.12. http://dev.w3.org/csswg/css-syntax/#consume-a-name
  def consume_name; end

  # Consumes a number and returns a 3-element array containing the number's
  # original representation, its numeric value, and its type (either
  # `:integer` or `:number`).
  #
  # 4.3.13. http://dev.w3.org/csswg/css-syntax/#consume-a-number
  def consume_number; end

  # Consumes a numeric token and returns it.
  #
  # 4.3.3. http://dev.w3.org/csswg/css-syntax/#consume-a-numeric-token
  def consume_numeric; end

  # Consumes a string token that ends at the given character, and returns the
  # token.
  #
  # 4.3.5. http://dev.w3.org/csswg/css-syntax/#consume-a-string-token
  def consume_string(ending = T.unsafe(nil)); end

  # Consumes a Unicode range token and returns it. Assumes the initial "u+" or
  # "U+" has already been consumed.
  #
  # 4.3.7. http://dev.w3.org/csswg/css-syntax/#consume-a-unicode-range-token
  def consume_unicode_range; end

  # Consumes a URL token and returns it. Assumes the original "url(" has
  # already been consumed.
  #
  # 4.3.6. http://dev.w3.org/csswg/css-syntax/#consume-a-url-token
  def consume_url; end

  # Converts a valid CSS number string into a number and returns the number.
  #
  # 4.3.14. http://dev.w3.org/csswg/css-syntax/#convert-a-string-to-a-number
  def convert_string_to_number(str); end

  # Creates and returns a new token with the given _properties_.
  def create_token(type, properties = T.unsafe(nil)); end

  # Preprocesses _input_ to prepare it for the tokenizer.
  #
  # 3.3. http://dev.w3.org/csswg/css-syntax/#input-preprocessing
  def preprocess(input); end

  # Returns `true` if the given three-character _text_ would start an
  # identifier. If _text_ is `nil`, the current and next two characters in the
  # input stream will be checked, but will not be consumed.
  #
  # 4.3.10. http://dev.w3.org/csswg/css-syntax/#would-start-an-identifier
  def start_identifier?(text = T.unsafe(nil)); end

  # Returns `true` if the given three-character _text_ would start a number.
  # If _text_ is `nil`, the current and next two characters in the input
  # stream will be checked, but will not be consumed.
  #
  # 4.3.11. http://dev.w3.org/csswg/css-syntax/#starts-with-a-number
  def start_number?(text = T.unsafe(nil)); end

  # Tokenizes the input stream and returns an array of tokens.
  def tokenize; end

  # Returns `true` if the given two-character _text_ is the beginning of a
  # valid escape sequence. If _text_ is `nil`, the current and next character
  # in the input stream will be checked, but will not be consumed.
  #
  # 4.3.9. http://dev.w3.org/csswg/css-syntax/#starts-with-a-valid-escape
  def valid_escape?(text = T.unsafe(nil)); end

  class << self
    # Tokenizes the given _input_ as a CSS string and returns an array of
    # tokens.
    #
    # See {#initialize} for _options_.
    def tokenize(input, options = T.unsafe(nil)); end
  end
end

Crass::Tokenizer::RE_COMMENT_CLOSE = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_DIGIT = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_ESCAPE = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_HEX = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_NAME = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_NAME_START = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_NON_PRINTABLE = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_NUMBER_DECIMAL = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_NUMBER_EXPONENT = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_NUMBER_SIGN = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_NUMBER_STR = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_QUOTED_URL_START = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_UNICODE_RANGE_END = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_UNICODE_RANGE_START = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_WHITESPACE = T.let(T.unsafe(nil), Regexp)
Crass::Tokenizer::RE_WHITESPACE_ANCHORED = T.let(T.unsafe(nil), Regexp)
