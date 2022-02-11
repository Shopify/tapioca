# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module Mixin
        extend T::Sig

        @mixin_map = {}.compare_by_identity

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
            mod: Module,
            mixin_type: Type,
            locations: T.nilable(T::Array[Thread::Backtrace::Location])
          ).void
        end
        def self.register(constant, mod, mixin_type, locations)
          locations ||= []
          locations.map!(&:absolute_path).uniq!
          locs = mixin_locations_for(constant)
          locs.fetch(mixin_type).store(mod, T.cast(locations, T::Array[String]))
        end

        sig { params(constant: Module).returns(T::Hash[Type, T::Hash[Module, T::Array[String]]]) }
        def self.mixin_locations_for(constant)
          @mixin_map[constant] ||= {
            Type::Prepend => {}.compare_by_identity,
            Type::Include => {}.compare_by_identity,
            Type::Extend => {}.compare_by_identity,
          }
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
        caller_locations
      )
      super
    end

    def append_features(constant)
      Tapioca::Runtime::Trackers::Mixin.register(
        constant,
        self,
        Tapioca::Runtime::Trackers::Mixin::Type::Include,
        caller_locations
      )
      super
    end

    def extend_object(obj)
      Tapioca::Runtime::Trackers::Mixin.register(
        obj,
        self,
        Tapioca::Runtime::Trackers::Mixin::Type::Extend,
        caller_locations
      ) if Module === obj
      super
    end
  end)
end
