# typed: strict
# frozen_string_literal: true

require "tapioca/rbi_ext/model"
require "tapioca/compilers/dsl/param_helper"

module Tapioca
  module Compilers
    module Dsl
      COMPILERS_PATH = T.let(File.expand_path("..", __FILE__).to_s, String)

      class Base
        extend T::Sig
        extend T::Helpers

        include Reflection

        abstract!

        sig { returns(T::Set[Module]) }
        attr_reader :processable_constants

        sig { returns(T::Array[String]) }
        attr_reader :errors

        sig { void }
        def initialize
          @processable_constants = T.let(Set.new(gather_constants), T::Set[Module])
          @errors = T.let([], T::Array[String])
        end

        sig { params(constant: Module).returns(T::Boolean) }
        def handles?(constant)
          processable_constants.include?(constant)
        end

        sig do
          abstract
            .type_parameters(:T)
            .params(
              tree: RBI::Tree,
              constant: T.type_parameter(:T)
            )
            .void
        end
        def decorate(tree, constant); end

        sig { abstract.returns(T::Enumerable[Module]) }
        def gather_constants; end

        # NOTE: This should eventually accept an `Error` object or `Exception` rather than simply a `String`.
        sig { params(error: String).void }
        def add_error(error)
          @errors << error
        end

        private

        sig { returns(T::Enumerable[Class]) }
        def all_classes
          @all_classes = T.let(@all_classes, T.nilable(T::Enumerable[Class]))
          @all_classes ||= T.cast(ObjectSpace.each_object(Class), T::Enumerable[Class]).each
        end

        sig { returns(T::Enumerable[Module]) }
        def all_modules
          @all_modules = T.let(@all_modules, T.nilable(T::Enumerable[Module]))
          @all_modules ||= T.cast(ObjectSpace.each_object(Module), T::Enumerable[Module]).each
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

          return method_def.parameters.map { "T.untyped" } unless signature

          # parameters types
          signature.arg_types.each { |arg_type| params << arg_type[1].to_s }

          # keyword parameters types
          signature.kwarg_types.each { |_, kwarg_type| params << kwarg_type.to_s }

          # rest parameter type
          params << signature.rest_type.to_s if signature.has_rest

          # special case `.void` in a proc
          unless signature.block_name.nil?
            params << signature.block_type.to_s.gsub("returns(<VOID>)", "void")
          end

          params
        end

        sig { params(scope: RBI::Scope, method_def: T.any(Method, UnboundMethod), class_method: T::Boolean).void }
        def create_method_from_def(scope, method_def, class_method: false)
          scope.create_method(
            method_def.name.to_s,
            parameters: compile_method_parameters_to_rbi(method_def),
            return_type: compile_method_return_type_to_rbi(method_def),
            class_method: class_method
          )
        end

        include ParamHelper

        sig { params(method_def: T.any(Method, UnboundMethod)).returns(T::Array[RBI::TypedParam]) }
        def compile_method_parameters_to_rbi(method_def)
          signature = T::Private::Methods.signature_for_method(method_def)
          method_def = signature.nil? ? method_def : signature.method
          method_types = parameters_types_from_signature(method_def, signature)

          method_def.parameters.each_with_index.map do |(type, name), index|
            fallback_arg_name = "_arg#{index}"

            name ||= fallback_arg_name
            name = name.to_s.gsub(/&|\*/, fallback_arg_name) # avoid incorrect names from `delegate`
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

        sig { params(method_def: T.any(Method, UnboundMethod)).returns(String) }
        def compile_method_return_type_to_rbi(method_def)
          signature = T::Private::Methods.signature_for_method(method_def)
          return_type = signature.nil? ? "T.untyped" : name_of_type(signature.return_type)
          return_type = "void" if return_type == "<VOID>"
          # Map <NOT-TYPED> to `T.untyped`
          return_type = "T.untyped" if return_type == "<NOT-TYPED>"
          return_type
        end
      end
    end
  end
end
