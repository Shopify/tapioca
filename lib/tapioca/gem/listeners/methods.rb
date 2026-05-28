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

          compile_method(node, symbol, constant, initialize_method_for(constant), scope_constant: constant)
          compile_directly_owned_methods(node, symbol, constant)
          compile_directly_owned_methods(node, symbol, singleton_class_of(constant), attached_class: constant)
        end

        #: (
        #|   RBI::Tree tree,
        #|   String module_name,
        #|   Module[top] mod,
        #|   ?Array[Symbol] for_visibility,
        #|   ?attached_class: Module[top]?
        #| ) -> void
        def compile_directly_owned_methods(
          tree,
          module_name,
          mod,
          for_visibility = [:public, :protected, :private],
          attached_class: nil
        )
          # For singleton methods (when `attached_class` is set), `mod` is the
          # singleton class; the lexical scope used to find RBS comments must be
          # the attached class.
          scope_constant = attached_class || mod

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
                compile_method(tree, module_name, mod, mod.instance_method(name), vis, scope_constant: scope_constant)
              end
            end
        end

        #: (
        #|   RBI::Tree tree,
        #|   String symbol_name,
        #|   Module[top] constant,
        #|   UnboundMethod? method,
        #|   ?RBI::Visibility visibility,
        #|   ?scope_constant: Module[top]?
        #| ) -> void
        def compile_method(tree, symbol_name, constant, method, visibility = RBI::Public.new, scope_constant: nil)
          return unless method
          return unless method_owned_by_constant?(method, constant)

          begin
            signature = signature_of!(method)
            if signature
              sig_method = signature.method
              method = sig_method.is_a?(Method) ? sig_method.unbind : sig_method
            end

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

          # When no Sorbet runtime signature is registered, look for inline RBS
          # comments in source. This is the path Tapioca uses to surface
          # `#: -> ...` style signatures without needing the require-hook
          # rewriter.
          rbs_lookup = nil #: Pipeline::RBSMethodLookup?
          if signature.nil? && scope_constant
            rbs_lookup = @pipeline.rbs_comments_for_method(
              scope_constant,
              method.name,
              is_singleton: constant.singleton_class?,
              source_location: method.source_location,
            )

            # For `attr_accessor`, Sorbet only attaches a runtime sig to the
            # reader; the writer is left bare. We match that convention here so
            # the generated RBI stays in line with the existing
            # `sig + attr_accessor` output.
            if rbs_lookup && rbs_lookup.kind == :attr_accessor && method.name.to_s.end_with?("=")
              rbs_lookup = nil
            end
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
              # For attr_writer methods, Sorbet signatures (and RBS comments)
              # name the only parameter using the attribute name (i.e. the
              # method name without the trailing `=`). When we have any kind
              # of signature available — Sorbet runtime or RBS — and we're
              # dealing with a single-required-arg writer method, fall back to
              # that convention instead of an anonymous `_arg0`.
              writer_method_with_sig =
                (signature || rbs_lookup&.comments&.signatures&.any?) &&
                type == :req &&
                parameters.size == 1 &&
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

          @pipeline.push_method(
            symbol_name,
            constant,
            method,
            rbi_method,
            signature,
            sanitized_parameters,
            rbs_lookup: rbs_lookup,
          )
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
        #: (UnboundMethod method, Module[top] constant) -> bool
        def method_owned_by_constant?(method, constant)
          # Widen the type of `method` to be nilable
          method = method #: UnboundMethod?

          while method
            return true if method.owner == constant

            method = method.super_method
          end

          false
        end

        #: (Module[top] mod) -> Hash[Symbol, Array[Symbol]]
        def method_names_by_visibility(mod)
          {
            public: public_instance_methods_of(mod),
            protected: protected_instance_methods_of(mod),
            private: private_instance_methods_of(mod),
          }
        end

        #: (Module[top] constant, String method_name) -> bool
        def struct_method?(constant, method_name)
          return false unless T::Props::ClassMethods === constant

          constant
            .props
            .keys
            .include?(method_name.gsub(/=$/, "").to_sym)
        end

        #: (Module[top]? attached_class, Symbol method_name) -> bool?
        def method_new_in_abstract_class?(attached_class, method_name)
          attached_class &&
            method_name == :new &&
            !!abstract_type_of(attached_class) &&
            Class === attached_class.singleton_class
        end

        #: (Module[top] constant) -> UnboundMethod?
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
