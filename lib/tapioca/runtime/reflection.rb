# typed: strict
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Reflection
      extend T::Sig
      extend self

      CLASS_METHOD = T.let(Kernel.instance_method(:class), UnboundMethod)
      CONSTANTS_METHOD = T.let(Module.instance_method(:constants), UnboundMethod)
      NAME_METHOD = T.let(Module.instance_method(:name), UnboundMethod)
      SINGLETON_CLASS_METHOD = T.let(Object.instance_method(:singleton_class), UnboundMethod)
      ANCESTORS_METHOD = T.let(Module.instance_method(:ancestors), UnboundMethod)
      SUPERCLASS_METHOD = T.let(Class.instance_method(:superclass), UnboundMethod)
      OBJECT_ID_METHOD = T.let(BasicObject.instance_method(:__id__), UnboundMethod)
      EQUAL_METHOD = T.let(BasicObject.instance_method(:equal?), UnboundMethod)
      PUBLIC_INSTANCE_METHODS_METHOD = T.let(Module.instance_method(:public_instance_methods), UnboundMethod)
      PROTECTED_INSTANCE_METHODS_METHOD = T.let(Module.instance_method(:protected_instance_methods), UnboundMethod)
      PRIVATE_INSTANCE_METHODS_METHOD = T.let(Module.instance_method(:private_instance_methods), UnboundMethod)
      METHOD_METHOD = T.let(Kernel.instance_method(:method), UnboundMethod)

      sig do
        params(
          symbol: String,
          inherit: T::Boolean,
          namespace: Module
        ).returns(BasicObject).checked(:never)
      end
      def constantize(symbol, inherit: false, namespace: Object)
        namespace.const_get(symbol, inherit)
      rescue NameError, LoadError, RuntimeError, ArgumentError, TypeError
        nil
      end

      sig { params(object: BasicObject).returns(Class).checked(:never) }
      def class_of(object)
        CLASS_METHOD.bind(object).call
      end

      sig { params(constant: Module).returns(T::Array[Symbol]) }
      def constants_of(constant)
        CONSTANTS_METHOD.bind(constant).call(false)
      end

      sig { params(constant: Module).returns(T.nilable(String)) }
      def name_of(constant)
        name = NAME_METHOD.bind(constant).call
        name&.start_with?("#<") ? nil : name
      end

      sig { params(constant: Module).returns(Class) }
      def singleton_class_of(constant)
        SINGLETON_CLASS_METHOD.bind(constant).call
      end

      sig { params(constant: Module).returns(T::Array[Module]) }
      def ancestors_of(constant)
        ANCESTORS_METHOD.bind(constant).call
      end

      sig { params(constant: Class).returns(T.nilable(Class)) }
      def superclass_of(constant)
        SUPERCLASS_METHOD.bind(constant).call
      end

      sig { params(object: BasicObject).returns(Integer).checked(:never) }
      def object_id_of(object)
        OBJECT_ID_METHOD.bind(object).call
      end

      sig { params(object: BasicObject, other: BasicObject).returns(T::Boolean).checked(:never) }
      def are_equal?(object, other)
        EQUAL_METHOD.bind(object).call(other)
      end

      sig { params(constant: Module).returns(T::Array[Symbol]) }
      def public_instance_methods_of(constant)
        PUBLIC_INSTANCE_METHODS_METHOD.bind(constant).call
      end

      sig { params(constant: Module).returns(T::Array[Symbol]) }
      def protected_instance_methods_of(constant)
        PROTECTED_INSTANCE_METHODS_METHOD.bind(constant).call
      end

      sig { params(constant: Module).returns(T::Array[Symbol]) }
      def private_instance_methods_of(constant)
        PRIVATE_INSTANCE_METHODS_METHOD.bind(constant).call
      end

      sig { params(constant: Module).returns(T::Array[Module]) }
      def inherited_ancestors_of(constant)
        if Class === constant
          ancestors_of(superclass_of(constant) || Object)
        else
          Module.ancestors
        end
      end

      sig { params(constant: Module).returns(T.nilable(String)) }
      def qualified_name_of(constant)
        name = name_of(constant)
        return if name.nil?

        if name.start_with?("::")
          name
        else
          "::#{name}"
        end
      end

      sig { params(method: T.any(UnboundMethod, Method)).returns(T.untyped) }
      def signature_of(method)
        T::Utils.signature_for_method(method)
      rescue LoadError, StandardError
        nil
      end

      sig { params(type: T::Types::Base).returns(String) }
      def name_of_type(type)
        type.to_s.gsub(/\bAttachedClass\b/, "T.attached_class")
      end

      sig { params(constant: Module, method: Symbol).returns(Method) }
      def method_of(constant, method)
        METHOD_METHOD.bind(constant).call(method)
      end

      # Returns an array with all classes that are < than the supplied class.
      #
      #   class C; end
      #   descendants_of(C) # => []
      #
      #   class B < C; end
      #   descendants_of(C) # => [B]
      #
      #   class A < B; end
      #   descendants_of(C) # => [B, A]
      #
      #   class D < C; end
      #   descendants_of(C) # => [B, A, D]
      sig { type_parameters(:U).params(klass: T.type_parameter(:U)).returns(T::Array[T.type_parameter(:U)]) }
      def descendants_of(klass)
        result = ObjectSpace.each_object(klass.singleton_class).reject do |k|
          T.cast(k, Module).singleton_class? || T.unsafe(k) == klass
        end

        T.unsafe(result)
      end
    end
  end
end
