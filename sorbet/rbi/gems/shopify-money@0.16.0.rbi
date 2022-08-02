# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `shopify-money` gem.
# Please instead update this file by running `bin/tapioca gem shopify-money`.

# source://shopify-money-0.16.0/lib/money/deprecations.rb:3
ACTIVE_SUPPORT_DEFINED = T.let(T.unsafe(nil), String)

# source://shopify-money-0.16.0/lib/money/accounting_money_parser.rb:3
class AccountingMoneyParser < ::MoneyParser
  # source://shopify-money-0.16.0/lib/money/accounting_money_parser.rb:4
  def parse(input, currency = T.unsafe(nil), **options); end
end

# source://shopify-money-0.16.0/lib/money/helpers.rb:4
class Money
  include ::Comparable
  extend ::Forwardable

  # @raise [ArgumentError]
  # @return [Money] a new instance of Money
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:84
  def initialize(value, currency); end

  # source://shopify-money-0.16.0/lib/money/money.rb:139
  def *(numeric); end

  # source://shopify-money-0.16.0/lib/money/money.rb:127
  def +(other); end

  # source://shopify-money-0.16.0/lib/money/money.rb:133
  def -(other); end

  # source://shopify-money-0.16.0/lib/money/money.rb:116
  def -@; end

  # source://shopify-money-0.16.0/lib/money/money.rb:146
  def /(numeric); end

  # source://shopify-money-0.16.0/lib/money/money.rb:120
  def <=>(other); end

  # source://shopify-money-0.16.0/lib/money/money.rb:154
  def ==(other); end

  # source://shopify-money-0.16.0/lib/money/money.rb:240
  def abs; end

  # @see Money::Allocator#allocate
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:260
  def allocate(splits, strategy = T.unsafe(nil)); end

  # @see Money::Allocator#allocate_max_amounts
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:265
  def allocate_max_amounts(maximums); end

  # source://shopify-money-0.16.0/lib/money/money.rb:236
  def as_json(*args); end

  # Calculate the splits evenly without losing pennies.
  # Returns the number of high and low splits and the value of the high and low splits.
  # Where high represents the Money value with the extra penny
  # and low a Money without the extra penny.
  #
  # @example
  #   Money.new(100, "USD").calculate_splits(3) #=> {Money.new(34) => 1, Money.new(33) => 2}
  # @param number [2] of parties.
  # @raise [ArgumentError]
  # @return [Hash<Money, Integer>]
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:292
  def calculate_splits(num); end

  # Clamps the value to be within the specified minimum and maximum. Returns
  # self if the value is within bounds, otherwise a new Money object with the
  # closest min or max value.
  #
  # @example
  #   Money.new(50, "CAD").clamp(1, 100) #=> Money.new(50, "CAD")
  #
  #   Money.new(120, "CAD").clamp(0, 100) #=> Money.new(100, "CAD")
  # @raise [ArgumentError]
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:314
  def clamp(min, max); end

  # @raise [TypeError]
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:189
  def coerce(other); end

  # Returns the value of attribute currency.
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:10
  def currency; end

  # source://shopify-money-0.16.0/lib/money/money.rb:95
  def encode_with(coder); end

  # TODO: Remove once cross-currency mathematical operations are no longer allowed
  #
  # @return [Boolean]
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:159
  def eql?(other); end

  # source://shopify-money-0.16.0/lib/money/money.rb:244
  def floor; end

  # @raise [ArgumentError]
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:252
  def fraction(rate); end

  # source://RUBY_ROOT/forwardable.rb:229
  def hash(*args, **_arg1, &block); end

  # source://shopify-money-0.16.0/lib/money/money.rb:91
  def init_with(coder); end

  # source://shopify-money-0.16.0/lib/money/money.rb:150
  def inspect; end

  # source://RUBY_ROOT/forwardable.rb:229
  def negative?(*args, **_arg1, &block); end

  # @return [Boolean]
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:112
  def no_currency?; end

  # source://RUBY_ROOT/forwardable.rb:229
  def nonzero?(*args, **_arg1, &block); end

  # source://RUBY_ROOT/forwardable.rb:229
  def positive?(*args, **_arg1, &block); end

  # source://shopify-money-0.16.0/lib/money/money.rb:248
  def round(ndigits = T.unsafe(nil)); end

  # Split money amongst parties evenly without losing pennies.
  #
  # @example
  #   Money.new(100, "USD").split(3) #=> [Money.new(34), Money.new(33), Money.new(33)]
  # @param number [2] of parties.
  # @return [Array<Money, Money, Money>]
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:277
  def split(num); end

  # source://shopify-money-0.16.0/lib/money/money.rb:100
  def subunits(format: T.unsafe(nil)); end

  # source://shopify-money-0.16.0/lib/money/money.rb:208
  def to_d; end

  # source://RUBY_ROOT/forwardable.rb:229
  def to_f(*args, **_arg1, &block); end

  # source://RUBY_ROOT/forwardable.rb:229
  def to_i(*args, **_arg1, &block); end

  # source://shopify-money-0.16.0/lib/money/money.rb:232
  def to_json(options = T.unsafe(nil)); end

  # source://shopify-money-0.16.0/lib/money/money.rb:194
  def to_money(curr = T.unsafe(nil)); end

  # source://shopify-money-0.16.0/lib/money/money.rb:212
  def to_s(style = T.unsafe(nil)); end

  # Returns the value of attribute value.
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:10
  def value; end

  # source://RUBY_ROOT/forwardable.rb:229
  def zero?(*args, **_arg1, &block); end

  private

  # @raise [TypeError]
  # @yield [other]
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:329
  def arithmetic(money_or_numeric); end

  # source://shopify-money-0.16.0/lib/money/money.rb:336
  def calculated_currency(other); end

  class << self
    # source://shopify-money-0.16.0/lib/money/deprecations.rb:5
    def active_support_deprecator; end

    # source://shopify-money-0.16.0/lib/money/money.rb:55
    def current_currency; end

    # source://shopify-money-0.16.0/lib/money/money.rb:59
    def current_currency=(currency); end

    # Returns the value of attribute default_currency.
    #
    # source://shopify-money-0.16.0/lib/money/money.rb:14
    def default_currency; end

    # Sets the attribute default_currency
    #
    # @param value the value to set the attribute default_currency to.
    #
    # source://shopify-money-0.16.0/lib/money/money.rb:14
    def default_currency=(_arg0); end

    # source://shopify-money-0.16.0/lib/money/money.rb:77
    def default_settings; end

    # source://shopify-money-0.16.0/lib/money/deprecations.rb:9
    def deprecate(message); end

    # source://shopify-money-0.16.0/lib/money/money.rb:16
    def from_amount(value = T.unsafe(nil), currency = T.unsafe(nil)); end

    # source://shopify-money-0.16.0/lib/money/money.rb:33
    def from_subunits(subunits, currency_iso, format: T.unsafe(nil)); end

    # source://shopify-money-0.16.0/lib/money/money.rb:16
    def new(value = T.unsafe(nil), currency = T.unsafe(nil)); end

    # source://shopify-money-0.16.0/lib/money/money.rb:29
    def parse(*args, **kwargs); end

    # Returns the value of attribute parser.
    #
    # source://shopify-money-0.16.0/lib/money/money.rb:14
    def parser; end

    # Sets the attribute parser
    #
    # @param value the value to set the attribute parser to.
    #
    # source://shopify-money-0.16.0/lib/money/money.rb:14
    def parser=(_arg0); end

    # source://shopify-money-0.16.0/lib/money/money.rb:48
    def rational(money1, money2); end

    # Set Money.default_currency inside the supplied block, resets it to
    # the previous value when done to prevent leaking state. Similar to
    # I18n.with_locale and ActiveSupport's Time.use_zone. This won't affect
    # instances being created with explicitly set currency.
    #
    # source://shopify-money-0.16.0/lib/money/money.rb:67
    def with_currency(new_currency); end
  end
