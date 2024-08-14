# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module MethodDefinition
        extend Tracker
        extend T::Sig

        @method_definitions = T.let({}, T::Hash[UnboundMethod, [String, Integer]])

        class << self
          extend T::Sig

          sig { params(method: UnboundMethod, locations: T::Array[Thread::Backtrace::Location]).void }
          def register(method, locations)
            return unless enabled?

            loc = Reflection.resolve_loc(locations)
            @method_definitions[method] = loc if loc
          end

          sig { params(method: UnboundMethod).returns(T.nilable([String, Integer])) }
          def method_definition_for(method)
            @method_definitions[method] || method.source_location
          end
        end
      end
    end
  end
end

class Module
  prepend(Module.new do
    def singleton_method_added(method_name)
      Tapioca::Runtime::Trackers::MethodDefinition.register(
        Tapioca::Runtime::Reflection.method_of(self, method_name),
        caller_locations,
      )
      super
    end

    def method_added(method_name)
      Tapioca::Runtime::Trackers::MethodDefinition.register(
        instance_method(method_name),
        caller_locations,
      )
      super
    end
  end)
end
