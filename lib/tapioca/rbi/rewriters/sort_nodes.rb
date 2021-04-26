# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBI
    module Rewriters
      class SortNodes < Visitor
        extend T::Sig

        sig { override.params(node: T.nilable(Node)).void }
        def visit(node)
          return unless node.is_a?(Tree)
          visit_all(node.nodes)
          node.nodes.sort! do |a, b|
            res = node_rank(a) <=> node_rank(b)
            res = node_name(a) <=> node_name(b) if res == 0
            res || 0
          end
        end

        private

        sig { params(node: Node).returns(Integer) }
        def node_rank(node)
          case node
          when Group                then kind_rank(node.kind)
          when Include              then 0
          when Extend               then 1
          when Helper               then 2
          when TypeMember           then 3
          when MixesInClassMethods  then 4
          when TStructField         then 5
          when TEnumBlock           then 6
          when Method
            if node.name == "initialize"
              7
            else
              8
            end
          when Scope, Const then 9
          else
            10
          end
        end

        sig { params(kind: Group::Kind).returns(Integer) }
        def kind_rank(kind)
          case kind
          when Group::Kind::Includes      then 0
          when Group::Kind::Extends       then 1
          when Group::Kind::Helpers       then 2
          when Group::Kind::TypeMembers   then 3
          when Group::Kind::Mixes         then 4
          when Group::Kind::TStructFields then 5
          when Group::Kind::TEnums        then 6
          when Group::Kind::Inits         then 7
          when Group::Kind::Methods       then 8
          when Group::Kind::Consts        then 9
          else
            T.absurd(kind)
          end
        end

        sig { params(node: Node).returns(T.nilable(String)) }
        def node_name(node)
          case node
          when Module, Class, Const, Method, Helper, TStructField
            node.name
          end
        end
      end
    end

    class Tree
      extend T::Sig

      sig { void }
      def sort_nodes!
        visitor = Rewriters::SortNodes.new
        visitor.visit(self)
      end
    end
  end
end
