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
          T::Hash[Module, T::Hash[Symbol, T::Array[[String, Integer]]]],
        )

        class << self
          extend T::Sig

          sig { params(method_name: Symbol, owner: Module, locations: T::Array[Thread::Backtrace::Location]).void }
          def register(method_name, owner, locations)
            return unless enabled?
            # If Sorbet runtime is redefining a method, it sets this to true.
            # In those cases, we should skip the registration, as the method's original
            # definition should already be registered.
            return if T::Private::DeclState.current.skip_on_method_added

            loc = Reflection.resolve_loc(locations)
            return unless loc

            registrations_for(method_name, owner) << loc
          end

          sig { params(method_name: Symbol, owner: Module).returns(T::Array[[String, Integer]]) }
          def method_definitions_for(method_name, owner)
            definitions = registrations_for(method_name, owner)

            if definitions.empty?
              source_loc = owner.instance_method(method_name).source_location
              definitions = [source_loc] if source_loc
            end

            definitions
          end

          private

          sig { params(method_name: Symbol, owner: Module).returns(T::Array[[String, Integer]]) }
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
