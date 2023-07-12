# typed: __STDLIB_INTERNAL

module Mutex_m
  def initialize(*args, **_arg1); end

  def mu_extended; end
  def mu_lock; end
  def mu_locked?; end
  def mu_synchronize(&block); end
  def mu_try_lock; end
  def mu_unlock; end
  def sleep(timeout = T.unsafe(nil)); end

  private

  def mu_initialize; end

  class << self
    def append_features(cl); end
    def define_aliases(cl); end
    def extend_object(obj); end
  end
end
