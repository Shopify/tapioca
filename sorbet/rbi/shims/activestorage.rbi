# typed: strict

# ActiveStorage dynamically adds a mixin and class attributes
# so replicating that behaviour here.

class ActiveRecord::Base
  # include(::ActiveStorage::Attached::Model)
  # class_attribute :attachment_reflections, instance_writer: false, default: {}
end
