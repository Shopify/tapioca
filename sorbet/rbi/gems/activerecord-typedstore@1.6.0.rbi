# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `activerecord-typedstore` gem.
# Please instead update this file by running `bin/tapioca gem activerecord-typedstore`.


# source://activerecord-typedstore//lib/active_record/typed_store.rb#5
module ActiveRecord; end

# source://activerecord-typedstore//lib/active_record/typed_store.rb#6
module ActiveRecord::TypedStore; end

# source://activerecord-typedstore//lib/active_record/typed_store/behavior.rb#4
module ActiveRecord::TypedStore::Behavior
  extend ::ActiveSupport::Concern

  mixes_in_class_methods ::ActiveRecord::TypedStore::Behavior::ClassMethods

  # @return [Boolean]
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/behavior.rb#56
  def attribute?(attr_name); end

  # source://activerecord-typedstore//lib/active_record/typed_store/behavior.rb#34
  def changes; end

  # source://activerecord-typedstore//lib/active_record/typed_store/behavior.rb#44
  def clear_attribute_change(attr_name); end

  # source://activerecord-typedstore//lib/active_record/typed_store/behavior.rb#49
  def read_attribute(attr_name); end

  private

  # source://activerecord-typedstore//lib/active_record/typed_store/behavior.rb#78
  def attribute_names_for_partial_inserts; end

  # source://activerecord-typedstore//lib/active_record/typed_store/behavior.rb#85
  def attribute_names_for_partial_updates; end
end

# source://activerecord-typedstore//lib/active_record/typed_store/behavior.rb#7
module ActiveRecord::TypedStore::Behavior::ClassMethods
  # source://activerecord-typedstore//lib/active_record/typed_store/behavior.rb#8
  def define_attribute_methods; end

  # source://activerecord-typedstore//lib/active_record/typed_store/behavior.rb#18
  def define_typed_store_attribute_methods; end

  # source://activerecord-typedstore//lib/active_record/typed_store/behavior.rb#13
  def undefine_attribute_methods; end

  # source://activerecord-typedstore//lib/active_record/typed_store/behavior.rb#27
  def undefine_before_type_cast_method(attribute); end
end

# source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#6
class ActiveRecord::TypedStore::DSL
  # @return [DSL] a new instance of DSL
  # @yield [_self]
  # @yieldparam _self [ActiveRecord::TypedStore::DSL] the object that the method was called on
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#9
  def initialize(store_name, options); end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#55
  def accessors; end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#65
  def any(name, **options); end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#65
  def boolean(name, **options); end

  # Returns the value of attribute coder.
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#7
  def coder; end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#65
  def date(name, **options); end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#69
  def date_time(name, **options); end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#65
  def datetime(name, **options); end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#65
  def decimal(name, **options); end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#50
  def default_coder(attribute_name); end

  # Returns the value of attribute fields.
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#7
  def fields; end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#65
  def float(name, **options); end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#65
  def integer(name, **options); end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#61
  def keys(*_arg0, **_arg1, &_arg2); end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#65
  def string(name, **options); end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#65
  def text(name, **options); end

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#65
  def time(name, **options); end

  private

  # source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#73
  def accessor_key_for(name); end
end

# source://activerecord-typedstore//lib/active_record/typed_store/dsl.rb#63
ActiveRecord::TypedStore::DSL::NO_DEFAULT_GIVEN = T.let(T.unsafe(nil), Object)

# source://activerecord-typedstore//lib/active_record/typed_store/extension.rb#10
module ActiveRecord::TypedStore::Extension
  # source://activerecord-typedstore//lib/active_record/typed_store/extension.rb#11
  def typed_store(store_attribute, options = T.unsafe(nil), &block); end
end

