# typed: strict
# frozen_string_literal: true

module RBS
  module AST
    module Declarations
      class Base
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).returns(NilClass) }
        def visit(visitor)
        end
      end

      class Global
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_declaration_global(self)
        end
      end

      class Class
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_declaration_class(self)
        end
      end

      class Module
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_declaration_module(self)
        end
      end

      class Constant
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_declaration_constant(self)
        end
      end

      class TypeAlias
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_declaration_type_alias(self)
        end
      end

      class Interface
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_declaration_interface(self)
        end
      end
    end

    module Members
      class Base
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).returns(NilClass) }
        def visit(visitor)
        end
      end

      class Alias
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_alias(self)
        end
      end

      class ClassInstanceVariable
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_class_instance_variable(self)
        end
      end

      class ClassVariable
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_class_variable(self)
        end
      end

      class InstanceVariable
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_instance_variable(self)
        end
      end

      class Private
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_private(self)
        end
      end

      class Public
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_public(self)
        end
      end

      class MethodDefinition
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_method_definition(self)
        end
      end

      class AttrReader
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_attr_reader(self)
        end
      end

      class AttrWriter
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_attr_writer(self)
        end
      end

      class AttrAccessor
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_attr_accessor(self)
        end
      end

      class Include
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_include(self)
        end
      end

      class Prepend
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_prepend(self)
        end
      end

      class Extend
        extend T::Sig

        sig { params(visitor: RBS::AST::Visitor).void }
        def visit(visitor)
          visitor.visit_member_extend(self)
        end
      end
    end

    class Visitor
      extend T::Sig

      sig { params(node: Declarations::Global).void }
      def visit_declaration_global(node)
      end

      sig { params(node: Declarations::Class).void }
      def visit_declaration_class(node)
        visit_all(node.members)
      end

      sig { params(node: Declarations::Module).void }
      def visit_declaration_module(node)
        visit_all(node.members)
      end

      sig { params(node: Declarations::Constant).void }
      def visit_declaration_constant(node)
      end

      sig { params(node: Declarations::TypeAlias).void }
      def visit_declaration_type_alias(node)
      end

      sig { params(node: Declarations::Interface).void }
      def visit_declaration_interface(node)
        visit_all(node.members)
      end

      sig { params(node: Members::Alias).void }
      def visit_member_alias(node)
      end

      sig { params(node: Members::ClassInstanceVariable).void }
      def visit_member_class_instance_variable(node)
      end

      sig { params(node: Members::ClassVariable).void }
      def visit_member_class_variable(node)
      end

      sig { params(node: Members::InstanceVariable).void }
      def visit_member_instance_variable(node)
      end

      sig { params(node: Members::Private).void }
      def visit_member_private(node)
      end

      sig { params(node: Members::Public).void }
      def visit_member_public(node)
      end

      sig { params(node: Members::MethodDefinition).void }
      def visit_member_method_definition(node)
      end

      sig { params(node: Members::AttrReader).void }
      def visit_member_attr_reader(node)
      end

      sig { params(node: Members::AttrWriter).void }
      def visit_member_attr_writer(node)
      end

      sig { params(node: Members::AttrAccessor).void }
      def visit_member_attr_accessor(node)
      end

      sig { params(node: Members::Include).void }
      def visit_member_include(node)
      end

      sig { params(node: Members::Prepend).void }
      def visit_member_prepend(node)
      end

      sig { params(node: Members::Extend).void }
      def visit_member_extend(node)
      end

      sig { params(nodes: T::Enumerable[T.any(Members::Base, Declarations::Base)]).void }
      def visit_all(nodes)
        nodes.each do |node|
          visit(node)
        end
      end

      sig { params(node: T.any(Members::Base, Declarations::Base)).void }
      def visit(node)
        node.visit(self)
      end
    end
  end
end
