# typed: strict
# frozen_string_literal: true

require "tapioca/runtime/source_location"

# On Ruby 3.2 or newer, Class defines an attached_object method that returns the
# attached class of a singleton class without iterating ObjectSpace. On older
# versions of Ruby, we fall back to iterating ObjectSpace.
if Class.method_defined?(:attached_object)
  require "tapioca/runtime/attached_class_of_32"
else
  require "tapioca/runtime/attached_class_of_legacy"
end

module Tapioca
  module Runtime
    module Reflection
      include AttachedClassOf

      extend T::Sig
      extend self

      CLASS_METHOD = Kernel.instance_method(:class) #: UnboundMethod
      CONSTANTS_METHOD = Module.instance_method(:constants) #: UnboundMethod
      NAME_METHOD = Module.instance_method(:name) #: UnboundMethod
      SINGLETON_CLASS_METHOD = Object.instance_method(:singleton_class) #: UnboundMethod
      ANCESTORS_METHOD = Module.instance_method(:ancestors) #: UnboundMethod
      SUPERCLASS_METHOD = Class.instance_method(:superclass) #: UnboundMethod
      OBJECT_ID_METHOD = BasicObject.instance_method(:__id__) #: UnboundMethod
      EQUAL_METHOD = BasicObject.instance_method(:equal?) #: UnboundMethod
      PUBLIC_INSTANCE_METHODS_METHOD = Module.instance_method(:public_instance_methods) #: UnboundMethod
      PROTECTED_INSTANCE_METHODS_METHOD = Module.instance_method(:protected_instance_methods) #: UnboundMethod
      PRIVATE_INSTANCE_METHODS_METHOD = Module.instance_method(:private_instance_methods) #: UnboundMethod
      METHOD_METHOD = Kernel.instance_method(:method) #: UnboundMethod
      UNDEFINED_CONSTANT = Module.new.freeze #: Module

      REQUIRED_FROM_LABELS = ["<top (required)>", "<main>", "<compiled>"].freeze #: Array[String]

      # @without_runtime
      #: (BasicObject constant) -> bool
      def constant_defined?(constant)
        !UNDEFINED_CONSTANT.eql?(constant)
      end

      # @without_runtime
      #: (String symbol, ?inherit: bool, ?namespace: Module) -> BasicObject
      def constantize(symbol, inherit: false, namespace: Object)
        namespace.const_get(symbol, inherit)
      rescue NameError, LoadError, RuntimeError, ArgumentError, TypeError
        UNDEFINED_CONSTANT
      end

      #: (BasicObject object) -> Class[top]
      def class_of(object)
        CLASS_METHOD.bind_call(object)
      end

      #: (Module constant) -> Array[Symbol]
      def constants_of(constant)
        CONSTANTS_METHOD.bind_call(constant, false)
      end

      #: (Module constant) -> String?
      def name_of(constant)
        name = NAME_METHOD.bind_call(constant)
        name&.start_with?("#<") ? nil : name
      end

      #: (Module constant) -> Class[top]
      def singleton_class_of(constant)
        SINGLETON_CLASS_METHOD.bind_call(constant)
      end

      #: (Module constant) -> Array[Module]
      def ancestors_of(constant)
        ANCESTORS_METHOD.bind_call(constant)
      end

      #: (Class[top] constant) -> Class[top]?
      def superclass_of(constant)
        SUPERCLASS_METHOD.bind_call(constant)
      end

      #: (BasicObject object) -> Integer
      def object_id_of(object)
        OBJECT_ID_METHOD.bind_call(object)
      end

      #: (BasicObject object, BasicObject other) -> bool
      def are_equal?(object, other)
        EQUAL_METHOD.bind_call(object, other)
      end

      #: (Module constant) -> Array[Symbol]
      def public_instance_methods_of(constant)
        PUBLIC_INSTANCE_METHODS_METHOD.bind_call(constant)
      end

      #: (Module constant) -> Array[Symbol]
      def protected_instance_methods_of(constant)
        PROTECTED_INSTANCE_METHODS_METHOD.bind_call(constant)
      end

      #: (Module constant) -> Array[Symbol]
      def private_instance_methods_of(constant)
        PRIVATE_INSTANCE_METHODS_METHOD.bind_call(constant)
      end

      #: (Module constant) -> Array[Module]
      def inherited_ancestors_of(constant)
        if Class === constant
          ancestors_of(superclass_of(constant) || Object)
        else
          Module.new.ancestors
        end
      end

      #: (Module constant) -> String?
      def qualified_name_of(constant)
        name = name_of(constant)
        return if name.nil?

        if name.start_with?("::")
          name
        else
          "::#{name}"
        end
      end

      SignatureBlockError = Class.new(Tapioca::Error)

      #: ((UnboundMethod | Method) method) -> untyped
      def signature_of!(method)
        T::Utils.signature_for_method(method)
      rescue LoadError, StandardError
        Kernel.raise SignatureBlockError
      end

      #: ((UnboundMethod | Method) method) -> untyped
      def signature_of(method)
        signature_of!(method)
      rescue SignatureBlockError
        nil
      end

      #: (T::Types::Base type) -> String
      def name_of_type(type)
        type.to_s
      end

      #: (Module constant, Symbol method) -> Method
      def method_of(constant, method)
        METHOD_METHOD.bind_call(constant, method)
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
      #: [U] ((Class[top] & U) klass) -> Array[U]
      def descendants_of(klass)
        result = ObjectSpace.each_object(klass.singleton_class).reject do |k|
          k.singleton_class? || k == klass
        end

        T.unsafe(result)
      end

      #: ((String | Symbol) constant_name) -> SourceLocation?
      def const_source_location(constant_name)
        return unless Object.respond_to?(:const_source_location)

        file, line = Object.const_source_location(constant_name)

        SourceLocation.from_loc([file, line]) if file && line
      end

      # Examines the call stack to identify the closest location where a "require" is performed
      # by searching for the label "<top (required)>" or "block in <class:...>" in the
      # case of an ActiveSupport.on_load hook. If none is found, it returns the location
      # labeled "<main>", which is the original call site.
      #: (Array[Thread::Backtrace::Location]? locations) -> SourceLocation?
      def resolve_loc(locations)
        return unless locations

        # Find the location of the closest file load, which should give us the location of the file that
        # triggered the definition.
        resolved_loc = locations.find do |loc|
          label = loc.label
          next unless label

          REQUIRED_FROM_LABELS.include?(label) || label.start_with?("block in <class:")
        end
        return unless resolved_loc

        resolved_loc_path = resolved_loc.absolute_path || resolved_loc.path

        # Find the location of the last frame in this file to get the most accurate line number.
        resolved_loc = locations.find { |loc| loc.absolute_path == resolved_loc_path }
        return unless resolved_loc

        # If the last operation was a `require`, and we have no more frames,
        # we are probably dealing with a C-method.
        return if locations.first&.label == "require"

        file = resolved_loc.absolute_path || resolved_loc.path || ""

        SourceLocation.from_loc([file, resolved_loc.lineno])
      end

      #: (Module constant) -> Set[String]
      def file_candidates_for(constant)
        relevant_methods_for(constant).filter_map do |method|
          method.source_location&.first
        end.to_set
      end

      #: (Module constant) -> untyped
      def abstract_type_of(constant)
        T::Private::Abstract::Data.get(constant, :abstract_type) ||
          T::Private::Abstract::Data.get(singleton_class_of(constant), :abstract_type)
      end

      #: (Module constant) -> bool
      def final_module?(constant)
        T::Private::Final.final_module?(constant)
      end

      #: (Module constant) -> bool
      def sealed_module?(constant)
        T::Private::Sealed.sealed_module?(constant)
      end

      private

      #: (Module constant) -> Array[UnboundMethod]
      def relevant_methods_for(constant)
        methods = methods_for(constant).select(&:source_location)
          .reject { |x| method_defined_by_forwardable_module?(x) }

        return methods unless methods.empty?

        constants_of(constant).flat_map do |const_name|
          if (mod = child_module_for_parent_with_name(constant, const_name.to_s))
            relevant_methods_for(mod)
          else
            []
          end
        end
      end

      #: (Module constant) -> Array[UnboundMethod]
      def methods_for(constant)
        modules = [constant, singleton_class_of(constant)]
        method_list_methods = [
          PUBLIC_INSTANCE_METHODS_METHOD,
          PROTECTED_INSTANCE_METHODS_METHOD,
          PRIVATE_INSTANCE_METHODS_METHOD,
        ]

        modules.product(method_list_methods).flat_map do |mod, method_list_method|
          method_list_method.bind_call(mod, false).map { |name| mod.instance_method(name) }
        end
      end

      #: (Module parent, String name) -> Module?
      def child_module_for_parent_with_name(parent, name)
        return if parent.autoload?(name)

        child = constantize(name, inherit: true, namespace: parent)
        return unless Module === child
        return unless name_of(child) == "#{name_of(parent)}::#{name}"

        child
      end

      #: (UnboundMethod method) -> bool
      def method_defined_by_forwardable_module?(method)
        method.source_location&.first == Object.const_source_location(:Forwardable)&.first
      end

      #: (String name) -> bool
      def has_aliased_namespace?(name)
        name_parts = name.split("::")
        name_parts.pop # drop the constant name, leaving just the namespace

        name_parts.each_with_object([]) do |name_part, namespaces|
          namespaces << "#{namespaces.last}::#{name_part}".delete_prefix("::")
        end.any? do |namespace|
          constant = constantize(namespace)
          next unless Module === constant

          # If the constant name doesn't match the namespace,
          # the namespace must contain an alias
          name_of(constant) != namespace
        end
      end
    end
  end
end
