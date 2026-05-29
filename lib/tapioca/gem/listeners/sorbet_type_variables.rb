# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class SorbetTypeVariables < Base
        include Runtime::Reflection

        private

        # @override
        #: (ScopeNodeAdded event) -> void
        def on_scope(event)
          constant = event.constant
          node = event.node

          compile_type_variable_declarations(node, constant)

          sclass = RBI::SingletonClass.new
          compile_type_variable_declarations(sclass, singleton_class_of(constant))
          node << sclass if sclass.nodes.length > 1

          # Pick up inline RBS class type parameter declarations
          # (e.g. `#: [A, B]` on a class) when the runtime didn't track them
          # (no `extend T::Generic` / `type_member` calls were made).
          add_rbs_type_members(event)
        end

        #: (RBI::Tree tree, Module[top] constant) -> void
        def compile_type_variable_declarations(tree, constant)
          # Try to find the type variables defined on this constant, bail if we can't
          type_variables = Runtime::GenericTypeRegistry.lookup_type_variables(constant)
          return unless type_variables

          # Map each type variable to its string representation.
          #
          # Each entry of `type_variables` maps a Module to a String, or
          # is a `has_attached_class!` declaration, and the order they are inserted
          # into the hash is the order they should be defined in the source code.
          type_variable_declarations = type_variables.filter_map do |type_variable|
            node = node_from_type_variable(type_variable)
            next unless node

            tree << node
          end

          return if type_variable_declarations.empty?

          tree << RBI::Extend.new("T::Generic")
        end

        # Adds `extend T::Generic` and one `type_member` per RBS type
        # parameter when an inline `#: [A, B]` declaration is present on a
        # class or module. Does nothing when the runtime already tracked the
        # generic via Sorbet's `extend T::Generic` + `type_member` calls,
        # since {#compile_type_variable_declarations} already emitted them.
        #: (ScopeNodeAdded event) -> void
        def add_rbs_type_members(event)
          return if event.node.nodes.any?(RBI::TypeMember)

          rbs_comments = @pipeline.rbs_comments_for_constant(event.constant)
          return unless rbs_comments

          type_param_signatures = rbs_comments.signatures.select { |s| s.string.start_with?("[") }
          return if type_param_signatures.empty?

          qualifier = Tapioca::RBS::TypeQualifier.new(
            @pipeline.gem_graph,
            event.symbol.delete_prefix("::").split("::").reject(&:empty?),
          )

          added_any = false #: bool

          type_param_signatures.each do |signature|
            begin
              type_params = ::RBS::Parser.parse_type_params(signature.string)
            rescue ::RBS::ParsingError
              next
            end
            next if type_params.empty?

            type_params.each do |type_param|
              event.node << build_rbs_type_member(type_param, qualifier)
              added_any = true
            end
          end

          if added_any && !event.node.nodes.any? { |n| n.is_a?(RBI::Extend) && n.names.include?("T::Generic") }
            event.node << RBI::Extend.new("T::Generic")
          end
        end

        # Builds an `RBI::TypeMember` node from an RBS type parameter,
        # carrying over variance (`:in` / `:out`), `upper:` bound, and
        # `fixed:` default into the standard Sorbet `type_member` block
        # form.
        #: (untyped type_param, Tapioca::RBS::TypeQualifier qualifier) -> RBI::TypeMember
        def build_rbs_type_member(type_param, qualifier)
          name = type_param.name.to_s
          parts = ["type_member"]

          case type_param.variance
          when :covariant
            parts << "(:out)"
          when :contravariant
            parts << "(:in)"
          end

          block_parts = []

          if type_param.upper_bound
            rbi_type = ::RBI::RBS::TypeTranslator.translate(type_param.upper_bound)
            block_parts << "upper: #{qualifier.visit(rbi_type)}"
          end

          if type_param.default_type
            rbi_type = ::RBI::RBS::TypeTranslator.translate(type_param.default_type)
            block_parts << "fixed: #{qualifier.visit(rbi_type)}"
          end

          if block_parts.any?
            parts << " { { #{block_parts.join(", ")} } }"
          end

          RBI::TypeMember.new(name, parts.join)
        end

        #: (Tapioca::TypeVariableModule type_variable) -> RBI::Node?
        def node_from_type_variable(type_variable)
          case type_variable.type
          when Tapioca::TypeVariableModule::Type::HasAttachedClass
            RBI::Send.new(type_variable.serialize)
          else
            type_variable_name = type_variable.name
            return unless type_variable_name

            RBI::TypeMember.new(type_variable_name, type_variable.serialize)
          end
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
