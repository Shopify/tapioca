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
      def type_member(variance = :invariant, &bounds_proc)
        # `T::Generic#type_member` just instantiates a `T::Type::TypeMember` instance and returns it.
        # We use that when registering the type member and then later return it from this method.
        Tapioca::TypeVariableModule.new(
          T.cast(self, ::Module),
          Tapioca::TypeVariableModule::Type::Member,
          variance,
          bounds_proc,
        ).tap do |type_variable|
          Tapioca::Runtime::GenericTypeRegistry.register_type_variable(self, type_variable)
        end
      end

      def type_template(variance = :invariant, &bounds_proc)
        # `T::Generic#type_template` just instantiates a `T::Type::TypeTemplate` instance and returns it.
        # We use that when registering the type template and then later return it from this method.
        Tapioca::TypeVariableModule.new(
          T.cast(self, ::Module),
          Tapioca::TypeVariableModule::Type::Template,
          variance,
          bounds_proc,
        ).tap do |type_variable|
          Tapioca::Runtime::GenericTypeRegistry.register_type_variable(self, type_variable)
        end
      end

      def has_attached_class!(variance = :invariant, &bounds_proc)
        Tapioca::Runtime::GenericTypeRegistry.register_type_variable(
          self,
          Tapioca::TypeVariableModule.new(
            T.cast(self, ::Module),
            Tapioca::TypeVariableModule::Type::HasAttachedClass,
            variance,
            bounds_proc,
          ),
        )
      end
    end

    class << self
      # Prepend the type instantiation patch directly on the singleton class of what is extending T::Generic. This
      # prevents any other overrides of the `[]` method from being called before our patch, which prevents us from
      # tracking type parameters.
      def extended(constant)
        # Place our patch in front of the singleton class ancestors
        constant.singleton_class.prepend(TypeInstantiationPatch)
        super
      end
    end

    module TypeInstantiationPatch
      def [](*types)
        # Each generic subclass must extend T::Generic and re-define the type parameters. That means calling `super`
        # would need to go through the entire singleton class chain, but we in fact only care about the current constant
        # exactly.
        #
        # Here we save the current constant so that we can skip registering the type parameters multiple times when
        # going through the singleton inheritance chain.
        return super if Thread.current[:__tapioca_instantiating_generic].equal?(self)

        previous = Thread.current[:__tapioca_instantiating_generic]
        Thread.current[:__tapioca_instantiating_generic] = self

        begin
          constant = super
        ensure
          Thread.current[:__tapioca_instantiating_generic] = previous
        end

        begin
          Tapioca::Runtime::GenericTypeRegistry.register_type(constant, types)
        rescue RuntimeError
          # When we register a type, we go through Sorbet's type coercion, which raises runtime error if the types
          # passed to `[]` aren't actually types. Instead of replicating the coercion logic, we just delegate and rescue
          # the error.
          #
          # An example when this might happen is if a class defines `self.[]` as a factory method while also being
          # generic. Consider a `array = Collection[1, 2, 3, 4]`, where the `[]` method is a factory, while at the same
          # time being the syntax for type parameters.
          #
          # For these cases, there is no type to register and we just want to make sure the code continues to work.
          constant
        end
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
    class Type < T::Enum
      enums do
        Member = new("type_member")
        Template = new("type_template")
        HasAttachedClass = new("has_attached_class!")
      end
    end

    DEFAULT_BOUNDS_PROC = -> { {} } #: ^-> Hash[Symbol, untyped]

    #: Type
    attr_reader :type

    #: (Module[top] context, Type type, Symbol variance, (^-> Hash[Symbol, untyped])? bounds_proc) -> void
    def initialize(context, type, variance, bounds_proc)
      @context = context
      @type = type
      @variance = variance
      @bounds_proc = bounds_proc || DEFAULT_BOUNDS_PROC

      super()
    end

    #: -> String?
    def name
      constant_name = super
      constant_name&.split("::")&.last
    end

    #: -> bool
    def fixed?
      bounds.key?(:fixed)
    end

    #: -> String
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

    #: -> Tapioca::TypeVariable
    def coerce_to_type_variable
      TypeVariable.new(name, @variance)
    end

    private

    #: -> Hash[Symbol, untyped]
    def bounds
      @bounds ||= @bounds_proc.call
    end
  end
end
