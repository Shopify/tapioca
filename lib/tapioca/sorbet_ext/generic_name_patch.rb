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
        type_member = Tapioca::TypeMember.new(variance, fixed, lower, upper)
        Tapioca::GenericTypeRegistry.register_type_variable(self, type_member)
        type_member
      end

      def type_template(variance = :invariant, fixed: nil, lower: T.untyped, upper: BasicObject)
        # `T::Generic#type_template` just instantiates a `T::Type::TypeTemplate` instance and returns it.
        # We use that when registering the type template and then later return it from this method.
        type_template = Tapioca::TypeTemplate.new(variance, fixed, lower, upper)
        Tapioca::GenericTypeRegistry.register_type_variable(self, type_template)
        type_template
      end
    end

    prepend TypeStoragePatch
  end

  module Types
    class Simple
      # This module intercepts calls to the `name` method for
      # simple types, so that it can ask the name to the type if
      # the type is generic, since, by this point, we've created
      # a clone of that type with the `name` method returning the
      # appropriate name for that specific concrete type.
      module GenericNamePatch
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

      prepend GenericNamePatch
    end
  end
end

module Tapioca
  class TypeMember < T::Types::TypeMember
    extend T::Sig

    sig { returns(T.nilable(String)) }
    attr_accessor :name

    sig { returns(T.untyped) }
    attr_reader :fixed, :lower, :upper

    sig { params(variance: Symbol, fixed: T.untyped, lower: T.untyped, upper: T.untyped).void }
    def initialize(variance, fixed, lower, upper)
      super(variance)
      @fixed = fixed
      @lower = lower
      @upper = upper
    end

    sig { returns(String) }
    def serialize
      parts = []
      parts << ":#{@variance}" unless @variance == :invariant
      parts << "fixed: #{@fixed}" if @fixed
      parts << "lower: #{@lower}" unless @lower == T.untyped
      parts << "upper: #{@upper}" unless @upper == BasicObject

      parameters = parts.join(", ")

      serialized = +"type_member"
      serialized << "(#{parameters})" unless parameters.empty?
      serialized
    end
  end

  class TypeTemplate < T::Types::TypeTemplate
    extend T::Sig

    sig { returns(T.nilable(String)) }
    attr_accessor :name

    sig { returns(T.untyped) }
    attr_reader :fixed, :lower, :upper

    sig { params(variance: Symbol, fixed: T.untyped, lower: T.untyped, upper: T.untyped).void }
    def initialize(variance, fixed, lower, upper)
      super(variance)
      @fixed = fixed
      @lower = lower
      @upper = upper
    end

    sig { returns(String) }
    def serialize
      parts = []
      parts << ":#{@variance}" unless @variance == :invariant
      parts << "fixed: #{@fixed}" if @fixed
      parts << "lower: #{@lower}" unless @lower == T.untyped
      parts << "upper: #{@upper}" unless @upper == BasicObject

      parameters = parts.join(", ")

      serialized = +"type_template"
      serialized << "(#{parameters})" unless parameters.empty?
      serialized
    end
  end
end