end

# source://shopify-money-0.16.0/lib/money/allocator.rb:5
class Money::Allocator < ::SimpleDelegator
  # @return [Allocator] a new instance of Allocator
  #
  # source://shopify-money-0.16.0/lib/money/allocator.rb:6
  def initialize(money); end

  # @example left over pennies distributed reverse order when using roundrobin_reverse strategy
  #   Money.new(10.01, "USD").allocate([0.5, 0.5], :roundrobin_reverse)
  #   #=> [#<Money value:5.00 currency:USD>, #<Money value:5.01 currency:USD>]
  #
  # source://shopify-money-0.16.0/lib/money/allocator.rb:42
  def allocate(splits, strategy = T.unsafe(nil)); end

  # Allocates money between different parties up to the maximum amounts specified.
  # Left over pennies will be assigned round-robin up to the maximum specified.
  # Pennies are dropped when the maximums are attained.
  #
  # @example
  #   Money.new(30.75).allocate_max_amounts([Money.new(26), Money.new(4.75)])
  #   #=> [Money.new(26), Money.new(4.75)]
  #
  #   Money.new(30.75).allocate_max_amounts([Money.new(26), Money.new(4.74)]
  #   #=> [Money.new(26), Money.new(4.74)]
  #
  #   Money.new(30).allocate_max_amounts([Money.new(15), Money.new(15)]
  #   #=> [Money.new(15), Money.new(15)]
  #
  #   Money.new(1).allocate_max_amounts([Money.new(33), Money.new(33), Money.new(33)])
  #   #=> [Money.new(0.34), Money.new(0.33), Money.new(0.33)]
  #
  #   Money.new(100).allocate_max_amounts([Money.new(5), Money.new(2)])
  #   #=> [Money.new(5), Money.new(2)]
  #
  # source://shopify-money-0.16.0/lib/money/allocator.rb:78
  def allocate_max_amounts(maximums); end

  private

  # @return [Boolean]
  #
  # source://shopify-money-0.16.0/lib/money/allocator.rb:129
  def all_rational?(splits); end

  # source://shopify-money-0.16.0/lib/money/allocator.rb:133
  def allocation_index_for(strategy, length, idx); end

  # @raise [ArgumentError]
  #
  # source://shopify-money-0.16.0/lib/money/allocator.rb:115
  def amounts_from_splits(allocations, splits, subunits_to_split = T.unsafe(nil)); end

  # source://shopify-money-0.16.0/lib/money/allocator.rb:107
  def extract_currency(money_array); end
