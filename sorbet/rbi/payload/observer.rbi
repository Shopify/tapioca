# typed: __STDLIB_INTERNAL

module Observable
  def add_observer(observer, func = T.unsafe(nil)); end
  def changed(state = T.unsafe(nil)); end
  def changed?; end
  def count_observers; end
  def delete_observer(observer); end
  def delete_observers; end
  def notify_observers(*arg); end
end
