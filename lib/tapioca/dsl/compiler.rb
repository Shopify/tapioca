# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    # @abstract
    #: [ConstantType < Module]
    class Compiler
      extend T::Sig

      include RBIHelper
      include Runtime::Reflection
      extend Runtime::Reflection

      #: ConstantType
      attr_reader :constant

      #: RBI::Tree
      attr_reader :root

      #: Hash[String, untyped]
      attr_reader :options

      @@requested_constants = [] #: Array[Module] # rubocop:disable Style/ClassVars

      class << self
        extend T::Sig

        #: (Module constant) -> bool
        def handles?(constant)
          processable_constants.include?(constant)
        end

        # @abstract
        #: -> T::Enumerable[Module]
        def gather_constants = raise NotImplementedError, "Abstract method called"

        #: -> Set[Module]
        def processable_constants
          @processable_constants ||= T::Set[Module].new.compare_by_identity.merge(gather_constants) #: Set[Module]?
        end

        #: (Array[Module] constants) -> void
        def requested_constants=(constants)
          @@requested_constants = constants # rubocop:disable Style/ClassVars
        end

        #: -> void
        def reset_state
          @processable_constants = nil
          @all_classes = nil
          @all_modules = nil
        end

        private

        #: [U] ((Class[top] & U) klass) -> Array[U]
        def descendants_of(klass)
          if @@requested_constants.any?
            T.cast(
              @@requested_constants.select do |k|
                k < klass && !k.singleton_class?
              end,
              T::Array[T.type_parameter(:U)],
            )
          else
            super
          end
        end

        #: -> T::Enumerable[Class[top]]
        def all_classes
          @all_classes ||= all_modules.grep(Class).freeze #: T::Enumerable[Class[top]]?
        end

        #: -> T::Enumerable[Module]
        def all_modules
          @all_modules ||= if @@requested_constants.any?
            @@requested_constants.grep(Module)
          else
            ObjectSpace.each_object(Module).to_a
          end.freeze #: T::Enumerable[Module]?
        end
      end

      #: (Tapioca::Dsl::Pipeline pipeline, RBI::Tree root, ConstantType constant, ?Hash[String, untyped] options) -> void
      def initialize(pipeline, root, constant, options = {})
        @pipeline = pipeline
        @root = root
        @constant = constant
        @options = options
        @errors = [] #: Array[String]
      end

      #: (String compiler_name) -> bool
      def compiler_enabled?(compiler_name)
        @pipeline.compiler_enabled?(compiler_name)
      end

      # @abstract
      #: -> void
      def decorate = raise NotImplementedError, "Abstract method called"

      # NOTE: This should eventually accept an `Error` object or `Exception` rather than simply a `String`.
      #: (String error) -> void
      def add_error(error)
        @pipeline.add_error(error)
      end

      private

      # Get the types of each parameter from a method signature
      #: ((Method | UnboundMethod) method_def, untyped signature) -> Array[String]
      def parameters_types_from_signature(method_def, signature)
        params = [] #: Array[String]

        return method_def.parameters.map { "T.untyped" } unless signature

        # parameters types
        signature.arg_types.each { |arg_type| params << arg_type[1].to_s }

        # keyword parameters types
        signature.kwarg_types.each { |_, kwarg_type| params << kwarg_type.to_s }

        # rest parameter type
        params << signature.rest_type.to_s if signature.has_rest

        # keyrest parameter type
        params << signature.keyrest_type.to_s if signature.has_keyrest

        # special case `.void` in a proc
        unless signature.block_name.nil?
          params << signature.block_type.to_s.gsub("returns(<VOID>)", "void")
        end

        params
      end

      #: (RBI::Scope scope, (Method | UnboundMethod) method_def, ?class_method: bool) -> void
      def create_method_from_def(scope, method_def, class_method: false)
        scope.create_method(
          method_def.name.to_s,
          parameters: compile_method_parameters_to_rbi(method_def),
          return_type: compile_method_return_type_to_rbi(method_def),
          class_method: class_method,
        )
      end

      #: ((Method | UnboundMethod) method_def) -> Array[RBI::TypedParam]
      def compile_method_parameters_to_rbi(method_def)
        signature = signature_of(method_def)
        method_def = signature.nil? ? method_def : signature.method
        method_types = parameters_types_from_signature(method_def, signature)

        parameters = method_def.parameters #: Array[[Symbol, Symbol?]]

        parameters.each_with_index.map do |(type, name), index|
          fallback_arg_name = "_arg#{index}"

          name = name ? name.to_s : fallback_arg_name
          name = fallback_arg_name unless valid_parameter_name?(name)
          method_type = T.must(method_types[index])

          case type
          when :req
            create_param(name, type: method_type)
          when :opt
            create_opt_param(name, type: method_type, default: "T.unsafe(nil)")
          when :rest
            create_rest_param(name, type: method_type)
          when :keyreq
            create_kw_param(name, type: method_type)
          when :key
            create_kw_opt_param(name, type: method_type, default: "T.unsafe(nil)")
          when :keyrest
            create_kw_rest_param(name, type: method_type)
          when :block
            create_block_param(name, type: method_type)
          else
            raise "Unknown type `#{type}`."
          end
        end
      end

      #: ((Method | UnboundMethod) method_def) -> String
      def compile_method_return_type_to_rbi(method_def)
        signature = signature_of(method_def)
        return_type = signature.nil? ? "T.untyped" : name_of_type(signature.return_type)
        sanitize_signature_types(return_type)
      end
    end
  end
end
