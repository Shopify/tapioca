# typed: strict
# frozen_string_literal: true

module Tapioca
  module Dsl
    class Compiler
      extend T::Sig
      extend T::Helpers
      extend T::Generic

      include RBIHelper
      include Runtime::Reflection
      extend Runtime::Reflection

      ConstantType = type_member { { upper: Module } }

      abstract!

      sig { returns(ConstantType) }
      attr_reader :constant

      sig { returns(RBI::Tree) }
      attr_reader :root

      class << self
        extend T::Sig

        sig { params(constant: Module).returns(T::Boolean) }
        def handles?(constant)
          processable_constants.include?(constant)
        end

        sig { abstract.returns(T::Enumerable[Module]) }
        def gather_constants; end

        sig { returns(T::Set[Module]) }
        def processable_constants
          @processable_constants ||= T.let(
            T::Set[Module].new(gather_constants).compare_by_identity,
            T.nilable(T::Set[Module]),
          )
        end

        sig { void }
        def register_interceptors
          interceptors.each do |method_name, interceptor|
            constant_name, method_name, singleton_class = if method_name.include?("#")
              [*method_name.split("#", 2), false]
            else
              [*method_name.split(".", 2), true]
            end

            constant = T.cast(Tapioca::Runtime::Reflection.constantize(T.must(constant_name)), Module)
            constant = constant.singleton_class if singleton_class

            constant.prepend(Module.new do
              define_method(T.must(method_name)) do |*args, **kwargs, &blk|
                interceptor.call(self, *args, **kwargs, &blk)
                super(*args, **kwargs, &blk)
              end
            end)
          end
        end

        private

        sig { returns(T::Hash[Module, T::Hash[Symbol, T.untyped]]) }
        def extension_info
          @extension_info_lookup ||= T.let({}.compare_by_identity,
            T.nilable(T::Hash[Module, T::Hash[Symbol, T.untyped]]))
        end

        sig { returns(T::Array[[String, Proc]]) }
        def interceptors
          @interceptors ||= T.let([], T.nilable(T::Array[[String, T.proc.params(args: T.untyped).void]]))
        end

        def store_extension_info(constant, extension_name, info)
          extension_info[constant] ||= {}
          extension_info[constant][extension_name] = info
        end

        def fetch_extension_info(constant, extension_name, &blk)
          extension_info.dig(constant, extension_name).then do |info|
            info = store_extension_info(constant, extension_name, blk.call) if blk && info.nil?
            info
          end
        end

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

        sig { params(method_name: String, blk: T.untyped).void }
        def intercept_method(method_name, &blk)
          interceptors << [method_name, blk]
        end
      end

      sig { params(pipeline: Tapioca::Dsl::Pipeline, root: RBI::Tree, constant: ConstantType).void }
      def initialize(pipeline, root, constant)
        @pipeline = pipeline
        @root = root
        @constant = constant
        @errors = T.let([], T::Array[String])
      end

      sig { params(compiler_name: String).returns(T::Boolean) }
      def compiler_enabled?(compiler_name)
        @pipeline.compiler_enabled?(compiler_name)
      end

      sig { abstract.void }
      def decorate; end

      # NOTE: This should eventually accept an `Error` object or `Exception` rather than simply a `String`.
      sig { params(error: String).void }
      def add_error(error)
        @pipeline.add_error(error)
      end

      private

      def fetch_extension_info(extension_name)
        self.class.send(:fetch_extension_info, constant, extension_name)
      end

      # Get the types of each parameter from a method signature
      sig do
        params(
          method_def: T.any(Method, UnboundMethod),
          signature: T.untyped, # as `T::Private::Methods::Signature` is private
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

        # keyrest parameter type
        params << signature.keyrest_type.to_s if signature.has_keyrest

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
          class_method: class_method,
        )
      end

      sig { params(method_def: T.any(Method, UnboundMethod)).returns(T::Array[RBI::TypedParam]) }
      def compile_method_parameters_to_rbi(method_def)
        signature = signature_of(method_def)
        method_def = signature.nil? ? method_def : signature.method
        method_types = parameters_types_from_signature(method_def, signature)

        parameters = T.let(method_def.parameters, T::Array[[Symbol, T.nilable(Symbol)]])

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

      sig { params(method_def: T.any(Method, UnboundMethod)).returns(String) }
      def compile_method_return_type_to_rbi(method_def)
        signature = signature_of(method_def)
        return_type = signature.nil? ? "T.untyped" : name_of_type(signature.return_type)
        sanitize_signature_types(return_type)
      end
    end
  end
end
