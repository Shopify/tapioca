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
          original_order = node.nodes.map.with_index.to_h
          node.nodes.sort! do |a, b|
            res = node_rank(a) <=> node_rank(b)
            res = node_name(a) <=> node_name(b) if res == 0
            res = (original_order[a] || 0) <=> (original_order[b] || 0) if res == 0
            res || 0
          end
        end

        private

        sig { params(node: Node).returns(Integer) }
        def node_rank(node)
          case node
          when Group                then group_rank(node.kind)
          when Include, Extend      then 10
          when Helper               then 20
          when TypeMember           then 30
          when MixesInClassMethods  then 40
          when TStructField         then 50
          when TEnumBlock           then 60
          when Method
            if node.name == "initialize"
              71
            elsif !node.is_singleton
              72
            else
              73
            end
          when Scope, Const then 80
          else
            100
          end
        end

        sig { params(kind: Group::Kind).returns(Integer) }
        def group_rank(kind)
          case kind
          when Group::Kind::Mixins              then 0
          when Group::Kind::Helpers             then 1
          when Group::Kind::TypeMembers         then 2
          when Group::Kind::MixesInClassMethods then 3
          when Group::Kind::TStructFields       then 4
          when Group::Kind::TEnums              then 5
          when Group::Kind::Inits               then 6
          when Group::Kind::Methods             then 7
          when Group::Kind::Consts              then 8
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
