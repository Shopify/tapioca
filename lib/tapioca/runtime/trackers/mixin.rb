# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module Mixin
        extend T::Sig

        @constants_to_mixin_locations = {}.compare_by_identity
        @mixins_to_constants = {}.compare_by_identity

        class Type < T::Enum
          enums do
            Prepend = new
            Include = new
            Extend = new
          end
        end

        sig do
          params(
            constant: Module,
            mixin: Module,
            mixin_type: Type,
          ).void
        end
        def self.register(constant, mixin, mixin_type)
          location = Reflection.required_from_location

          locs = mixin_locations_for(constant)
          locs.fetch(mixin_type).store(mixin, location)

          constants = constants_with_mixin(mixin)
          constants[constant] = location
        end

        sig { params(constant: Module).returns(T::Hash[Type, T::Hash[Module, String]]) }
        def self.mixin_locations_for(constant)
          @constants_to_mixin_locations[constant] ||= {
            Type::Prepend => {}.compare_by_identity,
            Type::Include => {}.compare_by_identity,
            Type::Extend => {}.compare_by_identity,
          }
        end

        sig { params(mixin: Module).returns(T::Hash[Module, String]) }
        def self.constants_with_mixin(mixin)
          @mixins_to_constants[mixin] ||= {}.compare_by_identity
        end
      end
    end
  end
end

class Module
  prepend(Module.new do
    def prepend_features(constant)
      Tapioca::Runtime::Trackers::Mixin.register(
        constant,
        self,
        Tapioca::Runtime::Trackers::Mixin::Type::Prepend,
      )
      super
    end

    def append_features(constant)
      Tapioca::Runtime::Trackers::Mixin.register(
        constant,
        self,
        Tapioca::Runtime::Trackers::Mixin::Type::Include,
      )
      super
    end

    def extend_object(obj)
      Tapioca::Runtime::Trackers::Mixin.register(
        obj,
        self,
        Tapioca::Runtime::Trackers::Mixin::Type::Extend,
      ) if Module === obj
      super
    end
  end)
end
