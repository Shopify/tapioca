# typed: __STDLIB_INTERNAL

module TSort
  def each_strongly_connected_component(&block); end
  def each_strongly_connected_component_from(node, id_map = T.unsafe(nil), stack = T.unsafe(nil), &block); end
  def strongly_connected_components; end
  def tsort; end
  def tsort_each(&block); end
  def tsort_each_child(node); end
  def tsort_each_node; end

  class << self
    def each_strongly_connected_component(each_node, each_child); end
    def each_strongly_connected_component_from(node, each_child, id_map = T.unsafe(nil), stack = T.unsafe(nil)); end
    def strongly_connected_components(each_node, each_child); end
    def tsort(each_node, each_child); end
    def tsort_each(each_node, each_child); end
  end
end

class TSort::Cyclic < ::StandardError; end