end

# source://shopify-money-0.16.0/lib/money/currency/loader.rb:5
class Money::Currency
  # @raise [UnknownCurrency]
  # @return [Currency] a new instance of Currency
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:33
  def initialize(currency_iso); end

  # @return [Boolean]
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:49
  def ==(other); end

  # @return [Boolean]
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:57
  def compatible?(other); end

  # Returns the value of attribute decimal_mark.
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:30
  def decimal_mark; end

  # Returns the value of attribute disambiguate_symbol.
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:30
  def disambiguate_symbol; end

  # @return [Boolean]
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:49
  def eql?(other); end

  # source://shopify-money-0.16.0/lib/money/currency.rb:53
  def hash; end

  # Returns the value of attribute iso_code.
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:30
  def iso_code; end

  # Returns the value of attribute iso_numeric.
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:30
  def iso_numeric; end

  # Returns the value of attribute minor_units.
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:30
  def minor_units; end

  # Returns the value of attribute name.
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:30
  def name; end

  # Returns the value of attribute smallest_denomination.
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:30
  def smallest_denomination; end

  # Returns the value of attribute subunit_symbol.
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:30
  def subunit_symbol; end

  # Returns the value of attribute subunit_to_unit.
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:30
  def subunit_to_unit; end

  # Returns the value of attribute symbol.
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:30
  def symbol; end

  # Returns the value of attribute iso_code.
  #
  # source://shopify-money-0.16.0/lib/money/currency.rb:30
  def to_s; end

  class << self
    # source://shopify-money-0.16.0/lib/money/currency.rb:25
    def currencies; end

    # source://shopify-money-0.16.0/lib/money/currency.rb:19
    def find(currency_iso); end

    # @raise [UnknownCurrency]
    #
    # source://shopify-money-0.16.0/lib/money/currency.rb:12
    def find!(currency_iso); end

    # @raise [UnknownCurrency]
    #
    # source://shopify-money-0.16.0/lib/money/currency.rb:12
    def new(currency_iso); end
  end
