# typed: strict
# frozen_string_literal: true

module Tapioca
  module GenericTypeRegistry
    class TypeVariableSerializer
      extend T::Sig
      sig do
        params(
          type_variable_type: T.untyped,
          variance: T.untyped,
          fixed: T.untyped,
          lower: T.untyped,
          upper: T.untyped
        ).void
      end
      def initialize(type_variable_type, variance, fixed, lower, upper)
        parts = []
        parts << ":#{variance}" unless variance == :invariant
        parts << "fixed: #{fixed}" if fixed
        parts << "lower: #{lower}" unless lower == T.untyped
        parts << "upper: #{upper}" unless upper == BasicObject

        parameters = parts.join(", ")

        @str = T.let("#{type_variable_type}(#{parameters})", String)
      end

      sig { returns(String) }
      def to_s
        @str
      end
    end

    @generic_instances = T.let(
      {},
      T::Hash[String, Module]
    )

    @type_variables = T.let(
      {},
      T::Hash[Integer, T::Hash[Integer, TypeVariableSerializer]]
    )

    class << self
      extend T::Sig

      sig { params(constant: T.untyped, types: T.untyped).returns(Module) }
      def register_type(constant, types)
        # Build the name of the instantiated generic type,
        # something like `Foo[X, Y, Z]`
        type_list = types.map do |type|
          next type.name if T::Types::Base === type
          name_of(type)
        end.join(", ")
        name = "#{name_of(constant)}[#{type_list}]"

        # Create a clone of the constant with an overridden `name`
        # method that returns the name we constructed above.
        #
        # Also, we try to memoize the clone based on the name, so that
        # we don't have to keep recreating clones all the time.
        @generic_instances[name] ||= constant.clone.tap do |clone|
          clone.define_singleton_method(:name) { name }
        end
      end

      sig do
        params(
          constant: T.untyped,
          type_template: T::Types::TypeVariable,
          fixed: T.untyped,
          lower: T.untyped,
          upper: T.untyped
        ).returns(T::Types::TypeVariable)
      end
      def register_type_template(constant, type_template, fixed, lower, upper)
        register_type_variable(constant, :type_template, type_template, fixed, lower, upper)
      end

      sig do
        params(
          constant: T.untyped,
          type_member: T::Types::TypeVariable,
          fixed: T.untyped,
          lower: T.untyped,
          upper: T.untyped
        ).returns(T::Types::TypeVariable)
      end
      def register_type_member(constant, type_member, fixed, lower, upper)
        register_type_variable(constant, :type_member, type_member, fixed, lower, upper)
      end

      sig { params(constant: Module).returns(T.nilable(T::Hash[Integer, TypeVariableSerializer])) }
      def lookup_type_variables(constant)
        @type_variables[object_id_of(constant)]
      end

      private

      sig do
        params(
          constant: T.untyped,
          type_variable_type: T.enum([:type_member, :type_template]),
          type_variable: T::Types::TypeVariable,
          fixed: T.untyped,
          lower: T.untyped,
          upper: T.untyped
        ).returns(T::Types::TypeVariable)
      end
      # rubocop:disable Metrics/ParameterLists
      def register_type_variable(constant, type_variable_type, type_variable, fixed, lower, upper)
        # rubocop:enable Metrics/ParameterLists
        type_variables = lookup_or_initialize_type_variables(constant)

        type_variables[object_id_of(type_variable)] = TypeVariableSerializer.new(
          type_variable_type,
          type_variable.variance,
          fixed,
          lower,
          upper
        )

        type_variable
      end

      sig { params(constant: Module).returns(T::Hash[Integer, TypeVariableSerializer]) }
      def lookup_or_initialize_type_variables(constant)
        @type_variables[object_id_of(constant)] ||= {}
      end

      sig { params(constant: Module).returns(T.nilable(String)) }
      def name_of(constant)
        Module.instance_method(:name).bind(constant).call
      end

      sig { params(object: BasicObject).returns(Integer) }
      def object_id_of(object)
        Object.instance_method(:object_id).bind(object).call
      end
    end
  end
end
