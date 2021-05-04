# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBI
    module Rewriters
      class NestNonPublicMethods < Visitor
        extend T::Sig

        sig { override.params(node: T.nilable(Node)).void }
        def visit(node)
          return unless node

          case node
          when Tree
            public_group = VisibilityGroup.new(Visibility::Public)
            protected_group = VisibilityGroup.new(Visibility::Protected)
            private_group = VisibilityGroup.new(Visibility::Private)

            node.nodes.dup.each do |child|
              visit(child)
              next unless child.is_a?(Method)
              child.detach
              case child.visibility
              when Visibility::Protected
                protected_group << child
              when Visibility::Private
                private_group << child
              else
                public_group << child
              end
            end

            node << public_group unless public_group.empty?
            node << protected_group unless protected_group.empty?
            node << private_group unless private_group.empty?
          end
        end
      end
    end

    class Tree
      extend T::Sig

      sig { void }
      def nest_non_public_methods!
        visitor = Rewriters::NestNonPublicMethods.new
        visitor.visit(self)
      end
    end

    class VisibilityGroup < Tree
      extend T::Sig

      sig { returns(Visibility) }
      attr_reader :visibility

      sig { params(visibility: Visibility).void }
      def initialize(visibility)
        super()
        @visibility = visibility
      end
    end
  end
end
