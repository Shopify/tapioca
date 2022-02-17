# typed: true
# frozen_string_literal: true

require "tapioca/sorbet_ext/name_patch"

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

      def type_member(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        # `T::Generic#type_member` just instantiates a `T::Type::TypeMember` instance and returns it.
        # We use that when registering the type member and then later return it from this method.
        Tapioca::TypeVariableModule.new(
          T.cast(self, Module),
          Tapioca::TypeVariableModule::Type::Member,
          variance,
          fixed,
          lower,
          upper
        ).tap do |type_variable|
          Tapioca::Runtime::GenericTypeRegistry.register_type_variable(self, type_variable)
        end
      end

      def type_template(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        # `T::Generic#type_template` just instantiates a `T::Type::TypeTemplate` instance and returns it.
        # We use that when registering the type template and then later return it from this method.
        Tapioca::TypeVariableModule.new(
          T.cast(self, Module),
          Tapioca::TypeVariableModule::Type::Template,
          variance,
          fixed,
          lower,
          upper
        ).tap do |type_variable|
          Tapioca::Runtime::GenericTypeRegistry.register_type_variable(self, type_variable)
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
          if T::Generic === @raw_type || Tapioca::TypeVariableModule === @raw_type
            # for types that are generic or are type variables, use the name
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
    module CoercePatch
      def coerce(val)
        if val.is_a?(Tapioca::TypeVariableModule)
          val.coerce_to_type_variable
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
      end
    end

    sig do
      params(context: Module, type: Type, variance: Symbol, fixed: T.untyped, lower: T.untyped, upper: T.untyped).void
    end
    def initialize(context, type, variance, fixed, lower, upper) # rubocop:disable Metrics/ParameterLists
      @context = context
      @type = type
      @variance = variance
      @fixed = fixed
      @lower = lower
      @upper = upper
      super()
    end

    sig { returns(T.nilable(String)) }
    def name
      constant_name = super

      # This is a hack to work around modules under anonymous modules not having
      # names in 2.6 and 2.7: https://bugs.ruby-lang.org/issues/14895
      #
      # This happens when a type variable is declared under `class << self`, for
      # example.
      #
      # The workaround is to give the parent context a name, at which point, our
      # module gets bound to a name under that name, as well.
      unless constant_name
        constant_name = with_bound_name_pre_3_0 { super }
      end

      constant_name&.split("::")&.last
    end

    sig { returns(String) }
    def serialize
      parts = []
      parts << ":#{@variance}" unless @variance == :invariant
      parts << "fixed: #{@fixed}" if @fixed
      parts << "lower: #{@lower}" unless @lower == T.untyped
      parts << "upper: #{@upper}" unless @upper == BasicObject

      parameters = parts.join(", ")

      serialized = @type.serialize.dup
      serialized << "(#{parameters})" unless parameters.empty?
      serialized
    end

    sig { returns(Tapioca::TypeVariable) }
    def coerce_to_type_variable
      TypeVariable.new(name, @variance)
    end

    private

    sig do
      type_parameters(:Result)
        .params(block: T.proc.returns(T.type_parameter(:Result)))
        .returns(T.type_parameter(:Result))
    end
    def with_bound_name_pre_3_0(&block)
      require "securerandom"
      temp_name = "TYPE_VARIABLE_TRACKING_#{SecureRandom.hex}"
      self.class.const_set(temp_name, @context)
      block.call
    ensure
      self.class.send(:remove_const, temp_name) if temp_name
    end
  end
end
