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
        Tapioca::GenericTypeRegistry.register_type(constant, types)
      end

      def type_member(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        # `T::Generic#type_member` just instantiates a `T::Type::TypeMember` instance and returns it.
        # We use that when registering the type member and then later return it from this method.
        Tapioca::TypeVariable.new(
          Tapioca::TypeVariable::Type::Member,
          variance,
          fixed,
          lower,
          upper
        ).tap do |type_variable|
          Tapioca::GenericTypeRegistry.register_type_variable(self, type_variable)
        end
      end

      def type_template(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        # `T::Generic#type_template` just instantiates a `T::Type::TypeTemplate` instance and returns it.
        # We use that when registering the type template and then later return it from this method.
        Tapioca::TypeVariable.new(
          Tapioca::TypeVariable::Type::Template,
          variance,
          fixed,
          lower,
          upper
        ).tap do |type_variable|
          Tapioca::GenericTypeRegistry.register_type_variable(self, type_variable)
        end
      end
    end

    prepend TypeStoragePatch
  end

  module Types
    class Simple
      module GenericPatch
        def valid?(obj)
          # Since `Tapioca::TypeVariable` is a `Module` now, it will be wrapped by a
          # `Simple` type. We want to always make type variable types valid, so we
          # need to explicitly check that `raw_type` is a `Tapioca::TypeVariable`
          # and return `true`
          if defined?(Tapioca::TypeVariable) && Tapioca::TypeVariable === @raw_type
            return true
          end

          obj.is_a?(@raw_type)
        end

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
  # This is subclassing from `Module` so that instances of this type will be modules.
  # The reason why we want that is because that means those instances will automatically
  # get bound to the constant names they are assigned to by Ruby. As a result, we don't
  # need to do any matching of constants to type variables to bind their names, Ruby will
  # do that automatically for us and we get the `name` method for free from `Module`.
  class TypeVariable < Module
    extend T::Sig

    class Type < T::Enum
      enums do
        Member = new("type_member")
        Template = new("type_template")
      end
    end

    sig { params(type: Type, variance: Symbol, fixed: T.untyped, lower: T.untyped, upper: T.untyped).void }
    def initialize(type, variance, fixed, lower, upper)
      @type = type
      @variance = variance
      @fixed = fixed
      @lower = lower
      @upper = upper
      super()
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
  end
end
