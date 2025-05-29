# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module Mixin
        extend Tracker
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

        class << self
          extend T::Sig

          #: [Result] { -> Result } -> Result
          def with_disabled_registration(&block)
            with_disabled_tracker(&block)
          end

          #: (Module constant, Module mixin, Type mixin_type) -> void
          def register(constant, mixin, mixin_type)
            return unless enabled?

            location = Reflection.resolve_loc(caller_locations)
            return unless location

            register_with_location(constant, mixin, mixin_type, location.file)
          end

          def resolve_to_attached_class(constant, mixin, mixin_type)
            attached_class = Reflection.attached_class_of(constant)
            return unless attached_class

            if mixin_type == Type::Include || mixin_type == Type::Prepend
              location = mixin_location(mixin, mixin_type, constant)
              register_with_location(constant, mixin, Type::Extend, T.must(location))
            end

            attached_class
          end

          #: (Module mixin) -> Hash[Type, Hash[Module, String]]
          def constants_with_mixin(mixin)
            find_or_initialize_mixin_lookup(mixin)
          end

          #: (Module mixin, Type mixin_type, Module constant) -> String?
          def mixin_location(mixin, mixin_type, constant)
            find_or_initialize_mixin_lookup(mixin).dig(mixin_type, constant)
          end

          private

          #: (Module constant, Module mixin, Type mixin_type, String location) -> void
          def register_with_location(constant, mixin, mixin_type, location)
            return unless @enabled

            constants = find_or_initialize_mixin_lookup(mixin)
            constants.fetch(mixin_type).store(constant, location)
          end

          #: (Module mixin) -> Hash[Type, Hash[Module, String]]
          def find_or_initialize_mixin_lookup(mixin)
            @mixins_to_constants[mixin] ||= {
              Type::Prepend => {}.compare_by_identity,
              Type::Include => {}.compare_by_identity,
              Type::Extend => {}.compare_by_identity,
            }
          end
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