end

# source://shopify-money-0.16.0/lib/money/currency/loader.rb:6
module Money::Currency::Loader
  class << self
    # source://shopify-money-0.16.0/lib/money/currency/loader.rb:8
    def load_currencies; end

    private

    # source://shopify-money-0.16.0/lib/money/currency/loader.rb:20
    def deep_deduplicate!(data); end
  end
end

# source://shopify-money-0.16.0/lib/money/currency.rb:9
class Money::Currency::UnknownCurrency < ::ArgumentError; end

# source://shopify-money-0.16.0/lib/money/errors.rb:3
class Money::Error < ::StandardError; end

# source://shopify-money-0.16.0/lib/money/helpers.rb:5
module Money::Helpers
  private

  # source://shopify-money-0.16.0/lib/money/helpers.rb:43
  def value_to_currency(currency); end

  # source://shopify-money-0.16.0/lib/money/helpers.rb:15
  def value_to_decimal(num); end

  class << self
    # source://shopify-money-0.16.0/lib/money/helpers.rb:43
    def value_to_currency(currency); end

    # source://shopify-money-0.16.0/lib/money/helpers.rb:15
    def value_to_decimal(num); end
  end
end

# source://shopify-money-0.16.0/lib/money/helpers.rb:8
Money::Helpers::DECIMAL_ZERO = T.let(T.unsafe(nil), BigDecimal)

# source://shopify-money-0.16.0/lib/money/helpers.rb:9
Money::Helpers::MAX_DECIMAL = T.let(T.unsafe(nil), Integer)

# source://shopify-money-0.16.0/lib/money/helpers.rb:11
Money::Helpers::STRIPE_SUBUNIT_OVERRIDE = T.let(T.unsafe(nil), Hash)

# source://shopify-money-0.16.0/lib/money/errors.rb:6
class Money::IncompatibleCurrencyError < ::Money::Error; end

# source://shopify-money-0.16.0/lib/money/money.rb:8
Money::NULL_CURRENCY = T.let(T.unsafe(nil), Money::NullCurrency)

# A placeholder currency for instances where no actual currency is available,
# as defined by ISO4217. You should rarely, if ever, need to use this
# directly. It's here mostly for backwards compatibility and for that reason
# behaves like a dollar, which is how this gem worked before the introduction
# of currency.
#
# Here follows a list of preferred alternatives over using Money with
# NullCurrency:
#
# For comparisons where you don't know the currency beforehand, you can use
# Numeric predicate methods like #positive?/#negative?/#zero?/#nonzero?.
# Comparison operators with Numeric (==, !=, <=, =>, <, >) work as well.
#
# Money with NullCurrency has behaviour that may surprise you, such as
# database validations or GraphQL enum not allowing the string representation
# of NullCurrency. Prefer using Money.new(0, currency) where possible, as
# this sidesteps these issues and provides additional currency check
# safeties.
#
# Unlike other currencies, it is allowed to calculate a Money object with
# NullCurrency with another currency. The resulting Money object will have
# the other currency.
#
# @example
#   Money.new(1, 'CAD').positive? #=> true
#   Money.new(2, 'CAD') >= 0      #=> true
# @example
#   Money.new(0, Money::NULL_CURRENCY) + Money.new(5, 'CAD')
#   #=> #<Money value:5.00 currency:CAD>
#
# source://shopify-money-0.16.0/lib/money/null_currency.rb:34
class Money::NullCurrency
  # @return [NullCurrency] a new instance of NullCurrency
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:39
  def initialize; end

  # @return [Boolean]
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:57
  def ==(other); end

  # @return [Boolean]
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:53
  def compatible?(other); end

  # Returns the value of attribute decimal_mark.
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:36
  def decimal_mark; end

  # Returns the value of attribute disambiguate_symbol.
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:36
  def disambiguate_symbol; end

  # @return [Boolean]
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:57
  def eql?(other); end

  # Returns the value of attribute iso_code.
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:36
  def iso_code; end

  # Returns the value of attribute iso_numeric.
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:36
  def iso_numeric; end

  # Returns the value of attribute minor_units.
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:36
  def minor_units; end

  # Returns the value of attribute name.
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:36
  def name; end

  # Returns the value of attribute smallest_denomination.
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:36
  def smallest_denomination; end

  # Returns the value of attribute subunit_symbol.
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:36
  def subunit_symbol; end

  # Returns the value of attribute subunit_to_unit.
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:36
  def subunit_to_unit; end

  # Returns the value of attribute symbol.
  #
  # source://shopify-money-0.16.0/lib/money/null_currency.rb:36
  def symbol; end

  # source://shopify-money-0.16.0/lib/money/null_currency.rb:61
  def to_s; end
