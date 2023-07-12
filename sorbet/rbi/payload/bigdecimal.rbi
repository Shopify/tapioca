# typed: __STDLIB_INTERNAL

class BigDecimal < ::Numeric
  def %(_arg0); end
  def *(_arg0); end
  def **(_arg0); end
  def +(_arg0); end
  def +@; end
  def -(_arg0); end
  def -@; end
  def /(_arg0); end
  def <(_arg0); end
  def <=(_arg0); end
  def <=>(_arg0); end
  def ==(_arg0); end
  def ===(_arg0); end
  def >(_arg0); end
  def >=(_arg0); end
  def _dump(*_arg0); end
  def abs; end
  def add(_arg0, _arg1); end
  def ceil(*_arg0); end
  def clone; end
  def coerce(_arg0); end
  def div(*_arg0); end
  def divmod(_arg0); end
  def dup; end
  def eql?(_arg0); end
  def exponent; end
  def finite?; end
  def fix; end
  def floor(*_arg0); end
  def frac; end
  def hash; end
  def infinite?; end
  def inspect; end
  def modulo(_arg0); end
  def mult(_arg0, _arg1); end
  def n_significant_digits; end
  def nan?; end
  def nonzero?; end
  def power(*_arg0); end
  def precision; end
  def precision_scale; end
  def precs; end
  def quo(*_arg0); end
  def remainder(_arg0); end
  def round(*_arg0); end
  def scale; end
  def sign; end
  def split; end
  def sqrt(_arg0); end
  def sub(_arg0, _arg1); end
  def to_d; end
  def to_digits; end
  def to_f; end
  def to_i; end
  def to_int; end
  def to_r; end
  def to_s(*_arg0); end
  def truncate(*_arg0); end
  def zero?; end

  class << self
    def _load(_arg0); end
    def double_fig; end
    def interpret_loosely(_arg0); end
    def limit(*_arg0); end
    def mode(*_arg0); end
    def save_exception_mode; end
    def save_limit; end
    def save_rounding_mode; end
  end
end

module BigMath
  private

  def E(prec); end
  def PI(prec); end
  def atan(x, prec); end
  def cos(x, prec); end
  def sin(x, prec); end
  def sqrt(x, prec); end

  class << self
    def E(prec); end
    def PI(prec); end
    def atan(x, prec); end
    def cos(x, prec); end
    def exp(_arg0, _arg1); end
    def log(_arg0, _arg1); end
    def sin(x, prec); end
    def sqrt(x, prec); end
  end
end

module Jacobian
  private

  def dfdxi(f, fx, x, i); end
  def isEqual(a, b, zero = T.unsafe(nil), e = T.unsafe(nil)); end
  def jacobian(f, fx, x); end

  class << self
    def dfdxi(f, fx, x, i); end
    def isEqual(a, b, zero = T.unsafe(nil), e = T.unsafe(nil)); end
    def jacobian(f, fx, x); end
  end
end

module LUSolve
  private

  def ludecomp(a, n, zero = T.unsafe(nil), one = T.unsafe(nil)); end
  def lusolve(a, b, ps, zero = T.unsafe(nil)); end

  class << self
    def ludecomp(a, n, zero = T.unsafe(nil), one = T.unsafe(nil)); end
    def lusolve(a, b, ps, zero = T.unsafe(nil)); end
  end
end

module Newton
  private

  def nlsolve(f, x); end
  def norm(fv, zero = T.unsafe(nil)); end

  class << self
    def nlsolve(f, x); end
    def norm(fv, zero = T.unsafe(nil)); end
  end
end
