# typed: strict
# frozen_string_literal: true

module Tapioca
  # This class is responsible for storing and looking up information related to generic types.
  #
  # The class stores 2 different kinds of data, in two separate lookup tables:
  #   1. a lookup of generic type instances by name: `@generic_instances`
  #   2. a lookup of type variable serializer by constant and type variable
  #      instance: `@type_variables`
  #
  # By storing the above data, we can cheaply query each constant against this registry
  # to see if it declares any generic type variables. This becomes a simple lookup in the
  # `@type_variables` hash table with the given constant.
  #
  # If there is no entry, then we can cheaply know that we can skip generic type
  # information generation for this type.
  #
  # On the other hand, if we get a result, then the result will be a hash of type
  # variable to type variable serializers. This allows us to associate type variables
  # to the constant names that represent them, easily.
  module GenericTypeRegistry
    @generic_instances = T.let(
      {},
      T::Hash[String, Module]
    )

    @type_variables = T.let(
      {},
      T::Hash[Integer, T::Hash[Integer, String]]
    )

    class << self
      extend T::Sig

      # This method is responsible for building the name of the instantiated concrete type
      # and cloning the given constant so that we can return a type that is the same
      # as the current type but is a different instance and has a different name method.
      #
      # We cache those cloned instances by their name in `@generic_instances`, so that
      # we don't keep instantiating a new type every single time it is referenced.
      # For example, `[Foo[Integer], Foo[Integer], Foo[Integer], Foo[String]]` will only
      # result in 2 clones (1 for `Foo[Integer]` and another for `Foo[String]`) and
      # 2 hash lookups (for the other two `Foo[Integer]`s).
      #
      # This method returns the created or cached clone of the constant.
      sig { params(constant: T.untyped, types: T.untyped).returns(Module) }
      def register_type(constant, types)
        # Build the name of the instantiated generic type,
        # something like `"Foo[X, Y, Z]"`
        type_list = types.map { |type| T::Utils.coerce(type).name }.join(", ")
        name = "#{name_of(constant)}[#{type_list}]"

        # Create a generic type with an overridden `name`
        # method that returns the name we constructed above.
        #
        # Also, we try to memoize the generic type based on the name, so that
        # we don't have to keep recreating them all the time.
        @generic_instances[name] ||= create_generic_type(constant, name)
      end

      sig do
        params(
          constant: T.untyped,
          type_member: T::Types::TypeVariable,
          fixed: T.untyped,
          lower: T.untyped,
          upper: T.untyped
        ).void
      end
      def register_type_member(constant, type_member, fixed, lower, upper)
        register_type_variable(constant, :type_member, type_member, fixed, lower, upper)
      end

      sig do
        params(
          constant: T.untyped,
          type_template: T::Types::TypeVariable,
          fixed: T.untyped,
          lower: T.untyped,
          upper: T.untyped
        ).void
      end
      def register_type_template(constant, type_template, fixed, lower, upper)
        register_type_variable(constant, :type_template, type_template, fixed, lower, upper)
      end

      sig { params(constant: Module).returns(T.nilable(T::Hash[Integer, String])) }
      def lookup_type_variables(constant)
        @type_variables[object_id_of(constant)]
      end

      private

      sig { params(constant: Module, name: String).returns(Module) }
      def create_generic_type(constant, name)
        generic_type = case constant
        when Class
          # For classes, we want to create a subclass, so that an instance of
          # the generic class `Foo[Bar]` is still a `Foo`. That is:
          # `Foo[Bar].new.is_a?(Foo)` should be true, which isn't the case
          # if we just clone the class. But subclassing works just fine.
          create_safe_subclass(constant)
        else
          # This can only be a module and it is fine to just clone modules
          # since they can't have instances and will not have `is_a?` relationships.
          # Moreover, we never `include`/`extend` any generic modules into the
          # ancestor tree, so this doesn't become a problem with checking the
          # instance of a class being `is_a?` of a module type.
          constant.clone
        end

        # Let's set the `name` method to return the proper generic name
        generic_type.define_singleton_method(:name) { name }

        # Return the generic type we created
        generic_type
      end

      # This method is called from intercepted calls to `type_member` and `type_template`.
      # We get passed all the arguments to those methods, as well as the `T::Types::TypeVariable`
      # instance generated by the Sorbet defined `type_member`/`type_template` call on `T::Generic`.
      #
      # This method creates a `String` with that data and stores it in the
      # `@type_variables` lookup table, keyed by the `constant` and `type_variable`.
      #
      # Finally, the original `type_variable` is returned from this method, so that the caller
      # can return it from the original methods as well.
      sig do
        params(
          constant: T.untyped,
          type_variable_type: T.enum([:type_member, :type_template]),
          type_variable: T::Types::TypeVariable,
          fixed: T.untyped,
          lower: T.untyped,
          upper: T.untyped
        ).void
      end
      # rubocop:disable Metrics/ParameterLists
      def register_type_variable(constant, type_variable_type, type_variable, fixed, lower, upper)
        # rubocop:enable Metrics/ParameterLists
        type_variables = lookup_or_initialize_type_variables(constant)

        type_variables[object_id_of(type_variable)] = serialize_type_variable(
          type_variable_type,
          type_variable.variance,
          fixed,
          lower,
          upper
        )
      end

      sig { params(constant: Class).returns(Class) }
      def create_safe_subclass(constant)
        # Lookup the "inherited" class method
        inherited_method = constant.method(:inherited)
        # and the module that defines it
        owner = inherited_method.owner

        # If no one has overriden the inherited method yet, just subclass
        return Class.new(constant) if Class == owner

        begin
          # Otherwise, some inherited method could be preventing us
          # from creating subclasses, so let's override it and rescue
          owner.send(:define_method, :inherited) do |s|
            begin
              inherited_method.call(s)
            rescue
              # Ignoring errors
            end
          end

          # return a subclass
          Class.new(constant)
        ensure
          # Reinstate the original inherited method back.
          owner.send(:define_method, :inherited, inherited_method)
        end
      end

      sig { params(constant: Module).returns(T::Hash[Integer, String]) }
      def lookup_or_initialize_type_variables(constant)
        @type_variables[object_id_of(constant)] ||= {}
      end

      sig do
        params(
          type_variable_type: Symbol,
          variance: Symbol,
          fixed: T.untyped,
          lower: T.untyped,
          upper: T.untyped
        ).returns(String)
      end
      def serialize_type_variable(type_variable_type, variance, fixed, lower, upper)
        parts = []
        parts << ":#{variance}" unless variance == :invariant
        parts << "fixed: #{fixed}" if fixed
        parts << "lower: #{lower}" unless lower == T.untyped
        parts << "upper: #{upper}" unless upper == BasicObject

        parameters = parts.join(", ")

        serialized = T.let(type_variable_type.to_s, String)
        serialized += "(#{parameters})" unless parameters.empty?

        serialized
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
