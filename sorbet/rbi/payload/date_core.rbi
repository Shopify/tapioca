# typed: __STDLIB_INTERNAL

class Date
  include ::Comparable

  def initialize(*_arg0); end

  def +(_arg0); end
  def -(_arg0); end
  def <<(_arg0); end
  def <=>(_arg0); end
  def ===(_arg0); end
  def >>(_arg0); end
  def ajd; end
  def amjd; end
  def asctime; end
  def ctime; end
  def cwday; end
  def cweek; end
  def cwyear; end
  def day; end
  def day_fraction; end
  def deconstruct_keys(_arg0); end
  def downto(_arg0); end
  def england; end
  def eql?(_arg0); end
  def friday?; end
  def gregorian; end
  def gregorian?; end
  def hash; end
  def httpdate; end
  def infinite?; end
  def inspect; end
  def iso8601; end
  def italy; end
  def jd; end
  def jisx0301; end
  def julian; end
  def julian?; end
  def ld; end
  def leap?; end
  def marshal_dump; end
  def marshal_load(_arg0); end
  def mday; end
  def mjd; end
  def mon; end
  def monday?; end
  def month; end
  def new_start(*_arg0); end
  def next; end
  def next_day(*_arg0); end
  def next_month(*_arg0); end
  def next_year(*_arg0); end
  def prev_day(*_arg0); end
  def prev_month(*_arg0); end
  def prev_year(*_arg0); end
  def rfc2822; end
  def rfc3339; end
  def rfc822; end
  def saturday?; end
  def start; end
  def step(*_arg0); end
  def strftime(*_arg0); end
  def succ; end
  def sunday?; end
  def thursday?; end
  def to_date; end
  def to_datetime; end
  def to_s; end
  def to_time; end
  def tuesday?; end
  def upto(_arg0); end
  def wday; end
  def wednesday?; end
  def xmlschema; end
  def yday; end
  def year; end

  private

  def hour; end
  def initialize_copy(_arg0); end
  def min; end
  def minute; end
  def sec; end
  def second; end

  class << self
    def _httpdate(*_arg0); end
    def _iso8601(*_arg0); end
    def _jisx0301(*_arg0); end
    def _load(_arg0); end
    def _parse(*_arg0); end
    def _rfc2822(*_arg0); end
    def _rfc3339(*_arg0); end
    def _rfc822(*_arg0); end
    def _strptime(*_arg0); end
    def _xmlschema(*_arg0); end
    def civil(*_arg0); end
    def commercial(*_arg0); end
    def gregorian_leap?(_arg0); end
    def httpdate(*_arg0); end
    def iso8601(*_arg0); end
    def jd(*_arg0); end
    def jisx0301(*_arg0); end
    def julian_leap?(_arg0); end
    def leap?(_arg0); end
    def ordinal(*_arg0); end
    def parse(*_arg0); end
    def rfc2822(*_arg0); end
    def rfc3339(*_arg0); end
    def rfc822(*_arg0); end
    def strptime(*_arg0); end
    def today(*_arg0); end
    def valid_civil?(*_arg0); end
    def valid_commercial?(*_arg0); end
    def valid_date?(*_arg0); end
    def valid_jd?(*_arg0); end
    def valid_ordinal?(*_arg0); end
    def xmlschema(*_arg0); end
  end
end

class Date::Error < ::ArgumentError; end

class Date::Infinity < ::Numeric
  def initialize(d = T.unsafe(nil)); end

  def +@; end
  def -@; end
  def <=>(other); end
  def abs; end
  def coerce(other); end
  def finite?; end
  def infinite?; end
  def nan?; end
  def to_f; end
  def zero?; end

  protected

  def d; end
end

class DateTime < ::Date
  def deconstruct_keys(_arg0); end
  def hour; end
  def iso8601(*_arg0); end
  def jisx0301(*_arg0); end
  def min; end
  def minute; end
  def new_offset(*_arg0); end
  def offset; end
  def rfc3339(*_arg0); end
  def sec; end
  def sec_fraction; end
  def second; end
  def second_fraction; end
  def strftime(*_arg0); end
  def to_date; end
  def to_datetime; end
  def to_s; end
  def to_time; end
  def xmlschema(*_arg0); end
  def zone; end

  class << self
    def _strptime(*_arg0); end
    def civil(*_arg0); end
    def commercial(*_arg0); end
    def httpdate(*_arg0); end
    def iso8601(*_arg0); end
    def jd(*_arg0); end
    def jisx0301(*_arg0); end
    def new(*_arg0); end
    def now(*_arg0); end
    def ordinal(*_arg0); end
    def parse(*_arg0); end
    def rfc2822(*_arg0); end
    def rfc3339(*_arg0); end
    def rfc822(*_arg0); end
    def strptime(*_arg0); end
    def xmlschema(*_arg0); end
  end
end
