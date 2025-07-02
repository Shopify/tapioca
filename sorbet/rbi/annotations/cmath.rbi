# typed: true
# frozen_string_literal: true

module CMath
  sig { params(z: Numeric).returns(Float) }
  def self.acos(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.acosh(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.asin(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.asinh(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.atan(z); end

  sig { params(y: Numeric, x: Numeric).returns(Float) }
  def self.atan2(y, x); end

  sig { params(z: Numeric).returns(Float) }
  def self.atanh(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.cbrt(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.cos(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.cosh(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.exp(z); end

  sig { params(z: Numeric, b: Numeric).returns(Float) }
  def self.log(z, b = ::Math::E); end

  sig { params(z: Numeric).returns(Float) }
  def self.log10(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.log2(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.sin(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.sinh(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.sqrt(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.tan(z); end

  sig { params(z: Numeric).returns(Float) }
  def self.tanh(z); end
end

