# typed: strict
# frozen_string_literal: true

module Tapioca
  module Runtime
    # Polymorphic wrapper around a method signature.
    #
    # The runtime side of Tapioca needs to talk about "the signature of a
    # method" in a few different places (gem RBI generation, DSL compilers,
    # type-aware helpers) without leaking the underlying representation. At
    # the moment that representation is always a Sorbet
    # `T::Private::Methods::Signature`, but the same surface needs to grow to
    # cover inline RBS signatures parsed from source. This abstract class is
    # the place callers depend on; concrete subclasses encapsulate the
    # backend-specific work.
    #
    # The public surface is deliberately small. We never expose raw
    # `arg_types` / `kwarg_types` / `rest_type` / etc. — those are internal
    # to whichever backend produced the signature. Callers ask high-level
    # questions ("compile yourself into an RBI sig", "give me your return
    # type as a string") and the signature answers.
    #
    # @abstract
    class Signature
      # Type strings (post-sanitization) that don't carry useful information
      # for downstream callers asking "what's the type of …?". Both the
      # `ActiveModelTypeHelper` and the `GraphqlTypeHelper` filter on this
      # set when deciding whether the signature actually says something.
      MEANINGLESS_TYPE_STRINGS = [
        "T.untyped",
        "::T.untyped",
        "T.noreturn",
        "::T.noreturn",
        "void",
        "<NOT-TYPED>",
        "<VOID>",
      ].to_set.freeze #: Set[String]

      # The method this signature was attached to. Sorbet's runtime wraps
      # methods with sigs in a layer that points back to the original
      # method via `signature.method`; callers that introspect parameter
      # names / source locations want that wrapped method, not the
      # surface one.
      # @abstract
      #: -> (Method | UnboundMethod)
      def method = raise NotImplementedError, "Abstract method called"

      # Parameter type strings in positional source order, ready to feed
      # into `RBI::TypedParam` constructors. Encapsulates the
      # arg/kwarg/rest/keyrest/block plumbing.
      # @abstract
      #: -> Array[String]
      def parameter_type_strings = raise NotImplementedError, "Abstract method called"

      # The signature's return type as a sanitized string (no `<VOID>` /
      # `<NOT-TYPED>` artifacts).
      # @abstract
      #: -> String
      def return_type_string = raise NotImplementedError, "Abstract method called"

      # Same as {#return_type_string}, but returns `nil` when the
      # underlying type is one of {MEANINGLESS_TYPE_STRINGS} (`void`,
      # `T.untyped`, `T.noreturn`, etc.). Callers that want to ignore
      # "no useful info" sigs use this to short-circuit.
      #: -> String?
      def valid_return_type_string
        type_string = return_type_string
        return if MEANINGLESS_TYPE_STRINGS.include?(type_string)

        type_string
      end

      # The first positional argument's type as a sanitized string, or
      # `nil` when the signature has no positional arguments or its first
      # arg type is meaningless. Used by helpers that infer custom types
      # from a method's lone "value" parameter (e.g.
      # `ActiveModelTypeHelper#lookup_arg_type_of_method`).
      # @abstract
      #: -> String?
      def valid_first_arg_type_string = raise NotImplementedError, "Abstract method called"

      # Compiles this signature into a list of `RBI::Sig`s. Sorbet
      # runtime sigs always produce a single-element array; inline RBS
      # signatures can carry multiple overloads (`#: (String) -> ...`
      # and `#: (Symbol) -> ...` on the same method) and produce one
      # entry per overload, in source order.
      #
      # `parameters` is the sanitized `[type, name]` list the caller has
      # already prepared from the underlying method. The block receives
      # every constant symbol the signature references, so callers (the
      # gem pipeline, typically) can feed them back into their symbol
      # tracker.
      # @abstract
      #: (Array[[Symbol, String]] parameters) { (String symbol) -> void } -> Array[RBI::Sig]
      def compile_to_rbi_sig(parameters, &push_symbol) = raise NotImplementedError, "Abstract method called"
    end

    # Concrete {Signature} backed by Sorbet's runtime
    # `T::Private::Methods::Signature`. This is what
    # `Runtime::Reflection.signature_of` returns today; the wrapper hides
    # Sorbet's internal layout so callers never have to touch
    # `arg_types`/`kwarg_types`/`rest_type`/etc. directly.
    class SorbetSignature < Signature
      include Reflection
      include RBIHelper

      # Sorbet-specific "meaningless" runtime type sentinels. These are
      # the runtime-level equivalents of {MEANINGLESS_TYPE_STRINGS} and
      # only matter to {SorbetSignature}; the string filter on the
      # parent class is the canonical user-facing answer.
      MEANINGLESS_TYPES = [
        T.untyped,
        T.noreturn,
        T::Private::Types::Void,
        T::Private::Types::NotTyped,
      ].freeze #: Array[Object]
      private_constant :MEANINGLESS_TYPES

      #: (untyped signature) -> void
      def initialize(signature)
        super()
        @signature = signature
      end

      # @override
      #: -> UnboundMethod
      def method
        @signature.method
      end

      # @override
      #: -> Array[String]
      def parameter_type_strings
        parameter_types.values.map { |type| sanitize_signature_types(type.to_s) }
      end

      # @override
      #: -> String
      def return_type_string
        sanitize_signature_types(name_of_type(@signature.return_type))
      end

      # @override
      #: -> String?
      def valid_first_arg_type_string
        first_arg_type = @signature.arg_types.dig(0, 1)
        return unless first_arg_type
        return unless meaningful_runtime_type?(first_arg_type)

        type_string = sanitize_signature_types(first_arg_type.to_s)
        return if MEANINGLESS_TYPE_STRINGS.include?(type_string)

        type_string
      end

      # @override
      #: (Array[[Symbol, String]] parameters) { (String symbol) -> void } -> Array[RBI::Sig]
      def compile_to_rbi_sig(parameters, &push_symbol)
        types_by_name = parameter_types
        sig = RBI::Sig.new

        parameters.each do |_, name|
          type = sanitize_signature_types(types_by_name[name.to_sym].to_s)
          push_symbol.call(type)
          sig << RBI::SigParam.new(name, type)
        end

        return_type = return_type_string
        sig.return_type = return_type
        push_symbol.call(return_type)

        sig.type_params.concat(
          extract_type_parameters(types_by_name.values.map(&:to_s).append(return_type)),
        )

        apply_mode!(sig)
        sig.is_final = final?

        [sig]
      end

      private

      # Builds the ordered `{ name => type }` mapping of every parameter the
      # signature describes (positional, keyword, rest, keyrest, block).
      # Used by both {#parameter_type_strings} and {#compile_to_rbi_sig}.
      #: -> Hash[Symbol, untyped]
      def parameter_types
        parameter_types = @signature.arg_types.to_h #: Hash[Symbol, untyped]
        parameter_types.merge!(@signature.kwarg_types)

        rest_type = @signature.rest_type
        parameter_types[@signature.rest_name] = rest_type if rest_type

        keyrest_type = @signature.keyrest_type
        parameter_types[@signature.keyrest_name] = keyrest_type if keyrest_type

        if @signature.block_name
          parameter_types[@signature.block_name] = @signature.block_type
        end

        parameter_types
      end

      #: (RBI::Sig sig) -> void
      def apply_mode!(sig)
        case @signature.mode
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
      end

      #: -> bool
      def final?
        modules_with_final = T::Private::Methods.instance_variable_get(:@modules_with_final)
        # In https://github.com/sorbet/sorbet/pull/7531, Sorbet changed
        # internal hashes to be compared by identity, starting on version
        # 0.5.11155, so we have to look both ways.
        final_methods = modules_with_final[@signature.owner] || modules_with_final[@signature.owner.object_id]
        return false unless final_methods

        final_methods.include?(@signature.method_name)
      end

      #: (untyped type) -> bool
      def meaningful_runtime_type?(type)
        !MEANINGLESS_TYPES.include?(type)
      end
    end

    # Concrete {Signature} backed by inline RBS comments that have already
    # been translated and qualified into `RBI::Sig` instances by
    # {Tapioca::RBS::SignatureBuilder}. RBS allows multiple `#:` lines on
    # the same method (overloads); the wrapper carries all of them, along
    # with the method-level annotations (`# @abstract`, `# @override`,
    # `# @without_runtime`, ...) so {#compile_to_rbi_sig} can apply them
    # to every emitted sig.
    #
    # The single-sig accessors ({#parameter_type_strings},
    # {#return_type_string}, {#valid_first_arg_type_string}) pick the
    # last overload, mirroring the convention the require-hook RBS
    # rewriter used: Sorbet's runtime can only attach one signature per
    # method anyway.
    class RbsSignature < Signature
      #: (
      #|   (Method | UnboundMethod) method,
      #|   Array[RBI::Sig] sigs,
      #|   ?annotations: Array[String]
      #| ) -> void
      def initialize(method, sigs, annotations: [])
        super()
        @method = method
        @sigs = sigs
        @annotations = annotations
      end

      # @override
      #: -> (Method | UnboundMethod)
      def method # rubocop:disable Style/TrivialAccessors
        @method
      end

      # @override
      #: -> Array[String]
      def parameter_type_strings
        last_sig.params.map { |param| param.type.to_s }
      end

      # @override
      #: -> String
      def return_type_string
        last_sig.return_type.to_s
      end

      # @override
      #: -> String?
      def valid_first_arg_type_string
        first_param = last_sig.params.first
        return unless first_param

        type_string = first_param.type.to_s
        return if MEANINGLESS_TYPE_STRINGS.include?(type_string)

        type_string
      end

      # @override
      #: (Array[[Symbol, String]] parameters) { (String symbol) -> void } -> Array[RBI::Sig]
      def compile_to_rbi_sig(parameters, &push_symbol)
        @sigs.map do |sig|
          out = clone_sig(sig)
          apply_method_annotations(out)

          # Feed every type the sig references back to the caller's symbol
          # tracker so downstream symbol-resolution still sees those
          # constants — same contract as `SorbetSignature#compile_to_rbi_sig`.
          out.params.each { |param| push_symbol.call(param.type.to_s) }
          push_symbol.call(out.return_type.to_s)

          out
        end
      end

      private

      #: -> RBI::Sig
      def last_sig
        @sigs.last #: as !nil
      end

      # Produces a shallow copy of `sig` so {#compile_to_rbi_sig} can mutate
      # the copy (applying annotations, setting `without_runtime` on
      # `method_added`/`singleton_method_added`) without disturbing the
      # original we built at construction.
      #: (RBI::Sig sig) -> RBI::Sig
      def clone_sig(sig)
        new_sig = RBI::Sig.new
        sig.params.each { |param| new_sig.params << RBI::SigParam.new(param.name, param.type) }
        new_sig.return_type = sig.return_type
        new_sig.type_params.concat(sig.type_params)
        new_sig.is_abstract = sig.is_abstract
        new_sig.is_override = sig.is_override
        new_sig.is_overridable = sig.is_overridable
        new_sig.is_final = sig.is_final
        new_sig.allow_incompatible_override = sig.allow_incompatible_override
        new_sig.allow_incompatible_override_visibility = sig.allow_incompatible_override_visibility
        new_sig.without_runtime = sig.without_runtime
        new_sig.checked = sig.checked
        new_sig
      end

      #: (RBI::Sig sig) -> void
      def apply_method_annotations(sig)
        @annotations.each do |annotation|
          case annotation
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

        # `method_added` and `singleton_method_added` can never carry a
        # runtime sig — Sorbet wraps these hooks itself, so any sig we
        # emit for them must be marked `without_runtime`.
        if @method.name == :method_added || @method.name == :singleton_method_added
          sig.without_runtime = true
        end
      end
    end
  end
end
