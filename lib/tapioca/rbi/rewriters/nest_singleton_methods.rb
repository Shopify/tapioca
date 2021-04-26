# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBI
    module Rewriters
      class NestSingletonMethods < Visitor
        extend T::Sig

        sig { override.params(node: T.nilable(Node)).void }
        def visit(node)
          return unless node

          case node
          when Tree
            singleton_class = SingletonClass.new

            node.nodes.dup.each do |child|
              visit(child)
              next unless child.is_a?(Method) && child.is_singleton
              child.detach
              child.is_singleton = false
              singleton_class << child
            end

            node << singleton_class unless singleton_class.empty?
          end
        end
      end
    end

    class Tree
      extend T::Sig

      sig { void }
      def nest_singleton_methods!
        visitor = Rewriters::NestSingletonMethods.new
        visitor.visit(self)
      end
    end
  end
end
