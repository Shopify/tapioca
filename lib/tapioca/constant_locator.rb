# typed: true
# frozen_string_literal: true

require "set"

module Tapioca
  # Registers a TracePoint immediately upon load to track points at which
  # classes and modules are opened for definition. This is used to track
  # correspondence between classes/modules and files, as this information isn't
  # available in the ruby runtime without extra accounting.
  module ConstantLocator
    @class_files = {}

    NAME = Module.instance_method(:name)
    private_constant :NAME

    # Immediately activated upon load. Observes class/module definition.
    TracePoint.trace(:class) do |tp|
      unless tp.self.singleton_class?
        key = NAME.bind(tp.self).call
        @class_files[key] ||= Set.new
        @class_files[key] << tp.path
      end
    end

    # Returns the files in which this class or module was opened. Doesn't know
    # about situations where the class was opened prior to +require+ing,
    # or where metaprogramming was used via +eval+, etc.
    def files_for(klass)
      name = String === klass ? klass : NAME.bind(klass).call
      files = @class_files[name]
      files || Set.new
    end
    module_function :files_for
  end
end
