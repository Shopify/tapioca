# typed: strict
# frozen_string_literal: true

module Tapioca
  module Compilers
    module Dsl
      class Base
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { returns(T::Set[Module]) }
        attr_reader :processable_constants

        sig { void }
        def initialize
          @processable_constants = T.let(Set.new(gather_constants), T::Set[Module])
        end

        sig { params(constant: Module).returns(T::Boolean) }
        def handles?(constant)
          processable_constants.include?(constant)
        end

        sig do
          abstract
            .type_parameters(:T)
            .params(
              root: Parlour::RbiGenerator::Namespace,
              constant: T.type_parameter(:T)
            )
            .void
        end
        def decorate(root, constant); end

        sig { abstract.returns(T::Enumerable[Module]) }
        def gather_constants; end

        private

        SPECIAL_METHOD_NAMES = T.let(
          %w[! ~ +@ ** -@ * / % + - << >> & | ^ < <= => > >= == === != =~ !~ <=> [] []= `],
          T::Array[String]
        )

        sig { params(name: String).returns(T::Boolean) }
        def valid_method_name?(name)
          return true if SPECIAL_METHOD_NAMES.include?(name)
          !!name.match(/^[a-zA-Z_][[:word:]]*[?!=]?$/)
        end

        sig do
          params(
            namespace: Parlour::RbiGenerator::Namespace,
            name: String,
            options: T::Hash[T.untyped, T.untyped]
          ).void
        end
        def create_method(namespace, name, options = {})
          return unless valid_method_name?(name)
          T.unsafe(namespace).create_method(name, options)
        end

        # Create a Parlour method inside `namespace` from its Ruby definition
        sig do
          params(
            namespace: Parlour::RbiGenerator::Namespace,
            method_def: T.any(Method, UnboundMethod)
          ).void
        end
        def create_method_from_def(namespace, method_def)
          create_method(
            namespace,
            method_def.name.to_s,
            parameters: compile_method_parameters_to_parlour(method_def),
            return_type: compile_method_return_type_to_parlour(method_def)
          )
        end

        # Compile a Ruby method parameters into Parlour parameters
        sig do
          params(method_def: T.any(Method, UnboundMethod))
            .returns(T::Array[Parlour::RbiGenerator::Parameter])
        end
        def compile_method_parameters_to_parlour(method_def)
          signature = T::Private::Methods.signature_for_method(method_def)
          method_def = signature.nil? ? method_def : signature.method
          method_types = parameters_types_from_signature(method_def, signature)

          method_def.parameters.each_with_index.map do |(type, name), i|
            name ||= :_
            name = name.to_s.gsub(/&|\*/, '_') # avoid incorrect names from `delegate`
            case type
            when :req
              ::Parlour::RbiGenerator::Parameter.new(name, type: method_types[i])
            when :opt
              ::Parlour::RbiGenerator::Parameter.new(name, type: method_types[i], default: '_')
            when :rest
              ::Parlour::RbiGenerator::Parameter.new("*#{name}", type: method_types[i])
            when :keyreq
              ::Parlour::RbiGenerator::Parameter.new("#{name}:", type: method_types[i])
            when :key
              ::Parlour::RbiGenerator::Parameter.new("#{name}:", type: method_types[i], default: '_')
            when :keyrest
              ::Parlour::RbiGenerator::Parameter.new("**#{name}", type: method_types[i])
            when :block
              ::Parlour::RbiGenerator::Parameter.new("&#{name}", type: method_types[i])
            else
              raise "Unknown type `#{type}`."
            end
          end
        end

        # Compile a Ruby method return type into a Parlour type
        sig do
          params(method_def: T.any(Method, UnboundMethod))
            .returns(String)
        end
        def compile_method_return_type_to_parlour(method_def)
          signature = T::Private::Methods.signature_for_method(method_def)
          return_type = signature.nil? ? 'T.untyped' : signature.return_type.to_s
          # Map <VOID> to `nil` since `nil` means a `void` return for Parlour
          return_type = nil if return_type == "<VOID>"
          # Map <NOT-TYPED> to `T.untyped`
          return_type = "T.untyped" if return_type == "<NOT-TYPED>"
          return_type
        end

        # Get the types of each parameter from a method signature
        sig do
          params(
            method_def: T.any(Method, UnboundMethod),
            signature: T.untyped # as `T::Private::Methods::Signature` is private
          ).returns(T::Array[String])
        end
        def parameters_types_from_signature(method_def, signature)
          params = T.let([], T::Array[String])

          return method_def.parameters.map { 'T.untyped' } unless signature

          # parameters types
          signature.arg_types.each { |arg_type| params << arg_type[1].to_s }

          # keyword parameters types
          signature.kwarg_types.each { |_, kwarg_type| params << kwarg_type.to_s }

          # rest parameter type
          params << signature.rest_type.to_s if signature.has_rest

          # special case `.void` in a proc
          unless signature.block_name.nil?
            params << signature.block_type.to_s.gsub('returns(<VOID>)', 'void')
          end

          params
        end
      end
    end
  end
end
