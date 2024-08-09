# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module MethodDefinition
        extend Tracker
        extend T::Sig

        @method_definitions = {}

        class << self
          extend T::Sig

          sig { params(method: UnboundMethod).void }
          def register(method)
            return unless enabled?

            @method_definitions[method] = Reflection.resolve_loc(caller_locations)
          end

          sig { params(method: UnboundMethod).returns(T.nilable(String)) }
          def method_definition_for(method)
            @method_definitions[method] || method.source_location&.first
          end
        end
      end
    end
  end
end

class Module
  prepend(Module.new do
    def method_added(method_name)
      Tapioca::Runtime::Trackers::MethodDefinition.register(instance_method(method_name))
      super
    end
  end)
end
