# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module MethodDefinition
        extend Tracker
        extend T::Sig

        @method_definitions = {}.compare_by_identity #: Hash[Module, Hash[Symbol, Array[SourceLocation]]]

        class << self
          #: (Symbol method_name, Module owner, Array[Thread::Backtrace::Location] locations) -> void
          def register(method_name, owner, locations)
            return unless enabled?

            loc = Reflection.resolve_loc(locations)
            return unless loc

            registrations_for(method_name, owner) << loc
          end

          #: (Symbol method_name, Module owner) -> Array[SourceLocation]
          def method_definitions_for(method_name, owner)
            definitions = registrations_for(method_name, owner)

            if definitions.empty?
              source_loc = owner.instance_method(method_name).source_location
              definitions = [source_loc] if source_loc
            end

            definitions
          end

          private

          #: (Symbol method_name, Module owner) -> Array[SourceLocation]
          def registrations_for(method_name, owner)
            owner_lookup = (@method_definitions[owner] ||= {})
            owner_lookup[method_name] ||= []
          end
        end
      end
    end
  end
end

class Module
  prepend(Module.new do
    def singleton_method_added(method_name)
      Tapioca::Runtime::Trackers::MethodDefinition.register(method_name, singleton_class, caller_locations)
      super
    end

    def method_added(method_name)
      Tapioca::Runtime::Trackers::MethodDefinition.register(method_name, self, caller_locations)
      super
    end
  end)
end
