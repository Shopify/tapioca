# typed: strict
# frozen_string_literal: true

require "set"

module Tapioca
  # Registers a TracePoint immediately upon load to track points at which
  # classes and modules are opened for definition. This is used to track
  # correspondence between classes/modules and files, as this information isn't
  # available in the ruby runtime without extra accounting.
  module ConstantTracker
    extend T::Sig
    extend Reflection

    @constant_name_to_files = T.let({}, T::Hash[String, T::Set[String]])
    @file_to_constant_names = T.let({}, T::Hash[String, T::Set[String]])

    # Immediately activated upon load. Observes class/module definition.
    TracePoint.trace(:class) do |tp|
      next if tp.self.singleton_class?

      constant_name = name_of(tp.self)
      next unless constant_name

      file = tp.path

      if file == "(eval)"
        file = T.must(caller_locations)
          .drop_while { |loc| loc.path == "(eval)" }
          .first&.path
      end

      next unless file

      files = (@constant_name_to_files[constant_name] ||= Set.new)
      files << file

      constant_names = (@file_to_constant_names[file] ||= Set.new)
      constant_names << constant_name
    end

    class << self
      extend T::Sig

      # Returns the files in which this class or module was opened. Doesn't know
      # about situations where the class was opened prior to +require+ing,
      # or where metaprogramming was used via +eval+, etc.
      sig { params(klass: T.any(Module, String)).returns(T::Set[String]) }
      def files_for(klass)
        name = String === klass ? klass : name_of(klass)

        return Set.new unless name

        @constant_name_to_files.fetch(name, Set.new)
      end

      sig { params(files: T::Array[T.any(String, Pathname)]).returns(T::Set[String]) }
      def constants_for_files(files)
        files.map do |file|
          @file_to_constant_names.fetch(file.to_s, Set.new)
        end.inject(:merge)
      end

      sig { void }
      def finalize!
        # Keep a list of seen constants
        seen = [].to_set

        # Grab a snapshot of current constant names.
        # We want an immutable snapshot because the operation we will
        # perform below will add more constant names to the map.
        constant_names = @constant_name_to_files.keys.dup.freeze

        # Descend into subconstants to trigger autoload for them.
        constant_names.each do |constant_name|
          descend_into(constant_name, Object, seen)
        end
      end

      private

      sig { params(constant_name: String, namespace: Module, seen: T::Set[Module]).void }
      def descend_into(constant_name, namespace, seen)
        constant = constantize(constant_name, inherit: true, namespace: Object)

        # Skip if unresolveable
        return unless constant
        # Skip if not a module/class
        return unless Module === constant
        # Skip if we have already seen this one before
        return if seen.include?(constant)

        # Mark this as seen
        seen.add(constant)

        constants_of(constant).each do |name|
          descend_into(name.to_s, constant, seen)
        end
      end
    end
  end
end
