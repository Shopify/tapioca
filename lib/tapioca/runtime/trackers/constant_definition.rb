# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      # Registers a TracePoint immediately upon load to track points at which
      # classes and modules are opened for definition. This is used to track
      # correspondence between classes/modules and files, as this information isn't
      # available in the ruby runtime without extra accounting.
      module ConstantDefinition
        extend Reflection
        extend T::Sig

        class ConstantLocation < T::Struct
          const :lineno, Integer
          const :path, String
        end

        @class_files = {}.compare_by_identity

        # Immediately activated upon load. Observes class/module definition.
        TracePoint.trace(:class, :c_return) do |tp|
          file = tp.path
          lineno = tp.lineno

          case tp.event
          when :class
            next if tp.self.singleton_class?

            key = tp.self

            if file == "(eval)"
              caller_location = T.must(caller_locations)
                .drop_while { |loc| loc.path == "(eval)" }
                .first

              file = caller_location&.path
              lineno = caller_location&.lineno
            end
          when :c_return
            next unless tp.method_id == :new
            next unless Module === tp.return_value

            key = tp.return_value
          else
            next
          end

          @class_files[key] ||= Set.new
          @class_files[key] << ConstantLocation.new(path: T.must(file), lineno: T.must(lineno))
        end

        # Returns the files in which this class or module was opened. Doesn't know
        # about situations where the class was opened prior to +require+ing,
        # or where metaprogramming was used via +eval+, etc.
        def self.files_for(klass)
          locations_for(klass).map(&:path).to_set
        end

        def self.locations_for(klass)
          @class_files.fetch(klass, Set.new)
        end
      end
    end
  end
end
