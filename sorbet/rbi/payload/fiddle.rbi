# typed: __STDLIB_INTERNAL

module Fiddle
  private

  def dlopen(library); end
  def dlunwrap(_arg0); end
  def dlwrap(_arg0); end
  def free(_arg0); end
  def malloc(_arg0); end
  def realloc(_arg0, _arg1); end

  class << self
    def dlopen(library); end
    def dlunwrap(_arg0); end
    def dlwrap(_arg0); end
    def free(_arg0); end
    def last_error; end
    def last_error=(error); end
    def malloc(_arg0); end
    def realloc(_arg0, _arg1); end
  end
end

module Fiddle::BasicTypes
  private

  def included(m); end

  class << self
    def included(m); end
  end
end

module Fiddle::CParser
  def parse_ctype(ty, tymap = T.unsafe(nil)); end
  def parse_signature(signature, tymap = T.unsafe(nil)); end
  def parse_struct_signature(signature, tymap = T.unsafe(nil)); end

  private

  def compact(signature); end
  def split_arguments(arguments, sep = T.unsafe(nil)); end
end

class Fiddle::CStruct
  def each; end
  def each_pair; end
  def replace(another); end
  def to_h; end

  private

  def unstruct(value); end

  class << self
    def entity_class; end
    def offsetof(name, members, types); end
  end
end

module Fiddle::CStructBuilder
  private

  def create(klass, types, members); end

  class << self
    def create(klass, types, members); end
  end
end

class Fiddle::CStructEntity < ::Fiddle::Pointer
  def initialize(addr, types, func = T.unsafe(nil)); end

  def [](*args); end
  def []=(*args); end
  def assign_names(members); end
  def set_ctypes(types); end
  def to_s; end

  class << self
    def alignment(types); end
    def malloc(types, func = T.unsafe(nil), size = T.unsafe(nil), &block); end
    def size(types); end
  end
end

class Fiddle::CUnion
  class << self
    def entity_class; end
    def offsetof(name, members, types); end
  end
end

class Fiddle::CUnionEntity < ::Fiddle::CStructEntity
  def set_ctypes(types); end

  class << self
    def size(types); end
  end
end

class Fiddle::ClearedReferenceError < ::Fiddle::Error; end

class Fiddle::Closure
  def initialize(*_arg0); end

  def args; end
  def ctype; end
  def free; end
  def freed?; end
  def to_i; end

  class << self
    def create(*args); end
  end
end

class Fiddle::Closure::BlockCaller < ::Fiddle::Closure
  def initialize(ctype, args, abi = T.unsafe(nil), &block); end

  def call(*args); end
end

class Fiddle::CompositeHandler
  def initialize(handlers); end

  def [](symbol); end
  def handlers; end
  def sym(symbol); end
end

class Fiddle::DLError < ::Fiddle::Error; end
class Fiddle::Error < ::StandardError; end

class Fiddle::Function
  def initialize(*_arg0); end

  def abi; end
  def call(*_arg0); end
  def name; end
  def need_gvl?; end
  def ptr; end
  def to_i; end
  def to_proc; end
end

class Fiddle::Handle
  def initialize(*_arg0); end

  def [](_arg0); end
  def close; end
  def close_enabled?; end
  def disable_close; end
  def enable_close; end
  def file_name; end
  def sym(_arg0); end
  def sym_defined?(_arg0); end
  def to_i; end
  def to_ptr; end

  class << self
    def [](_arg0); end
    def sym(_arg0); end
    def sym_defined?(_arg0); end
  end
end

module Fiddle::Importer
  extend ::Fiddle
  extend ::Fiddle::CParser

  def [](name); end
  def bind(signature, *opts, &blk); end
  def bind_function(name, ctype, argtype, call_type = T.unsafe(nil), &block); end
  def create_value(ty, val = T.unsafe(nil)); end
  def dlload(*libs); end
  def extern(signature, *opts); end
  def handler; end
  def import_function(name, ctype, argtype, call_type = T.unsafe(nil)); end
  def import_symbol(name); end
  def import_value(ty, addr); end
  def sizeof(ty); end
  def struct(signature); end
  def typealias(alias_type, orig_type); end
  def union(signature); end
  def value(ty, val = T.unsafe(nil)); end

  private

  def parse_bind_options(opts); end
  def type_alias; end
end

class Fiddle::MemoryView
  def initialize(_arg0); end

  def [](*_arg0); end
  def byte_size; end
  def format; end
  def item_size; end
  def ndim; end
  def obj; end
  def readonly?; end
  def release; end
  def shape; end
  def strides; end
  def sub_offsets; end
  def to_s; end

  class << self
    def export(_arg0); end
  end
end

module Fiddle::PackInfo
  private

  def align(addr, align); end

  class << self
    def align(addr, align); end
  end
end

class Fiddle::Packer
  def initialize(types); end

  def pack(ary); end
  def size; end
  def unpack(ary); end

  private

  def parse_types(types); end

  class << self
    def [](*types); end
  end
end

class Fiddle::Pinned
  def initialize(_arg0); end

  def clear; end
  def cleared?; end
  def ref; end
end

class Fiddle::Pointer
  def initialize(*_arg0); end

  def +(_arg0); end
  def +@; end
  def -(_arg0); end
  def -@; end
  def <=>(_arg0); end
  def ==(_arg0); end
  def [](*_arg0); end
  def []=(*_arg0); end
  def call_free; end
  def eql?(_arg0); end
  def free; end
  def free=(_arg0); end
  def freed?; end
  def inspect; end
  def null?; end
  def ptr; end
  def ref; end
  def size; end
  def size=(_arg0); end
  def to_i; end
  def to_int; end
  def to_s(*_arg0); end
  def to_str(*_arg0); end
  def to_value; end

  class << self
    def [](_arg0); end
    def malloc(*_arg0); end
    def to_ptr(_arg0); end
  end
end

class Fiddle::StructArray < ::Array
  def initialize(ptr, type, initial_values); end

  def []=(index, value); end
  def to_ptr; end
end

module Fiddle::Types; end

module Fiddle::ValueUtil
  def signed_value(val, ty); end
  def unsigned_value(val, ty); end
  def wrap_arg(arg, ty, funcs = T.unsafe(nil), &block); end
  def wrap_args(args, tys, funcs, &block); end
end

module Fiddle::Win32Types
  private

  def included(m); end

  class << self
    def included(m); end
  end
end
