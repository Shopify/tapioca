# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module MethodDefinition
        extend Tracker
        extend T::Sig

        @method_definitions = {}.compare_by_identity

        class << self
          extend T::Sig

          sig { params(constant: Module, method_name: Symbol).void }
          def register(constant, method_name)
            return unless enabled?

            @method_definitions[constant] ||= {}
            @method_definitions[constant][method_name] = Reflection.resolve_loc(caller_locations)
          end

          sig { params(constant: Module).returns(T::Hash[Symbol, T::Array[T::Hash[Symbol, String]]]) }
          def method_definitions_for(constant)
            @method_definitions[constant] || {}
          end
        end
      end
    end
  end
end

class Module
  prepend(Module.new do
    def method_added(method_name)
      Tapioca::Runtime::Trackers::MethodDefinition.register(self, method_name)
      super
    end
  end)
end

# TODO: are there other methods I have to override here?
