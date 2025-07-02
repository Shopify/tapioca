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
        extend Tracker
        extend Reflection
        extend T::Sig

        @class_files = {}.compare_by_identity #: Hash[Module, Set[SourceLocation]]

        # Immediately activated upon load. Observes class/module definition.
        @class_tracepoint = TracePoint.trace(:class) do |tp|
          next if tp.self.singleton_class?

          key = tp.self

          path = tp.path
          if File.exist?(path)
            loc = build_source_location(tp, caller_locations)
          else
            caller_location = T.must(caller_locations)
              .find { |loc| loc.path && File.exist?(loc.path) }

            next unless caller_location

            loc = SourceLocation.from_loc([
              caller_location.absolute_path || "",
              caller_location.lineno,
            ])
          end

          (@class_files[key] ||= Set.new) << loc
        end

        @creturn_tracepoint = TracePoint.trace(:c_return) do |tp|
          next unless tp.method_id == :new

          key = tp.return_value
          next unless Module === key

          loc = build_source_location(tp, caller_locations)
          (@class_files[key] ||= Set.new) << loc
        end

        class << self
          extend T::Sig

          def disable!
            @class_tracepoint.disable
            @creturn_tracepoint.disable
            super
          end

          def build_source_location(tp, locations)
            loc = resolve_loc(locations)
            file = loc&.file
            line = loc&.line
            lineno = file && File.identical?(file, tp.path) ? tp.lineno : (line || 0)

            SourceLocation.from_loc([file || "", lineno])
          end

          # Returns the files in which this class or module was opened. Doesn't know
          # about situations where the class was opened prior to +require+ing,
          # or where metaprogramming was used via +eval+, etc.
          #: (Module klass) -> Set[String]
          def files_for(klass)
            locations_for(klass).map(&:file).to_set
          end

          #: (Module klass) -> Set[SourceLocation]
          def locations_for(klass)
            @class_files.fetch(klass, Set.new)
          end
        end
      end
    end
  end
end
