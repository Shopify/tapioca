# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module MethodDefinition
        extend Tracker
        extend T::Sig

        @method_definitions = T.let(
          {}.compare_by_identity,
          T::Hash[Module, T::Hash[Symbol, T.nilable([String, Integer])]],
        )

        class << self
          extend T::Sig

          sig { params(method: T.any(Method, UnboundMethod), locations: T::Array[Thread::Backtrace::Location]).void }
          def register(method, locations)
            return unless enabled?

            loc = Reflection.resolve_loc(locations)
            return unless loc

            methods_for_owner(method.owner).store(method.name, loc)
          end

          sig { params(method: T.any(Method, UnboundMethod)).returns(T.nilable([String, Integer])) }
          def method_definition_for(method)
            methods_for_owner(method.owner).fetch(method.name, method.source_location)
          end

          private

          sig { params(owner: Module).returns(T::Hash[Symbol, T.nilable([String, Integer])]) }
          def methods_for_owner(owner)
            @method_definitions[owner] ||= {}
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
