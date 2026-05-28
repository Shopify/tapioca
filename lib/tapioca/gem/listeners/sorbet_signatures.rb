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
          if signature
            event.node.sigs << signature.compile_to_rbi_sig(event.parameters) { |sym| @pipeline.push_symbol(sym) }
            return
          end

          rbs_lookup = event.rbs_lookup
          return unless rbs_lookup
          return if rbs_lookup.comments.signatures.empty?

          compile_rbs_lookup(event, rbs_lookup)
        end

        # Builds RBI sigs for `node` from a set of inline `#: ...` RBS comments
        # captured on the method's source declaration. Translates Spoom/RBS
        # method types (via the `rbi` gem's `MethodTypeTranslator` for plain
        # methods, or `TypeTranslator` for attr_* methods), fully-qualifies
        # every constant reference using the pipeline's Rubydex graph, and
        # applies any `# @abstract`, `# @override`, `# @without_runtime`, etc.
        # annotations directly to the emitted `RBI::Sig`.
        #: (MethodNodeAdded event, Pipeline::RBSMethodLookup rbs_lookup) -> void
        def compile_rbs_lookup(event, rbs_lookup)
          method_annotations = rbs_lookup.comments.method_annotations

          qualifier = Tapioca::RBS::TypeQualifier.new(@pipeline.gem_graph, nesting_for(event))
          node = event.node

          rbs_lookup.comments.signatures.each do |signature|
            sig = build_rbi_sig(node, signature.string, rbs_lookup.kind, qualifier)
            next unless sig

            apply_method_annotations(sig, method_annotations)

            # `method_added` and `singleton_method_added` can never carry a
            # runtime sig — Sorbet wraps these hooks itself, so any sig we
            # emit for them must be marked `without_runtime`.
            if node.name == "method_added" || node.name == "singleton_method_added"
              sig.without_runtime = true
            end

            push_sig_symbols(sig)
            node.sigs << sig
          end
        end

        # Parses a single RBS signature string and translates it into an
        # {RBI::Sig} with fully-qualified type strings. For regular methods
        # the string is parsed as an `RBS::MethodType`; for attr_* methods it
        # is parsed as a plain `RBS::Type`, then wrapped into a getter or
        # setter sig depending on the kind of attr method.
        #: (RBI::Method node, String signature_string, Symbol kind, Tapioca::RBS::TypeQualifier qualifier) -> RBI::Sig?
        def build_rbi_sig(node, signature_string, kind, qualifier)
          case kind
          when :attr_reader, :attr_accessor
            attr_type = ::RBS::Parser.parse_type(signature_string)
            sig = ::RBI::Sig.new
            sig.return_type = qualifier.visit(::RBI::RBS::TypeTranslator.translate(attr_type))
            sig
          when :attr_writer
            attr_type = ::RBS::Parser.parse_type(signature_string)
            sig = ::RBI::Sig.new
            translated = qualifier.visit(::RBI::RBS::TypeTranslator.translate(attr_type))
            attr_name = node.name.to_s.delete_suffix("=")
            sig.params << ::RBI::SigParam.new(attr_name, translated)
            sig.return_type = translated
            sig
          else
            method_type = ::RBS::Parser.parse_method_type(signature_string)
            rbi_sig = ::RBI::RBS::MethodTypeTranslator.translate(node, method_type)
            qualify_sig(rbi_sig, qualifier)
            rbi_sig
          end
        rescue ::RBS::ParsingError, ::RBI::Error
          nil
        end

        # Walks an `RBI::Sig`, replacing each `Type` param and return type
        # with its fully-qualified string form (so the printer emits the
        # already-qualified text verbatim and never recurses back into the
        # default RBI serializer).
        #: (RBI::Sig sig, Tapioca::RBS::TypeQualifier qualifier) -> void
        def qualify_sig(sig, qualifier)
          new_params = sig.params.map do |param|
            param_type = param.type
            new_type = param_type.is_a?(::RBI::Type) ? qualifier.visit(param_type) : param_type.to_s
            ::RBI::SigParam.new(param.name, new_type)
          end
          sig.params.replace(new_params)

          return_type = sig.return_type
          sig.return_type = qualifier.visit(return_type) if return_type.is_a?(::RBI::Type)
        end

        #: (RBI::Sig sig, Array[Tapioca::RBS::Comments::Annotation] annotations) -> void
        def apply_method_annotations(sig, annotations)
          annotations.each do |annotation|
            case annotation.string
            when "@abstract"
              sig.is_abstract = true
            when "@final"
              sig.is_final = true
            when "@override"
              sig.is_override = true
            when "@override(allow_incompatible: true)"
              sig.is_override = true
              sig.allow_incompatible_override = true
            when "@override(allow_incompatible: :visibility)"
              sig.is_override = true
              sig.allow_incompatible_override_visibility = true
            when "@overridable"
              sig.is_overridable = true
            when "@without_runtime"
              sig.without_runtime = true
            end
          end
        end

        # Pushes every type symbol referenced by an RBI sig into the pipeline so
        # downstream symbol resolution still sees those constants.
        #: (RBI::Sig sig) -> void
        def push_sig_symbols(sig)
          sig.params.each do |param|
            push_type_symbols(param.type.to_s)
          end
          push_type_symbols(sig.return_type.to_s)
        end

        #: (String type_string) -> void
        def push_type_symbols(type_string)
          @pipeline.push_symbol(sanitize_signature_types(type_string))
        end

        # Lexical nesting (e.g. `["Foo", "Bar"]`) for a method defined under
        # `Foo::Bar`. For singleton methods the nesting is the attached class
        # path, since RBS comments are written against the actual class scope.
        #: (MethodNodeAdded event) -> Array[String]
        def nesting_for(event)
          event.symbol.delete_prefix("::").split("::").reject(&:empty?)
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
