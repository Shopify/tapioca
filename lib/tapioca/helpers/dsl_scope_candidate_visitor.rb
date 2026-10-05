# typed: strict
# frozen_string_literal: true

require "prism"
require "set"

module Tapioca
  module RBIFilesHelper
    class DslScopeCandidateVisitor < Prism::Visitor
      #: (Set[String], Hash[String, Set[String]], String) -> void
      def initialize(scope_names, method_names, source)
        @scope_names = scope_names
        @method_names = method_names
        @source = source
        @scope = nil #: String?
      end

      #: (Prism::ProgramNode) -> bool
      def candidate?(program)
        catch(:dsl_scope_candidate) do
          visit(program)
          false
        end
      end

      #: (Prism::ClassNode) -> void
      def visit_class_node(node)
        visit_scope(node, qualified_name(node.constant_path.slice))
      end

      #: (Prism::ModuleNode) -> void
      def visit_module_node(node)
        visit_scope(node, qualified_name(node.constant_path.slice))
      end

      #: (Prism::SingletonClassNode) -> void
      def visit_singleton_class_node(node)
        visit_scope(node, "#{@scope}::<self>")
      end

      #: (Prism::DefNode) -> void
      def visit_def_node(node)
        parameters = node.parameters
        if parameters.is_a?(Prism::ParametersNode)
          parameters.each_child_node do |parameter|
            case parameter
            when Prism::RequiredParameterNode,
                Prism::OptionalParameterNode,
                Prism::RestParameterNode,
                Prism::RequiredKeywordParameterNode,
                Prism::OptionalKeywordParameterNode,
                Prism::NoKeywordsParameterNode,
                Prism::KeywordRestParameterNode,
                Prism::BlockParameterNode
              next
            else
              # Let RBI::Parser report parameter forms it does not support.
              throw(:dsl_scope_candidate, true)
            end
          end
        end

        super
      end

      #: (Prism::ConstantWriteNode) -> void
      def visit_constant_write_node(node)
        check_constant(node.name.to_s, node.value)
        super
      end

      #: (Prism::ConstantPathWriteNode) -> void
      def visit_constant_path_write_node(node)
        check_constant(node.target.slice, node.value)
        super
      end

      #: (Prism::CallNode) -> void
      def visit_call_node(node)
        if node.name == :enums && node.block && !node.arguments
          visit_scope(node, "#{@scope}.enums")
        else
          super
        end
      end

      private

      #: (Prism::Node, String) -> void
      def visit_scope(node, name)
        previous_scope = @scope
        @scope = name
        check_scope(name)
        visit_child_nodes(node)
      ensure
        @scope = previous_scope
      end

      #: (String) -> void
      def check_scope(name)
        throw(:dsl_scope_candidate, true) if @scope_names.include?(name)

        method_names = @method_names.fetch(name, nil)
        throw(:dsl_scope_candidate, true) if method_names && method_names.any? { |method_name| @source.include?(method_name) }
      end

      #: (String, Prism::Node) -> void
      def check_constant(name, value)
        throw(:dsl_scope_candidate, true) if struct_with_block?(value) || @scope_names.include?(qualified_name(name))
      end

      #: (String) -> String
      def qualified_name(name)
        name.start_with?("::") ? name : "#{@scope}::#{name}"
      end

      #: (Prism::Node) -> bool
      def struct_with_block?(node)
        return false unless node.is_a?(Prism::CallNode) && node.name == :new && node.block

        receiver = node.receiver
        !!(receiver && receiver.slice.include?("Struct"))
      end
    end
  end
end
