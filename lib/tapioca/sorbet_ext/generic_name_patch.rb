# typed: true
# frozen_string_literal: true

module T
  module Generic
    # This module intercepts calls to generic type instantiations and type variable definitions.
    # Tapioca stores the data from those calls in a `GenericTypeRegistry` which can then be used
    # to look up the original call details when we are trying to do code generation.
    #
    # We are interested in the data of the `[]`, `type_member` and `type_template` calls which
    # are all needed to generate good generic information at runtime.
    module TypeStoragePatch
      def [](*types)
        # `T::Generic#[]` just returns `self`, so let's call and store it.
        constant = super
        # `register_type` method builds and returns an instantiated clone of the generic type
        # so, we just return that from this method as well.
        Tapioca::Runtime::GenericTypeRegistry.register_type(constant, types)
      end

      def type_member(variance = :invariant, fixed: nil, lower: nil, upper: nil, &bounds_proc)
        # `T::Generic#type_member` just instantiates a `T::Type::TypeMember` instance and returns it.
        # We use that when registering the type member and then later return it from this method.
        Tapioca::TypeVariableModule.new(
          T.cast(self, Module),
          Tapioca::TypeVariableModule::Type::Member,
          variance,
          fixed,
          lower,
          upper,
          bounds_proc,
        ).tap do |type_variable|
          Tapioca::Runtime::GenericTypeRegistry.register_type_variable(self, type_variable)
        end
      end

      def type_template(variance = :invariant, fixed: nil, lower: nil, upper: nil, &bounds_proc)
        # `T::Generic#type_template` just instantiates a `T::Type::TypeTemplate` instance and returns it.
        # We use that when registering the type template and then later return it from this method.
        Tapioca::TypeVariableModule.new(
          T.cast(self, Module),
          Tapioca::TypeVariableModule::Type::Template,
          variance,
          fixed,
          lower,
          upper,
          bounds_proc,
        ).tap do |type_variable|
          Tapioca::Runtime::GenericTypeRegistry.register_type_variable(self, type_variable)
        end
      end

      def has_attached_class!(variance = :invariant, &bounds_proc)
        Tapioca::Runtime::GenericTypeRegistry.register_type_variable(
          self,
          Tapioca::TypeVariableModule.new(
            T.cast(self, Module),
            Tapioca::TypeVariableModule::Type::HasAttachedClass,
            variance,
            nil,
            nil,
            nil,
            bounds_proc,
          ),
        )
      end
    end

    prepend TypeStoragePatch
  end

  module Types
    class Simple
      module GenericPatch
        # This method intercepts calls to the `name` method for simple types, so that
        # it can ask the name to the type if the type is generic, since, by this point,
        # we've created a clone of that type with the `name` method returning the
        # appropriate name for that specific concrete type.
        def name
          if T::Generic === @raw_type
            # for types that are generic, use the name
            # returned by the "name" method of this instance
            @name ||= T.unsafe(@raw_type).name.freeze
          else
            # otherwise, fallback to the normal name lookup
            super
          end
        end
      end

      prepend GenericPatch
    end
  end

  module Utils
    # This duplication is required to preserve backwards compatibility with sorbet-runtime versions prior to the
    # introduction of the `Private` module in https://github.com/sorbet/sorbet/pull/6559.
    if defined?(T::Utils::Private)
      module Private
        module PrivateCoercePatch
          def coerce_and_check_module_types(val, check_val, check_module_type)
            if val.is_a?(Tapioca::TypeVariableModule)
              val.coerce_to_type_variable
            elsif val.respond_to?(:__tapioca_override_type)
              val.__tapioca_override_type
            else
              super
            end
          end
        end

        class << self
          prepend(PrivateCoercePatch)
        end
      end
    else
      module CoercePatch
        def coerce(val)
          if val.is_a?(Tapioca::TypeVariableModule)
            val.coerce_to_type_variable
          elsif val.respond_to?(:__tapioca_override_type)
            val.__tapioca_override_type
          else
            super
          end
        end
      end

      class << self
        prepend(CoercePatch)
      end
    end
  end
end

module Tapioca
  class TypeVariable < ::T::Types::TypeVariable
    def initialize(name, variance)
      @name = name
      super(variance)
    end

    attr_reader :name
  end

  # This is subclassing from `Module` so that instances of this type will be modules.
  # The reason why we want that is because that means those instances will automatically
  # get bound to the constant names they are assigned to by Ruby. As a result, we don't
  # need to do any matching of constants to type variables to bind their names, Ruby will
  # do that automatically for us and we get the `name` method for free from `Module`.
  class TypeVariableModule < Module
    extend T::Sig

    class Type < T::Enum
      enums do
        Member = new("type_member")
        Template = new("type_template")
        HasAttachedClass = new("has_attached_class!")
      end
    end

    sig { returns(Type) }
    attr_reader :type

    # rubocop:disable Metrics/ParameterLists
    sig do
      params(
        context: Module,
        type: Type,
        variance: Symbol,
        fixed: T.untyped,
        lower: T.untyped,
        upper: T.untyped,
        bounds_proc: T.nilable(T.proc.returns(T::Hash[Symbol, T.untyped])),
      ).void
    end
    def initialize(context, type, variance, fixed, lower, upper, bounds_proc)
      @context = context
      @type = type
      @variance = variance
      @bounds_proc = if bounds_proc
        bounds_proc
      else
        build_bounds_proc(fixed, lower, upper)
      end

      super()
    end
    # rubocop:enable Metrics/ParameterLists

    sig { returns(T.nilable(String)) }
    def name
      constant_name = super
      constant_name&.split("::")&.last
    end

    sig { returns(T::Boolean) }
    def fixed?
      bounds.key?(:fixed)
    end

    sig { returns(String) }
    def serialize
      fixed = bounds[:fixed].to_s if fixed?
      lower = bounds[:lower].to_s if bounds.key?(:lower)
      upper = bounds[:upper].to_s if bounds.key?(:upper)

      RBIHelper.serialize_type_variable(
        @type.serialize,
        @variance,
        fixed,
        upper,
        lower,
      )
    end

    sig { returns(Tapioca::TypeVariable) }
    def coerce_to_type_variable
      TypeVariable.new(name, @variance)
    end

    private

    sig do
      params(fixed: T.untyped, lower: T.untyped, upper: T.untyped)
        .returns(T.proc.returns(T::Hash[Symbol, T.untyped]))
    end
    def build_bounds_proc(fixed, lower, upper)
      bounds = {}
      bounds[:fixed] = fixed unless fixed.nil?
      bounds[:lower] = lower unless lower.nil?
      bounds[:upper] = upper unless upper.nil?

      -> { bounds }
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def bounds
      @bounds ||= @bounds_proc.call
    end
  end
end