end

# source://shopify-money-0.16.0/lib/money/money.rb:165
class Money::ReverseOperationProxy
  include ::Comparable

  # @return [ReverseOperationProxy] a new instance of ReverseOperationProxy
  #
  # source://shopify-money-0.16.0/lib/money/money.rb:168
  def initialize(value); end

  # source://shopify-money-0.16.0/lib/money/money.rb:184
  def *(other); end

  # source://shopify-money-0.16.0/lib/money/money.rb:176
  def +(other); end

  # source://shopify-money-0.16.0/lib/money/money.rb:180
  def -(other); end

  # source://shopify-money-0.16.0/lib/money/money.rb:172
  def <=>(other); end
end

# source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:2
module MoneyColumn; end

# source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:3
module MoneyColumn::ActiveRecordHooks
  mixes_in_class_methods ::MoneyColumn::ActiveRecordHooks::ClassMethods

  # source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:8
  def reload(*_arg0); end

  private

  # source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:20
  def clear_money_column_cache; end

  # source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:24
  def init_internals; end

  # source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:13
  def initialize_dup(*_arg0); end

  # source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:29
  def read_money_attribute(column); end

  # source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:42
  def write_money_attribute(column, money); end

  class << self
    # @private
    #
    # source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:4
    def included(base); end
  end
end

# source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:70
module MoneyColumn::ActiveRecordHooks::ClassMethods
  # source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:73
  def money_column(*columns, currency_column: T.unsafe(nil), currency: T.unsafe(nil), currency_read_only: T.unsafe(nil), coerce_null: T.unsafe(nil)); end

  # Returns the value of attribute money_column_options.
  #
  # source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:71
  def money_column_options; end

  private

  # source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:121
  def clear_cache_on_currency_change(currency_column); end

  # source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:130
  def inherited(subclass); end

  # @raise [ArgumentError]
  #
  # source://shopify-money-0.16.0/lib/money_column/active_record_hooks.rb:106
  def normalize_money_column_options(options); end
end

# source://shopify-money-0.16.0/lib/money_column/active_record_type.rb:2
class MoneyColumn::ActiveRecordType < ::ActiveModel::Type::Decimal
  # source://shopify-money-0.16.0/lib/money_column/active_record_type.rb:3
  def serialize(money); end
end

# source://shopify-money-0.16.0/lib/money_column/railtie.rb:3
class MoneyColumn::Railtie < ::Rails::Railtie; end

# Parse an amount from a string
#
# source://shopify-money-0.16.0/lib/money/money_parser.rb:4
class MoneyParser
  # source://shopify-money-0.16.0/lib/money/money_parser.rb:64
  def parse(input, currency = T.unsafe(nil), strict: T.unsafe(nil)); end

  private

  # @raise [MoneyFormatError]
  #
  # source://shopify-money-0.16.0/lib/money/money_parser.rb:72
  def extract_amount_from_string(input, currency, strict); end

  # @return [Boolean]
  #
  # source://shopify-money-0.16.0/lib/money/money_parser.rb:127
  def last_digits_decimals?(digits, marks, currency); end

  # source://shopify-money-0.16.0/lib/money/money_parser.rb:116
  def normalize_number(number, marks, currency); end

  class << self
    # source://shopify-money-0.16.0/lib/money/money_parser.rb:60
    def parse(input, currency = T.unsafe(nil), **options); end
  end
