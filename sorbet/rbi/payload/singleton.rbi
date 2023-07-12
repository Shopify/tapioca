# typed: __STDLIB_INTERNAL

module Singleton
  mixes_in_class_methods ::Singleton::SingletonClassMethods

  def _dump(depth = T.unsafe(nil)); end
  def clone; end
  def dup; end

  class << self
    def __init__(klass); end

    private

    def append_features(mod); end
    def included(klass); end
  end
end

module Singleton::SingletonClassMethods
  def _load(str); end
  def clone; end
  def instance; end

  private

  def inherited(sub_klass); end
end
