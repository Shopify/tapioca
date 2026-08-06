# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    # @abstract
    #: [ConstantType < Module[top]]
    class Compiler
      include RBIHelper
      include Runtime::Reflection
      extend Runtime::Reflection

      #: ConstantType
      attr_reader :constant

      #: RBI::Tree
      attr_reader :root

      #: Hash[String, untyped]
      attr_reader :options

      @@requested_constants = [] #: Array[Module[top]] # rubocop:disable Style/ClassVars

      class << self
        #: (Module[top] constant) -> bool
        def handles?(constant)
          processable_constants.include?(constant)
        end

        # @abstract
        #: -> Enumerable[Module[top]]
        def gather_constants = raise NotImplementedError, "Abstract method called"

        #: -> Set[Module[top]]
        def processable_constants
          @processable_constants ||= T::Set[T::Module[T.anything]].new.compare_by_identity.merge(gather_constants) #: Set[Module[top]]?
        end

        #: (Array[Module[top]] constants) -> void
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

        #: -> Enumerable[Class[top]]
        def all_classes
          @all_classes ||= all_modules.grep(Class).freeze #: Enumerable[Class[top]]?
        end

        #: -> Enumerable[Module[top]]
        def all_modules
          @all_modules ||= if @@requested_constants.any?
            @@requested_constants.grep(Module)
          else
            ObjectSpace.each_object(Module).to_a
          end.freeze #: Enumerable[Module[top]]?
        end
      end

      #: (
      #|   Tapioca::Dsl::Pipeline pipeline,
      #|   RBI::Tree root,
      #|   ConstantType constant,
      #|   ?Hash[String, untyped] options
      #| ) -> void
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
        rest_type = signature.rest_type
        params << rest_type.to_s if rest_type

        # keyrest parameter type
        keyrest_type = signature.keyrest_type
        params << keyrest_type.to_s if keyrest_type

        # special case `.void` in a proc
        unless signature.block_name.nil?
          params << signature.block_type.to_s.gsub("returns(<VOID>)", "void")
        end

        params
      end

      #: (RBI::Scope scope, (Method | UnboundMethod) method_def, ?class_method: bool) -> void
      def create_method_from_def(scope, method_def, class_method: false)
        parameters = compile_method_parameters_to_rbi(method_def)
        return_type = compile_method_return_type_to_rbi(method_def)

        scope.create_method(
          method_def.name.to_s,
          parameters: parameters,
          return_type: return_type,
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
          parameter, = create_method_parameter(type, name&.to_s, index)
          create_typed_param(parameter, T.must(method_types[index]))
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
