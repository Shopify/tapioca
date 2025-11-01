# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class Methods < Base
        include RBIHelper
        include Runtime::Reflection

        private

        # @override
        #: (ScopeNodeAdded event) -> void
        def on_scope(event)
          symbol = event.symbol
          constant = event.constant
          node = event.node

          compile_method(node, symbol, constant, initialize_method_for(constant))
          compile_directly_owned_methods(node, symbol, constant)
          compile_directly_owned_methods(node, symbol, singleton_class_of(constant), attached_class: constant)
        end

        #: (RBI::Tree tree, String module_name, Module mod, ?Array[Symbol] for_visibility, ?attached_class: Module?) -> void
        def compile_directly_owned_methods(
          tree,
          module_name,
          mod,
          for_visibility = [:public, :protected, :private],
          attached_class: nil
        )
          method_names_by_visibility(mod)
            .delete_if { |visibility, _method_list| !for_visibility.include?(visibility) }
            .each do |visibility, method_list|
              method_list.sort!.map do |name|
                next if name == :initialize
                next if method_new_in_abstract_class?(attached_class, name)

                vis = case visibility
                when :protected
                  RBI::Protected.new
                when :private
                  RBI::Private.new
                else
                  RBI::Public.new
                end
                compile_method(tree, module_name, mod, mod.instance_method(name), vis)
              end
            end
        end

        #: (RBI::Tree tree, String symbol_name, Module constant, UnboundMethod? method, ?RBI::Visibility visibility) -> void
        def compile_method(tree, symbol_name, constant, method, visibility = RBI::Public.new)
          return unless method
          return unless method_owned_by_constant?(method, constant)

          begin
            signature = signature_of!(method)
            method = signature.method if signature #: UnboundMethod

            case @pipeline.method_definition_in_gem(method.name, constant)
            when Pipeline::MethodUnknown
              # This means that this is a C-method. Thus, we want to
              # skip it only if the constant is an ignored one, since
              # that probably means that we've hit a C-method for a
              # core type.
              return if @pipeline.symbol_in_payload?(symbol_name)
            when Pipeline::MethodNotInGem
              # Do not process this method, if it is not defined by the current gem
              return
            end
          rescue SignatureBlockError => error
            @pipeline.error_handler.call(<<~MSG)
              Unable to compile signature for method: #{method.owner}##{method.name}
                Exception raised when loading signature: #{error.cause.inspect}
            MSG

            signature = nil
          end

          method_name = method.name.to_s
          return unless valid_method_name?(method_name)
          return if struct_method?(constant, method_name)
          return if method_name.start_with?("__t_props_generated_")

          parameters = method.parameters #: Array[[Symbol, Symbol?]]

          sanitized_parameters = parameters.each_with_index.map do |(type, name), index|
            fallback_arg_name = "_arg#{index}"

            name = if name
              name.to_s
            else
              # For attr_writer methods, Sorbet signatures have the name
              # of the method (without the trailing = sign) as the name of
              # the only parameter. So, if the parameter does not have a name
              # then the replacement name should be the name of the method
              # (minus trailing =) if and only if there is a signature for the
              # method and the parameter is required and there is a single
              # parameter and the signature also defines a single parameter and
              # the name of the method ends with a = character.
              writer_method_with_sig =
                signature && type == :req &&
                parameters.size == 1 &&
                signature.arg_types.size == 1 &&
                method_name[-1] == "="

              if writer_method_with_sig
                method_name.delete_suffix("=")
              else
                fallback_arg_name
              end
            end

            # Sanitize param names
            name = fallback_arg_name unless valid_parameter_name?(name)

            [type, name]
          end

          rbi_method = RBI::Method.new(
            method_name,
            is_singleton: constant.singleton_class?,
            visibility: visibility,
          )

          sanitized_parameters.each do |type, name|
            case type
            when :req
              rbi_method << RBI::ReqParam.new(name)
            when :opt
              rbi_method << RBI::OptParam.new(name, "T.unsafe(nil)")
            when :rest
              rbi_method << RBI::RestParam.new(name)
            when :keyreq
              rbi_method << RBI::KwParam.new(name)
            when :key
              rbi_method << RBI::KwOptParam.new(name, "T.unsafe(nil)")
            when :keyrest
              rbi_method << RBI::KwRestParam.new(name)
            when :block
              rbi_method << RBI::BlockParam.new(name)
            end
          end

          @pipeline.push_method(symbol_name, constant, method, rbi_method, signature, sanitized_parameters)
          tree << rbi_method
        end

        # Check whether the method is defined by the constant.
        #
        # In most cases, it works to check that the constant is the method owner. However,
        # in the case that a method is also defined in a module prepended to the constant, it
        # will be owned by the prepended module, not the constant.
        #
        # This method implements a better way of checking whether a constant defines a method.
        # It walks up the ancestor tree via the `super_method` method; if any of the super
        # methods are owned by the constant, it means that the constant declares the method.
        #: (UnboundMethod method, Module constant) -> bool
        def method_owned_by_constant?(method, constant)
          # Widen the type of `method` to be nilable
          method = method #: UnboundMethod?

          while method
            return true if method.owner == constant

            method = method.super_method
          end

          false
        end

        #: (Module mod) -> Hash[Symbol, Array[Symbol]]
        def method_names_by_visibility(mod)
          {
            public: public_instance_methods_of(mod),
            protected: protected_instance_methods_of(mod),
            private: private_instance_methods_of(mod),
          }
        end

        #: (Module constant, String method_name) -> bool
        def struct_method?(constant, method_name)
          return false unless T::Props::ClassMethods === constant

          constant
            .props
            .keys
            .include?(method_name.gsub(/=$/, "").to_sym)
        end

        #: (Module? attached_class, Symbol method_name) -> bool?
        def method_new_in_abstract_class?(attached_class, method_name)
          attached_class &&
            method_name == :new &&
            !!abstract_type_of(attached_class) &&
            Class === attached_class.singleton_class
        end

        #: (Module constant) -> UnboundMethod?
        def initialize_method_for(constant)
          constant.instance_method(:initialize)
        rescue
          nil
        end

        # @override
        #: (NodeAdded event) -> bool
        def ignore?(event)
          event.is_a?(Tapioca::Gem::ForeignScopeNodeAdded)
        end
      end
    end
  end
end
