# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBI
    class Index < Visitor
      extend T::Sig
      include T::Enumerable

      sig { params(node: Node).returns(Index) }
      def self.index(*node)
        index = Index.new
        index.visit_all(node)
        index
      end

      sig { void }
      def initialize
        super()
        @index = T.let({}, T::Hash[String, T::Array[Node]])
      end

      sig { returns(T::Array[String]) }
      def keys
        @index.keys
      end

      sig { params(id: String).returns(T::Array[Node]) }
      def [](id)
        @index[id] ||= []
      end

      sig { params(node: T.all(Indexable, Node)).void }
      def index(node)
        node.index_ids.each { |id| self[id] << node }
      end

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        return unless node

        case node
        when Scope
          index(node)
          visit_all(node.nodes)
        when Tree
          visit_all(node.nodes)
        when Indexable
          index(node)
        end
      end
    end

    class Tree
      extend T::Sig

      sig { returns(Index) }
      def index
        Index.index(self)
      end
    end

    # A Node that can be refered to by a unique ID inside an index
    module Indexable
      extend T::Sig
      extend T::Helpers

      interface!

      # Unique IDs that refer to this node.
      #
      # Some nodes can have multiple ids, for example an attribute accessor matches the ID of the
      # getter and the setter.
      sig { abstract.returns(T::Array[String]) }
      def index_ids; end
    end

    class Scope
      extend T::Sig
      include Indexable

      sig { override.returns(T::Array[String]) }
      def index_ids
        [fully_qualified_name]
      end
    end

    class Const
      extend T::Sig
      include Indexable

      sig { override.returns(T::Array[String]) }
      def index_ids
        [fully_qualified_name]
      end
    end

    class Attr
      extend T::Sig
      include Indexable

      sig { override.returns(T::Array[String]) }
      def index_ids
        fully_qualified_names
      end
    end

    class Method
      extend T::Sig
      include Indexable

      sig { override.returns(T::Array[String]) }
      def index_ids
        [fully_qualified_name]
      end
    end

    class Include
      extend T::Sig
      include Indexable

      sig { override.returns(T::Array[String]) }
      def index_ids
        names.map { |name| "#{parent_scope&.fully_qualified_name}.include(#{name})" }
      end
    end

    class Extend
      extend T::Sig
      include Indexable

      sig { override.returns(T::Array[String]) }
      def index_ids
        names.map { |name| "#{parent_scope&.fully_qualified_name}.extend(#{name})" }
      end
    end

    class MixesInClassMethods
      extend T::Sig
      include Indexable

      sig { override.returns(T::Array[String]) }
      def index_ids
        names.map { |name| "#{parent_scope&.fully_qualified_name}.mixes_in_class_method(#{name})" }
      end
    end

    class Helper
      extend T::Sig
      include Indexable

      sig { override.returns(T::Array[String]) }
      def index_ids
        [to_s]
      end
    end

    class TStructConst
      extend T::Sig
      include Indexable

      sig { override.returns(T::Array[String]) }
      def index_ids
        fully_qualified_names
      end
    end

    class TStructProp
      extend T::Sig
      include Indexable

      sig { override.returns(T::Array[String]) }
      def index_ids
        fully_qualified_names
      end
    end

    class TEnumBlock
      extend T::Sig
      include Indexable

      sig { override.returns(T::Array[String]) }
      def index_ids
        [to_s]
      end
    end
  end
end
