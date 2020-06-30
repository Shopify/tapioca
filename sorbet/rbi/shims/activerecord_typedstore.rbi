# typed: strict

# ActiveRecord TypedStore dynamically adds a mixin and class attributes
# so replicating that behaviour here.

class ActiveRecord::Base
  include(::ActiveRecord::TypedStore::Behavior)
  class_attribute :typed_stores, :store_accessors, instance_accessor: false
end
