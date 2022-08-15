# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module Mixin
        extend T::Sig

        @constants_to_mixin_locations = {}.compare_by_identity
        @mixins_to_constants = {}.compare_by_identity
        @enabled = true

        class Type < T::Enum
          enums do
            Prepend = new
            Include = new
            Extend = new
          end
        end

        class << self
          extend T::Sig

          sig do
            type_parameters(:Result)
              .params(block: T.proc.returns(T.type_parameter(:Result)))
              .returns(T.type_parameter(:Result))
          end
          def with_disabled_registration(&block)
            @enabled = false

            block.call
          ensure
            @enabled = true
          end

          sig do
            params(
              constant: Module,
              mixin: Module,
              mixin_type: Type,
            ).void
          end
          def register(constant, mixin, mixin_type)
            return unless @enabled

            location = Reflection.resolve_loc(caller_locations)

            constants = constants_with_mixin(mixin)
            constants.fetch(mixin_type).store(constant, location)
          end

          sig { params(mixin: Module).returns(T::Hash[Type, T::Hash[Module, String]]) }
          def constants_with_mixin(mixin)
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

      register_extend_on_attached_class(constant) if constant.singleton_class?

      super
    end

    def append_features(constant)
      Tapioca::Runtime::Trackers::Mixin.register(
        constant,
        self,
        Tapioca::Runtime::Trackers::Mixin::Type::Include,
      )

      register_extend_on_attached_class(constant) if constant.singleton_class?

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

    private

    # Including or prepending on a singleton class is functionally equivalent to extending the
    # attached class. Registering the mixin as an extend on the attached class ensures that
    # this mixin can be found whether searching for an include/prepend on the singleton class
    # or an extend on the attached class.
    def register_extend_on_attached_class(constant)
      attached_class = Tapioca::Runtime::Reflection.attached_class_of(constant)

      Tapioca::Runtime::Trackers::Mixin.register(
        T.cast(attached_class, Module),
        self,
        Tapioca::Runtime::Trackers::Mixin::Type::Extend,
      ) if attached_class
    end
  end)
end