end

# 1,1123,4567.89
#
# source://shopify-money-0.16.0/lib/money/money_parser.rb:51
MoneyParser::CHINESE_NUMERIC_REGEX = T.let(T.unsafe(nil), Regexp)

# 1.234.567,89
#
# source://shopify-money-0.16.0/lib/money/money_parser.rb:30
MoneyParser::COMMA_DECIMAL_REGEX = T.let(T.unsafe(nil), Regexp)

# 1,234,567.89
#
# source://shopify-money-0.16.0/lib/money/money_parser.rb:20
MoneyParser::DOT_DECIMAL_REGEX = T.let(T.unsafe(nil), Regexp)

# source://shopify-money-0.16.0/lib/money/money_parser.rb:9
MoneyParser::ESCAPED_MARKS = T.let(T.unsafe(nil), String)

# source://shopify-money-0.16.0/lib/money/money_parser.rb:12
MoneyParser::ESCAPED_NON_COMMA_MARKS = T.let(T.unsafe(nil), String)

# source://shopify-money-0.16.0/lib/money/money_parser.rb:11
MoneyParser::ESCAPED_NON_DOT_MARKS = T.let(T.unsafe(nil), String)

# source://shopify-money-0.16.0/lib/money/money_parser.rb:10
MoneyParser::ESCAPED_NON_SPACE_MARKS = T.let(T.unsafe(nil), String)

# 12,34,567.89
#
# source://shopify-money-0.16.0/lib/money/money_parser.rb:40
MoneyParser::INDIAN_NUMERIC_REGEX = T.let(T.unsafe(nil), Regexp)

# source://shopify-money-0.16.0/lib/money/money_parser.rb:7
MoneyParser::MARKS = T.let(T.unsafe(nil), Array)

# source://shopify-money-0.16.0/lib/money/money_parser.rb:5
class MoneyParser::MoneyFormatError < ::ArgumentError; end

# source://shopify-money-0.16.0/lib/money/money_parser.rb:14
MoneyParser::NUMERIC_REGEX = T.let(T.unsafe(nil), Regexp)

# Allows Writing of 100.to_money for +Numeric+ types
#   100.to_money => #<Money @cents=10000>
#   100.37.to_money => #<Money @cents=10037>
#
# source://shopify-money-0.16.0/lib/money/core_extensions.rb:5
class Numeric
  include ::Comparable

  # source://shopify-money-0.16.0/lib/money/core_extensions.rb:6
  def to_money(currency = T.unsafe(nil)); end
end

# source://activesupport-7.0.3.1/lib/active_support/core_ext/numeric/bytes.rb:9
Numeric::EXABYTE = T.let(T.unsafe(nil), Integer)

# source://activesupport-7.0.3.1/lib/active_support/core_ext/numeric/bytes.rb:6
Numeric::GIGABYTE = T.let(T.unsafe(nil), Integer)

# source://activesupport-7.0.3.1/lib/active_support/core_ext/numeric/bytes.rb:4
Numeric::KILOBYTE = T.let(T.unsafe(nil), Integer)

# source://activesupport-7.0.3.1/lib/active_support/core_ext/numeric/bytes.rb:5
Numeric::MEGABYTE = T.let(T.unsafe(nil), Integer)

# source://activesupport-7.0.3.1/lib/active_support/core_ext/numeric/bytes.rb:8
Numeric::PETABYTE = T.let(T.unsafe(nil), Integer)

# source://activesupport-7.0.3.1/lib/active_support/core_ext/numeric/bytes.rb:7
Numeric::TERABYTE = T.let(T.unsafe(nil), Integer)

# source://shopify-money-0.16.0/lib/rubocop/cop/money/missing_currency.rb:3
module RuboCop; end

# source://shopify-money-0.16.0/lib/rubocop/cop/money/missing_currency.rb:4
module RuboCop::Cop; end

# source://rubocop-1.32.0/lib/rubocop/cop/mixin/allowed_pattern.rb:38
RuboCop::Cop::IgnoredPattern = RuboCop::Cop::AllowedPattern

