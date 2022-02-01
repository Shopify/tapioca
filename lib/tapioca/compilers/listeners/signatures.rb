# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    module NodeListeners
      class Signatures < Base
        extend T::Sig

        include Reflection

        TYPE_PARAMETER_MATCHER = /T\.type_parameter\(:?([[:word:]]+)\)/

        private

        sig { override.params(event: Tapioca::Compilers::SymbolTableCompiler::NodeEvent).void }
        def on_node(event)
          node = event.node

          return unless node.is_a?(RBI::Method)
          return unless event.is_a?(Tapioca::Compilers::SymbolTableCompiler::MethodEvent)
          return unless event.signature

          node.sigs << compile_signature(event.tree, event.signature, event.parameters)
        end

        sig { params(tree: RBI::Tree, signature: T.untyped, parameters: T::Array[[Symbol, String]]).returns(RBI::Sig) }
        def compile_signature(tree, signature, parameters)
          parameter_types = T.let(signature.arg_types.to_h, T::Hash[Symbol, T::Types::Base])
          parameter_types.merge!(signature.kwarg_types)
          parameter_types[signature.rest_name] = signature.rest_type if signature.has_rest
          parameter_types[signature.keyrest_name] = signature.keyrest_type if signature.has_keyrest
          parameter_types[signature.block_name] = signature.block_type if signature.block_name

          sig = RBI::Sig.new

          parameters.each do |_, name|
            type = @compiler.sanitize_signature_types(parameter_types[name.to_sym].to_s)
            @compiler.push_symbol(tree, type)
            sig << RBI::SigParam.new(name, type)
          end

          return_type = name_of_type(signature.return_type)
          return_type = @compiler.sanitize_signature_types(return_type)
          sig.return_type = return_type
          @compiler.push_symbol(tree, return_type)

          parameter_types.values.join(", ").scan(TYPE_PARAMETER_MATCHER).flatten.uniq.each do |k, _|
            sig.type_params << k
          end

          case signature.mode
          when "abstract"
            sig.is_abstract = true
          when "override"
            sig.is_override = true
          when "overridable_override"
            sig.is_overridable = true
            sig.is_override = true
          when "overridable"
            sig.is_overridable = true
          end

          sig
        end
      end
    end
  end
end
