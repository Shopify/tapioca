# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SorbetSignatures < Base
        include Runtime::Reflection
        include RBIHelper

        private

        # @override
        #: (MethodNodeAdded event) -> void
        def on_method(event)
          signature = event.signature
          return unless signature

          event.node.sigs << compile_signature(signature, event.parameters)
        end

        #: (untyped signature, Array[[Symbol, String]] parameters) -> RBI::Sig
        def compile_signature(signature, parameters)
          parameter_types = parameter_types_for(signature, parameters)

          sig = RBI::Sig.new

          parameters.each_with_index do |(_, name), index|
            type = sanitize_signature_types(parameter_types.fetch(index))
            @pipeline.push_symbol(type)
            sig << RBI::SigParam.new(name, type)
          end

          return_type = name_of_type(signature.return_type)
          return_type = sanitize_signature_types(return_type)
          sig.return_type = return_type
          @pipeline.push_symbol(return_type)

          sig.type_params.concat(extract_type_parameters([*parameter_types, return_type]))

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

          sig.is_final = signature_final?(signature)

          sig
        end

        #: (untyped signature, Array[[Symbol, String]] parameters) -> Array[String]
        def parameter_types_for(signature, parameters)
          positional_types = signature.arg_types.map { |_name, type| type }
          keyword_types = signature.kwarg_types.values

          parameters.map do |kind, _name|
            type = case kind
            when :req, :opt
              positional_types.shift
            when :keyreq, :key
              keyword_types.shift
            when :rest
              signature.rest_type
            when :keyrest
              signature.keyrest_type
            when :block
              signature.block_type
            end

            type ? type.to_s : "T.untyped"
          end
        end

        #: (untyped signature) -> bool
        def signature_final?(signature)
          modules_with_final = T::Private::Methods.instance_variable_get(:@modules_with_final)
          # In https://github.com/sorbet/sorbet/pull/7531, Sorbet changed internal hashes to be compared by identity,
          # starting on version 0.5.11155
          final_methods = modules_with_final[signature.owner] || modules_with_final[signature.owner.object_id]
          return false unless final_methods

          final_methods.include?(signature.method_name)
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
