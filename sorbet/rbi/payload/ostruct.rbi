# typed: __STDLIB_INTERNAL

class OpenStruct
  def initialize(hash = T.unsafe(nil)); end

  def ==(other); end
  def [](name); end
  def []=(name, value); end
  def __id__!; end
  def __send__!(*_arg0); end
  def class!; end
  def clone!(freeze: T.unsafe(nil)); end
  def define_singleton_method!(*_arg0); end
  def delete_field(name, &block); end
  def delete_field!(name, &block); end
  def dig(name, *names); end
  def dig!(name, *names); end
  def display!(*_arg0); end
  def dup!; end
  def each_pair; end
  def each_pair!; end
  def encode_with(coder); end
  def encode_with!(coder); end
  def enum_for!(*_arg0); end
  def eql?(other); end
  def extend!(*_arg0); end
  def freeze; end
  def freeze!; end
  def gem!(dep, *reqs); end
  def hash; end
  def hash!; end
  def init_with(coder); end
  def init_with!(coder); end
  def inspect; end
  def inspect!; end
  def instance_eval!(*_arg0); end
  def instance_exec!(*_arg0); end
  def instance_variable_get!(_arg0); end
  def instance_variable_set!(_arg0, _arg1); end
  def instance_variables!; end
  def itself!; end
  def marshal_dump; end
  def marshal_dump!; end
  def method!(_arg0); end
  def methods!(*_arg0); end
  def object_id!; end
  def pretty_inspect!; end
  def pretty_print!(q); end
  def pretty_print_cycle!(q); end
  def pretty_print_inspect!; end
  def pretty_print_instance_variables!; end
  def private_methods!(*_arg0); end
  def protected_methods!(*_arg0); end
  def public_method!(_arg0); end
  def public_methods!(*_arg0); end
  def public_send!(*_arg0); end
  def remove_instance_variable!(_arg0); end
  def send!(*_arg0); end
  def singleton_class!; end
  def singleton_method!(_arg0); end
  def singleton_methods!(*_arg0); end
  def table; end
  def tap!; end
  def then!; end
  def to_enum!(*_arg0); end
  def to_h(&block); end
  def to_h!(&block); end
  def to_s; end
  def to_s!; end
  def yield_self!; end

  protected

  def table!; end

  private

  def block_given!; end
  def initialize_clone(orig); end
  def initialize_dup(orig); end
  def is_method_protected!(name); end
  def marshal_load(hash); end
  def method_missing(mid, *args); end
  def new_ostruct_member!(name); end
  def raise!(*_arg0); end
  def set_ostruct_member_value!(name, value); end
  def update_to_values!(hash); end
end