# source://shopify-money-0.16.0/lib/rubocop/cop/money/missing_currency.rb:5
module RuboCop::Cop::Money; end

# source://shopify-money-0.16.0/lib/rubocop/cop/money/missing_currency.rb:20
class RuboCop::Cop::Money::MissingCurrency < ::RuboCop::Cop::Cop
  # source://shopify-money-0.16.0/lib/rubocop/cop/money/missing_currency.rb:47
  def autocorrect(node); end

  # source://shopify-money-0.16.0/lib/rubocop/cop/money/missing_currency.rb:22
  def money_new(param0 = T.unsafe(nil)); end

  # source://shopify-money-0.16.0/lib/rubocop/cop/money/missing_currency.rb:34
  def on_csend(node); end

  # source://shopify-money-0.16.0/lib/rubocop/cop/money/missing_currency.rb:34
  def on_send(node); end

  # source://shopify-money-0.16.0/lib/rubocop/cop/money/missing_currency.rb:30
  def to_money_block?(param0 = T.unsafe(nil)); end

  # source://shopify-money-0.16.0/lib/rubocop/cop/money/missing_currency.rb:26
  def to_money_without_currency?(param0 = T.unsafe(nil)); end

  private

  # source://shopify-money-0.16.0/lib/rubocop/cop/money/missing_currency.rb:73
  def replacement_currency; end
end

# source://shopify-money-0.16.0/lib/rubocop/cop/money/zero_money.rb:25
class RuboCop::Cop::Money::ZeroMoney < ::RuboCop::Cop::Cop
  # source://shopify-money-0.16.0/lib/rubocop/cop/money/zero_money.rb:39
  def autocorrect(node); end

  # source://shopify-money-0.16.0/lib/rubocop/cop/money/zero_money.rb:29
  def money_zero(param0 = T.unsafe(nil)); end

  # source://shopify-money-0.16.0/lib/rubocop/cop/money/zero_money.rb:33
  def on_send(node); end

  private

  # source://shopify-money-0.16.0/lib/rubocop/cop/money/zero_money.rb:56
  def replacement_currency(currency_arg); end
end

# `Money.zero` and it's alias `empty`, with or without currency
# argument is removed in favour of the more explicit Money.new
# syntax. Supplying it with a real currency is preferred for
# additional currency safety checks.
#
# If no currency was supplied, it defaults to
# Money::NULL_CURRENCY which was the default setting of
# Money.default_currency and should effectively be the same. The cop
# can be configured with a ReplacementCurrency in case that is more
# appropriate for your application.
#
# @example
#
#   # bad
#   Money.zero
#
#   # good when configured with `ReplacementCurrency: CAD`
#   Money.new(0, 'CAD')
#
# source://shopify-money-0.16.0/lib/rubocop/cop/money/zero_money.rb:27
RuboCop::Cop::Money::ZeroMoney::MSG = T.let(T.unsafe(nil), String)

# source://rubocop-1.32.0/lib/rubocop/ast_aliases.rb:5
RuboCop::NodePattern = RuboCop::AST::NodePattern

# source://rubocop-1.32.0/lib/rubocop/ast_aliases.rb:6
RuboCop::ProcessedSource = RuboCop::AST::ProcessedSource

# source://rubocop-1.32.0/lib/rubocop/ast_aliases.rb:7
RuboCop::Token = RuboCop::AST::Token

# Allows Writing of '100'.to_money for +String+ types
# Excess characters will be discarded
#   '100'.to_money => #<Money @cents=10000>
#   '100.37'.to_money => #<Money @cents=10037>
#
# source://shopify-money-0.16.0/lib/money/core_extensions.rb:15
class String
  include ::Comparable

  # source://shopify-money-0.16.0/lib/money/core_extensions.rb:16
  def to_money(currency = T.unsafe(nil)); end
end

# source://activesupport-7.0.3.1/lib/active_support/core_ext/object/blank.rb:104
String::BLANK_RE = T.let(T.unsafe(nil), Regexp)

# source://activesupport-7.0.3.1/lib/active_support/core_ext/object/blank.rb:105
String::ENCODED_BLANKS = T.let(T.unsafe(nil), Concurrent::Map)
