# typed: __STDLIB_INTERNAL

class Delegator < ::BasicObject
  def initialize(obj); end

  def !; end
  def !=(obj); end
  def ==(obj); end
  def __getobj__; end
  def __setobj__(obj); end
  def eql?(obj); end
  def freeze; end
  def marshal_dump; end
  def marshal_load(data); end
  def method_missing(m, *args, **_arg2, &block); end
  def methods(all = T.unsafe(nil)); end
  def protected_methods(all = T.unsafe(nil)); end
  def public_methods(all = T.unsafe(nil)); end

  private

  def initialize_clone(obj, freeze: T.unsafe(nil)); end
  def initialize_dup(obj); end
  def respond_to_missing?(m, include_private); end
  def target_respond_to?(target, m, include_private); end

  class << self
    def const_missing(n); end
    def delegating_block(mid); end
    def public_api; end
  end
end

class SimpleDelegator
  def __getobj__; end
  def __setobj__(obj); end
end

class WeakRef
  def initialize(orig); end

  def __getobj__; end
  def __setobj__(obj); end
  def weakref_alive?; end
end

class WeakRef::RefError < ::StandardError; end
