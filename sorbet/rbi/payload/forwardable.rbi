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

module SingleForwardable
  def def_delegator(accessor, method, ali = T.unsafe(nil)); end
  def def_delegators(accessor, *methods); end
  def def_single_delegator(accessor, method, ali = T.unsafe(nil)); end
  def def_single_delegators(accessor, *methods); end
  def delegate(hash); end
  def single_delegate(hash); end
end
