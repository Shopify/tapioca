# typed: strict
# frozen_string_literal: true

require "tapioca/runtime/source_location"

module Tapioca
  module Runtime
    module Reflection
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
      INSTANCE_METHOD_METHOD = Module.instance_method(:instance_method) #: UnboundMethod
      METHOD_METHOD = Kernel.instance_method(:method) #: UnboundMethod
      METHOD_RECEIVER_METHOD = Method.instance_method(:receiver) #: UnboundMethod
      UNDEFINED_CONSTANT = Module.new.freeze #: Module[top]

      REQUIRED_FROM_LABELS = ["<top (required)>", "<main>", "<compiled>"].freeze #: Array[String]

      # @without_runtime
      #: (BasicObject constant) -> bool
      def constant_defined?(constant)
        !UNDEFINED_CONSTANT.eql?(constant)
      end

      # @without_runtime
      #: (String symbol, ?inherit: bool, ?namespace: Module[top]) -> BasicObject
      def constantize(symbol, inherit: false, namespace: Object)
        namespace.const_get(symbol, inherit)
      rescue NameError, LoadError, RuntimeError, ArgumentError, TypeError
        UNDEFINED_CONSTANT
      end

      #: (BasicObject object) -> Class[top]
      def class_of(object)
        CLASS_METHOD.bind_call(object)
      end

      #: (Module[top] constant) -> Array[Symbol]
      def constants_of(constant)
        CONSTANTS_METHOD.bind_call(constant, false)
      end

      #: (Module[top] constant) -> String?
      def name_of(constant)
        name = NAME_METHOD.bind_call(constant)
        name&.start_with?("#<") ? nil : name
      end

      #: (Module[top] constant) -> Class[top]
      def singleton_class_of(constant)
        SINGLETON_CLASS_METHOD.bind_call(constant)
      end

      #: (Module[top] constant) -> Array[Module[top]]
      def ancestors_of(constant)
        ANCESTORS_METHOD.bind_call(constant)
      end

      #: (Class[top] constant) -> Class[top]?
      def superclass_of(constant)
        SUPERCLASS_METHOD.bind_call(constant)
      end

      #: (Class[top] singleton_class) -> Module[top]?
      def attached_class_of(singleton_class)
        result = singleton_class.attached_object
        Module === result ? result : nil
      end

      #: (BasicObject object) -> Integer
      def object_id_of(object)
        OBJECT_ID_METHOD.bind_call(object)
      end

      #: (BasicObject object, BasicObject other) -> bool
      def are_equal?(object, other)
        EQUAL_METHOD.bind_call(object, other)
      end

      #: (Module[top] constant) -> Array[Symbol]
      def public_instance_methods_of(constant)
        PUBLIC_INSTANCE_METHODS_METHOD.bind_call(constant)
      end

      #: (Module[top] constant) -> Array[Symbol]
      def protected_instance_methods_of(constant)
        PROTECTED_INSTANCE_METHODS_METHOD.bind_call(constant)
      end

      #: (Module[top] constant) -> Array[Symbol]
      def private_instance_methods_of(constant)
        PRIVATE_INSTANCE_METHODS_METHOD.bind_call(constant)
      end

      #: (Module[top] constant) -> Array[Module[top]]
      def inherited_ancestors_of(constant)
        if Class === constant
          ancestors_of(superclass_of(constant) || Object)
        else
          Module.new.ancestors
        end
      end

      #: (Module[top] constant) -> String?
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

      #: ((UnboundMethod | Method) method, lookup_from: untyped) -> untyped
      def signature_of!(method, lookup_from:)
        # We use `T::Utils.signature_for_method` on a method and the portion of its
        # `super_method` chain introduced by `prepend`. This finds signatures hidden
        # by prepended methods without crossing ordinary method implementations. We
        # check the chain a second time to support `prepend` in cases like this:
        #   module Wrapper
        #     def foo = super
        #   end
        #   class Example
        #     sig { void }
        #     def foo; end
        #     prepend Wrapper
        #   end
        # Asking Sorbet for the signature on the original `Example#foo` evaluates its
        # `sig`. Because `Wrapper` was prepended, Ruby now resolves `Example#foo` to
        # `Wrapper#foo`, so Sorbet stores the signature for `Wrapper#foo`. The first
        # pass causes the store; the second pass finds `Example#foo`'s signature on
        # `Wrapper#foo`.
        lookup_scope = lookup_scope_for(method, lookup_from)
        resolved_method = method_from_lookup(method, lookup_from, lookup_scope)
        unless are_equal?(method.owner, resolved_method.owner)
          Kernel.raise ArgumentError, "`method` must be looked up from `lookup_from`"
        end
        candidates = signature_candidates(method, lookup_scope)

        begin
          needs_second_pass = false #: bool
          candidates.each do |current_method|
            needs_second_pass ||= T::Private::Methods.has_sig_block_for_method(current_method)
            current_signature = T::Utils.signature_for_method(current_method)
            return current_signature if current_signature
          end
          return nil unless needs_second_pass

          # Evaluating a `sig` lazily may register it under the prepended wrapper,
          # so resolve the method and inspect the chain again.
          refreshed_method = method_from_lookup(method, lookup_from, lookup_scope)
          signature_candidates(refreshed_method, lookup_scope).each do |current_method|
            current_signature = T::Utils.signature_for_method(current_method)
            return current_signature if current_signature
          end

          nil
        rescue LoadError, StandardError
          Kernel.raise SignatureBlockError
        end
      end

      #: ((UnboundMethod | Method) method, lookup_from: untyped) -> untyped
      def signature_of(method, lookup_from:)
        signature_of!(method, lookup_from: lookup_from)
      rescue SignatureBlockError
        nil
      end

      #: ((UnboundMethod | Method) method, untyped lookup_from) -> Module[top]
      def lookup_scope_for(method, lookup_from)
        if Method === method
          receiver = METHOD_RECEIVER_METHOD.bind_call(method)
          unless are_equal?(receiver, lookup_from)
            Kernel.raise ArgumentError, "`lookup_from` must be the method receiver"
          end

          singleton_class_of(lookup_from)
        elsif Module === lookup_from
          lookup_from
        else
          Kernel.raise ArgumentError, "`lookup_from` must be a module for an unbound method"
        end
      end
      private :lookup_scope_for

      #: (
      #|   (UnboundMethod | Method) method,
      #|   untyped lookup_from,
      #|   Module[top] lookup_scope
      #| ) -> (UnboundMethod | Method)
      def method_from_lookup(method, lookup_from, lookup_scope)
        if Method === method
          METHOD_METHOD.bind_call(lookup_from, method.name)
        else
          INSTANCE_METHOD_METHOD.bind_call(lookup_scope, method.name)
        end
      end
      private :method_from_lookup

      #: ((UnboundMethod | Method) method, Module[top] lookup_scope) -> Array[UnboundMethod | Method]
      def signature_candidates(method, lookup_scope)
        return [method] if are_equal?(method.owner, lookup_scope)

        ancestors = ancestors_of(lookup_scope)
        prepended_positions = prepended_ancestor_positions(ancestors)
        candidates = [] #: Array[UnboundMethod | Method]
        current_method = method #: (UnboundMethod | Method)?
        first_ancestor_index = 0

        while current_method
          ancestor_index = (first_ancestor_index...ancestors.length).find do |index|
            are_equal?(ancestors.fetch(index), current_method.owner)
          end
          unless ancestor_index
            Kernel.raise ArgumentError, "method does not belong to the `lookup_from` ancestor chain"
          end

          candidates << current_method
          break unless prepended_positions.fetch(ancestor_index)

          first_ancestor_index = ancestor_index + 1
          current_method = current_method.super_method
        end

        candidates
      end
      private :signature_candidates

      #: (Array[Module[top]] ancestors) -> Array[bool]
      def prepended_ancestor_positions(ancestors)
        prepended = Array.new(ancestors.length, false) #: Array[bool]

        # Mark prepend positions in the flattened ancestor chain. We track positions
        # instead of module identities because Ruby can include and prepend the same
        # module at different points in one ancestor chain.
        ancestors.each_with_index do |ancestor, ancestor_index|
          prepended_ancestors = ancestors_of(ancestor).take_while do |candidate|
            !are_equal?(candidate, ancestor)
          end
          first_prepend_index = ancestor_index - prepended_ancestors.length
          next if first_prepend_index.negative?
          next unless prepended_ancestors.each_with_index.all? do |candidate, index|
            are_equal?(candidate, ancestors.fetch(first_prepend_index + index))
          end

          first_prepend_index.upto(ancestor_index - 1) do |index|
            prepended[index] = true
          end
        end

        prepended
      end
      private :prepended_ancestor_positions

      #: (T::Types::Base type) -> String
      def name_of_type(type)
        type.to_s
      end

      #: (Module[top] constant, Symbol method) -> Method
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

      #: (Module[top] constant) -> Set[String]
      def file_candidates_for(constant)
        # Grab all source files for (relevant) methods defined on the constant
        candidates = relevant_methods_for(constant).filter_map do |method|
          method.source_location&.first
        end.to_set

        # Add the source file for the constant definition itself, if available.
        source_location_candidate = const_source_location(name_of(constant).to_s)&.file
        candidates.add(source_location_candidate) if source_location_candidate

        candidates
      end

      #: (Module[top] constant) -> untyped
      def abstract_type_of(constant)
        T::Private::Abstract::Data.get(constant, :abstract_type) ||
          T::Private::Abstract::Data.get(singleton_class_of(constant), :abstract_type)
      end

      #: (Module[top] constant) -> bool
      def final_module?(constant)
        T::Private::Final.final_module?(constant)
      end

      #: (Module[top] constant) -> bool
      def sealed_module?(constant)
        T::Private::Sealed.sealed_module?(constant)
      end

      private

      #: (Module[top] constant) -> Array[UnboundMethod]
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

      #: (Module[top] constant) -> Array[UnboundMethod]
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

      #: (Module[top] parent, String name) -> Module[top]?
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
