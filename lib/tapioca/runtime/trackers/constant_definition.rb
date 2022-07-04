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

        @class_files = {}

        # Immediately activated upon load. Observes class/module definition.
        TracePoint.trace(:class) do |tp|
          unless tp.self.singleton_class?
            key = name_of(tp.self)
            file = tp.path
            lineno = tp.lineno

            if file == "(eval)"
              caller_location = T.must(caller_locations)
                .drop_while { |loc| loc.path == "(eval)" }
                .first

              file = caller_location&.path
              lineno = caller_location&.lineno
            end

            @class_files[key] ||= Set.new
            @class_files[key] << ConstantLocation.new(path: T.must(file), lineno: T.must(lineno))
          end
        end

        # Returns the files in which this class or module was opened. Doesn't know
        # about situations where the class was opened prior to +require+ing,
        # or where metaprogramming was used via +eval+, etc.
        def self.files_for(klass)
          name = String === klass ? klass : name_of(klass)
          files = @class_files[name]
          files&.map(&:path)&.to_set || Set.new
        end
      end
    end
  end
end
