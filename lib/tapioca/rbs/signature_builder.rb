# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBS
    # Builds a {Tapioca::Runtime::RbsSignature} from a Rubydex method
    # definition. Both the gem-RBI pipeline and the DSL signature lookup
    # need the same translate-and-qualify dance — parse the `#:` comment
    # strings, translate them through `RBI::RBS::*Translator`, and qualify
    # every constant reference against a Rubydex graph for the surrounding
    # lexical scope. The two call sites differ only in *which* graph they
    # qualify against (gem-scoped vs workspace-scoped); the rest is the
    # same work.
    module SignatureBuilder
      class << self
        # Reads the inline `#:` comments on `definition`, parses each
        # signature line as RBS, translates to `RBI::Sig`, and qualifies
        # every constant against `graph` using the definition's lexical
        # nesting. Returns nil when the definition has no RBS signatures
        # or none of them parse.
        #
        # The resulting {Tapioca::Runtime::RbsSignature} owns N overload
        # sigs (one per `#:` line) plus the method-level annotations
        # (`@abstract`, `@override`, `@without_runtime`, ...) ready for
        # {Tapioca::Runtime::RbsSignature#compile_to_rbi_sig} to apply.
        #: (
        #|   (Method | UnboundMethod) method,
        #|   Rubydex::Definition definition,
        #|   Symbol kind,
        #|   Rubydex::Graph graph
        #| ) -> Tapioca::Runtime::RbsSignature?
        def build(method, definition, kind, graph)
          parsed = parse_rbs_comments(definition)
          return if parsed.signatures.empty?

          qualifier = TypeQualifier.new(graph, nesting_for(definition))
          rbi_method = build_rbi_method(method)

          sigs = parsed.signatures.filter_map do |signature|
            sig = build_sig(signature.string, kind, rbi_method, method)
            next unless sig

            qualify_sig!(sig, qualifier)
            sig
          end
          return if sigs.empty?

          Tapioca::Runtime::RbsSignature.new(
            method,
            sigs,
            annotations: parsed.method_annotations.map(&:string),
          )
        rescue ::RBS::ParsingError, ::RBI::Error
          nil
        end

        private

        #: (Rubydex::Definition definition) -> Tapioca::RBS::Comments::Parsed
        def parse_rbs_comments(definition)
          tuples = definition.comments.map do |comment|
            # Rubydex uses 0-indexed lines; we present 1-indexed lines to
            # match `Method#source_location` and downstream callers.
            [comment.string, comment.location.start_line + 1]
          end
          Tapioca::RBS::Comments.parse(tuples)
        end

        #: (String signature_string, Symbol kind, RBI::Method rbi_method, (Method | UnboundMethod) method) -> RBI::Sig?
        def build_sig(signature_string, kind, rbi_method, method)
          case kind
          when :attr_reader, :attr_accessor
            build_attr_sig(signature_string, attr_name_from(method), writer: false)
          when :attr_writer
            build_attr_sig(signature_string, attr_name_from(method), writer: true)
          else
            method_type = ::RBS::Parser.parse_method_type(signature_string)
            ::RBI::RBS::MethodTypeTranslator.translate(rbi_method, method_type)
          end
        rescue ::RBS::ParsingError, ::RBI::Error
          nil
        end

        #: (String signature_string, String attr_name, writer: bool) -> RBI::Sig
        def build_attr_sig(signature_string, attr_name, writer:)
          attr_type = ::RBS::Parser.parse_type(signature_string)
          translated = ::RBI::RBS::TypeTranslator.translate(attr_type)

          sig = ::RBI::Sig.new
          sig.params << ::RBI::SigParam.new(attr_name, translated) if writer
          sig.return_type = translated
          sig
        end

        #: ((Method | UnboundMethod) method) -> RBI::Method
        def build_rbi_method(method)
          rbi = RBI::Method.new(method.name.to_s)
          method.parameters.each_with_index do |(type, name), index|
            rbi_name = name ? name.to_s : "_arg#{index}"
            case type
            when :req
              rbi << RBI::ReqParam.new(rbi_name)
            when :opt
              rbi << RBI::OptParam.new(rbi_name, "T.unsafe(nil)")
            when :rest
              rbi << RBI::RestParam.new(rbi_name)
            when :keyreq
              rbi << RBI::KwParam.new(rbi_name)
            when :key
              rbi << RBI::KwOptParam.new(rbi_name, "T.unsafe(nil)")
            when :keyrest
              rbi << RBI::KwRestParam.new(rbi_name)
            when :block
              rbi << RBI::BlockParam.new(rbi_name)
            end
          end
          rbi
        end

        #: ((Method | UnboundMethod) method) -> String
        def attr_name_from(method)
          method.name.to_s.delete_suffix("=")
        end

        #: (RBI::Sig sig, TypeQualifier qualifier) -> void
        def qualify_sig!(sig, qualifier)
          new_params = sig.params.map do |param|
            type = param.type
            new_type = type.is_a?(::RBI::Type) ? qualifier.visit(type) : type.to_s
            ::RBI::SigParam.new(param.name, new_type)
          end
          sig.params.replace(new_params)

          return_type = sig.return_type
          sig.return_type = qualifier.visit(return_type) if return_type.is_a?(::RBI::Type)
        end

        # Lexical nesting at the definition's source position, expressed
        # in the shape Rubydex's `Graph#resolve_constant` expects: short
        # names, outermost first. See {Tapioca::RBS::DslSignatures} for
        # the historical context.
        #
        # The translation from `Definition#lexical_nesting` (deepest
        # first, giving each scope's short name + qualified declaration
        # name) accounts for three source shapes:
        #
        # - **Plain nesting** (`module Foo; class Bar; ...`): each inner
        #   scope is contributed as its short name (`["Foo", "Bar"]`).
        # - **Compound-path opening** (`class Foo::Bar; ...`): the
        #   outermost scope is contributed as its fully-qualified
        #   declaration name (`["Foo::Bar"]`).
        # - **Absolute-path opening** (`class Foo; module ::Bar; ...`):
        #   the inner scope is contributed as its declaration name with
        #   a leading `::` (`["Foo", "::Bar"]`), which is the marker
        #   Rubydex uses for "this is a top-level reference, restart the
        #   walk."
        #
        # Anonymous classes (`Class.new do ... end`) show up as entries
        # in `Definition#lexical_nesting` but their declaration name is
        # the synthetic `…<anonymous>` form Rubydex uses, which is
        # useless for constant resolution. We drop those frames so the
        # surrounding named scopes still get picked up correctly.
        #: (Rubydex::Definition definition) -> Array[String]
        def nesting_for(definition)
          scopes = definition.lexical_nesting.reject do |s|
            declaration = s.declaration
            declaration.nil? || declaration.name.include?("<anonymous>")
          end

          result = [] #: Array[String]
          parent_decl_name = nil #: String?
          scopes.reverse_each do |scope|
            declaration = scope.declaration #: as !nil
            decl_name = declaration.name

            entry = if parent_decl_name.nil?
              decl_name
            elsif decl_name == "#{parent_decl_name}::#{scope.name}"
              scope.name
            else
              "::#{decl_name}"
            end

            result << entry
            parent_decl_name = decl_name
          end

          result
        end
      end
    end
  end
end
