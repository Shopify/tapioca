# typed: true
# frozen_string_literal: true

require "set"

module Tapioca
  # Registers a TracePoint immediately upon load to track points at which
  # classes and modules are opened for definition. This is used to track
  # correspondence between classes/modules and files, as this information isn't
  # available in the ruby runtime without extra accounting.
  module ConstantLocator
    extend Reflection

    @class_files = {}

    # Immediately activated upon load. Observes class/module definition.
    TracePoint.trace(:class) do |tp|
      unless tp.self.singleton_class?
        key = name_of(tp.self)
        @class_files[key] ||= Set.new
        @class_files[key] << tp.path
      end
    end

    # Returns the files in which this class or module was opened. Doesn't know
    # about situations where the class was opened prior to +require+ing,
    # or where metaprogramming was used via +eval+, etc.
    def self.files_for(klass)
      name = String === klass ? klass : name_of(klass)
      files = @class_files[name]
      files || Set.new
    end
  end
end
