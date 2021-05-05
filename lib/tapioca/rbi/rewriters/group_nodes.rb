# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBI
    module Rewriters
      class GroupNodes < Visitor
        extend T::Sig

        sig { override.params(node: T.nilable(Node)).void }
        def visit(node)
          return unless node

          case node
          when Tree
            kinds = node.nodes.map(&:group_kind)
            kinds.compact!
            kinds.uniq!

            groups = {}
            kinds.each { |kind| groups[kind] = Group.new(kind) }

            node.nodes.dup.each do |child|
              visit(child)
              child.detach
              groups[child.group_kind] << child
            end

            groups.each { |_, group| node << group }
          end
        end
      end
    end

    class Tree
      extend T::Sig

      sig { void }
      def group_nodes!
        visitor = Rewriters::GroupNodes.new
        visitor.visit(self)
      end
    end

    class Node
      extend T::Sig

      sig { returns(Group::Kind) }
      def group_kind
        case self
        when Include, Extend
          Group::Kind::Mixins
        when Helper
          Group::Kind::Helpers
        when TypeMember
          Group::Kind::TypeMembers
        when MixesInClassMethods
          Group::Kind::MixesInClassMethods
        when TStructField
          Group::Kind::TStructFields
        when TEnumBlock
          Group::Kind::TEnums
        when VisibilityGroup
          Group::Kind::Methods
        when Method
          if name == "initialize"
            Group::Kind::Inits
          else
            Group::Kind::Methods
          end
        when Scope, Const
          Group::Kind::Consts
        else
          raise "Unknown group for #{self}"
        end
      end
    end

    class Group < Tree
      extend T::Sig

      sig { returns(Kind) }
      attr_reader :kind

      sig { params(kind: Kind).void }
      def initialize(kind)
        super()
        @kind = kind
      end

      class Kind < T::Enum
        enums do
          Mixins              = new
          Helpers             = new
          TypeMembers         = new
          MixesInClassMethods = new
          TStructFields       = new
          TEnums              = new
          Inits               = new
          Methods             = new
          Consts              = new
        end
      end
    end
  end
end
