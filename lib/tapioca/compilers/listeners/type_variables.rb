# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    module NodeListeners
      class TypeVariables < Base
        extend T::Sig

        include Reflection

        private

        sig { override.params(event: Tapioca::Compilers::SymbolTableCompiler::NodeEvent).void }
        def on_node(event)
          node = event.node
          return unless node.is_a?(RBI::Scope)

          compile_type_variable_declarations(node, event.constant)

          sclass = RBI::SingletonClass.new
          compile_type_variable_declarations(sclass, singleton_class_of(event.constant))
          node << sclass if sclass.nodes.length > 1
        end

        sig { params(tree: RBI::Tree, constant: Module).void }
        def compile_type_variable_declarations(tree, constant)
          # Try to find the type variables defined on this constant, bail if we can't
          type_variables = GenericTypeRegistry.lookup_type_variables(constant)
          return unless type_variables

          # Map each type variable to its string representation.
          #
          # Each entry of `type_variables` maps a Module to a String,
          # and the order they are inserted into the hash is the order they should be
          # defined in the source code.
          type_variable_declarations = type_variables.map do |type_variable|
            type_variable_name = type_variable.name
            next unless type_variable_name

            tree << RBI::TypeMember.new(type_variable_name, type_variable.serialize)
          end

          return if type_variable_declarations.empty?

          tree << RBI::Extend.new("T::Generic")
        end
      end
    end
  end
end
