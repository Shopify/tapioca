# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      # Registers a TracePoint immediately upon load to track points at which
      # classes and modules are opened for definition. This is used to track
      # correspondence between classes/modules and files, as this information isn't
      # available in the ruby runtime without extra accounting.
      module ConstantType
        extend Tracker
        extend Reflection
        extend T::Sig

        @constant_types_by_location_and_value = {}

        T.singleton_class.prepend(Module.new do
          def let(name, type, checked: true)
            if ConstantType.enabled?
              loc = ConstantType.build_constant_location(Kernel.caller_locations(1, 1))
              ConstantType.register(name, type, loc)
            end
            super
          end
        end)

        class << self
          def build_constant_location(locations)
            loc = locations.first

            [loc.path || loc.absolute_path, loc.lineno]
          end

          def register(name, type, loc)
            @constant_types_by_location_and_value[[loc, name]] = type
          end

          # Returns the files in which this class or module was opened. Doesn't know
          # about situations where the class was opened prior to +require+ing,
          # or where metaprogramming was used via +eval+, etc.
          def type_for_constant(name, constant)
            @constant_types_by_location_and_value.fetch(
              [
                Object.const_source_location(name),
                constant,
              ],
              class_of(constant),
            )
          end
        end
      end
    end
  end
end