# source://activerecord-typedstore//lib/active_record/typed_store/field.rb#4
class ActiveRecord::TypedStore::Field
  # @return [Field] a new instance of Field
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#7
  def initialize(name, type, options = T.unsafe(nil)); end

  # Returns the value of attribute accessor.
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#5
  def accessor; end

  # Returns the value of attribute array.
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#5
  def array; end

  # Returns the value of attribute blank.
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#5
  def blank; end

  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#26
  def cast(value); end

  # Returns the value of attribute default.
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#5
  def default; end

  # @return [Boolean]
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#22
  def has_default?; end

  # Returns the value of attribute name.
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#5
  def name; end

  # Returns the value of attribute null.
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#5
  def null; end

  # Returns the value of attribute type.
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#5
  def type; end

  # Returns the value of attribute type_sym.
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#5
  def type_sym; end

  private

  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#56
  def extract_default(value); end

  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#52
  def lookup_type(type, options); end

  # source://activerecord-typedstore//lib/active_record/typed_store/field.rb#63
  def type_cast(value, arrayize: T.unsafe(nil)); end
end

# source://activerecord-typedstore//lib/active_record/typed_store/field.rb#40
ActiveRecord::TypedStore::Field::TYPES = T.let(T.unsafe(nil), Hash)

# source://activerecord-typedstore//lib/active_record/typed_store/identity_coder.rb#4
module ActiveRecord::TypedStore::IdentityCoder
  extend ::ActiveRecord::TypedStore::IdentityCoder

  # source://activerecord-typedstore//lib/active_record/typed_store/identity_coder.rb#11
  def dump(data); end

  # source://activerecord-typedstore//lib/active_record/typed_store/identity_coder.rb#7
  def load(data); end
end

# source://activerecord-typedstore//lib/active_record/typed_store/type.rb#4
class ActiveRecord::TypedStore::Type < ::ActiveRecord::Type::Serialized
  # @return [Type] a new instance of Type
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/type.rb#5
  def initialize(typed_hash_klass, coder, subtype); end

  # @return [Boolean]
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/type.rb#42
  def changed_in_place?(raw_old_value, value); end

  # @return [Boolean]
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/type.rb#38
  def default_value?(value); end

  # source://activerecord-typedstore//lib/active_record/typed_store/type.rb#34
  def defaults; end

  # source://activerecord-typedstore//lib/active_record/typed_store/type.rb#11
  def deserialize(value); end

  # source://activerecord-typedstore//lib/active_record/typed_store/type.rb#23
  def serialize(value); end

  # source://activerecord-typedstore//lib/active_record/typed_store/type.rb#23
  def type_cast_for_database(value); end

  # source://activerecord-typedstore//lib/active_record/typed_store/type.rb#11
  def type_cast_from_database(value); end

  # source://activerecord-typedstore//lib/active_record/typed_store/type.rb#11
  def type_cast_from_user(value); end
end

# source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#4
class ActiveRecord::TypedStore::TypedHash < ::ActiveSupport::HashWithIndifferentAccess
  # @return [TypedHash] a new instance of TypedHash
  #
  # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#23
  def initialize(constructor = T.unsafe(nil)); end

  # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#29
  def []=(key, value); end

  # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#47
  def defaults_hash(&block); end

  # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#21
  def except(*_arg0, **_arg1, &_arg2); end

  # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#47
  def fields(&block); end

  # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#34
  def merge!(other_hash); end

  # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#21
  def slice(*_arg0, **_arg1, &_arg2); end

  # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#32
  def store(key, value); end

  # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#43
  def update(other_hash); end

  # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#20
  def with_indifferent_access(*_arg0, **_arg1, &_arg2); end

  # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#21
  def without(*_arg0, **_arg1, &_arg2); end

  private

  # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#49
  def cast_value(key, value); end

  class << self
    # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#9
    def create(fields); end

    # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#15
    def defaults_hash; end

    # Returns the value of attribute fields.
    #
    # source://activerecord-typedstore//lib/active_record/typed_store/typed_hash.rb#7
    def fields; end
  end
end
