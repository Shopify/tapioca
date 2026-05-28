# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBS
    # Translates {RBI::Type} trees into the same fully-qualified string form
    # Tapioca uses elsewhere when emitting RBI: every constant reference
    # (user-defined as well as Sorbet's own `T.*` and `T::*`) is prefixed
    # with `::`. Bare names from RBS like `Integer` or `Bar` are first
    # resolved through a {Rubydex::Graph} using a lexical `nesting` so the
    # output reflects the actual fully-qualified constant name (`::Integer`,
    # `::Foo::Bar`, ...).
    #
    # We deliberately produce strings instead of constructing transformed
    # {RBI::Type} instances because we want a single shared serialization
    # convention that matches Tapioca's existing output — every type lives
    # under the global namespace, including `::T`.
    class TypeQualifier
      # @without_runtime
      #: Rubydex::Graph
      attr_reader :graph

      #: Array[String]
      attr_reader :nesting

      #: (Rubydex::Graph graph, Array[String] nesting) -> void
      def initialize(graph, nesting)
        @graph = graph
        @nesting = nesting
      end

      # Converts an {RBI::Type} tree into a fully-qualified string. Both
      # user-defined constants and Sorbet's `T` helpers are emitted with a
      # leading `::` (e.g. `::String`, `::T.nilable(::Integer)`, `::T::Array[::String]`).
      #: (RBI::Type type) -> String
      def visit(type)
        case type
        when RBI::Type::Simple
          qualify(type.name)
        when RBI::Type::Generic
          "#{qualify_generic(type.name)}[#{type.params.map { |t| visit(t) }.join(", ")}]"
        when RBI::Type::Class
          "::T::Class[#{visit(type.type)}]"
        when RBI::Type::Module
          "::T::Module[#{visit(type.type)}]"
        when RBI::Type::ClassOf
          inner = type.type_parameter
          if inner
            "::T.class_of(#{visit(type.type)})[#{visit(inner)}]"
          else
            "::T.class_of(#{visit(type.type)})"
          end
        when RBI::Type::Nilable
          "::T.nilable(#{visit(type.type)})"
        when RBI::Type::All
          "::T.all(#{type.types.map { |t| visit(t) }.join(", ")})"
        when RBI::Type::Any
          "::T.any(#{type.types.map { |t| visit(t) }.join(", ")})"
        when RBI::Type::Tuple
          "[#{type.types.map { |t| visit(t) }.join(", ")}]"
        when RBI::Type::Shape
          fields = type.types.map { |name, t| "#{name.inspect} => #{visit(t)}" }
          "{#{fields.join(", ")}}"
        when RBI::Type::TypeAlias
          qualify(type.name)
        when RBI::Type::TypeParameter
          "::T.type_parameter(#{type.name.inspect})"
        when RBI::Type::Proc
          render_proc(type)
        when RBI::Type::Anything
          "::T.anything"
        when RBI::Type::AttachedClass
          "::T.attached_class"
        when RBI::Type::Boolean
          "::T::Boolean"
        when RBI::Type::NoReturn
          "::T.noreturn"
        when RBI::Type::SelfType
          "::T.self_type"
        when RBI::Type::Untyped
          "::T.untyped"
        when RBI::Type::Void
          "void"
        else
          # Unknown subclass — fall back to RBI's own serializer.
          type.to_rbi
        end
      end

      private

      #: (RBI::Type::Proc type) -> String
      def render_proc(type)
        result = +"::T.proc"

        bind = type.proc_bind
        result << ".bind(#{visit(bind)})" if bind

        unless type.proc_params.empty?
          result << ".params("
          result << type.proc_params.map { |name, t| "#{name}: #{visit(t)}" }.join(", ")
          result << ")"
        end

        returns = type.proc_returns
        result << if returns.is_a?(RBI::Type::Void)
          ".void"
        else
          ".returns(#{visit(returns)})"
        end

        result
      end

      # Fully-qualifies a constant name, returning `::Foo::Bar` when the name
      # resolves in the current nesting. Names already prefixed with `::` are
      # returned as-is. Names that can't be resolved through the graph fall
      # back to a top-level (`::`) qualification.
      #: (String name) -> String
      def qualify(name)
        return name if name.start_with?("::")

        resolved = @graph.resolve_constant(name, @nesting)
        return "::#{resolved.name}" if resolved

        "::#{name}"
      end

      # Same as {#qualify}, but specialized for `Generic` names.
      #
      # `RBI::Type::Generic` covers both Sorbet's builtin parametric
      # generics (`T::Array[X]`, `T::Hash[K, V]`, ...) and user-defined
      # generic classes that extend `T::Generic`. RBI's `TypeTranslator`
      # already prefixes the Sorbet builtins with `::T::`, so those pass
      # through unchanged.
      #
      # User-defined generics are a different beast: Sorbet's runtime
      # `T::Types::TypedGenericType#name` emits them *without* a leading
      # `::`, while their type parameters keep the standard `::Foo`
      # qualification. We match that convention here so generated RBI
      # stays consistent with the runtime-driven path — resolve the name
      # through Rubydex (so `ValueType` becomes
      # `Tapioca::Dsl::Helpers::ActiveModelTypeHelperSpec::ValueType`) but
      # don't prepend `::`.
      #: (String name) -> String
      def qualify_generic(name)
        return name if name.start_with?("::T::")

        resolved = @graph.resolve_constant(name, @nesting)
        return resolved.name if resolved

        name
      end
    end
  end
end
