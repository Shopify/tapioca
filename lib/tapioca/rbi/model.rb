# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBI
    class Node
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(T.nilable(Tree)) }
      attr_accessor :parent_tree

      sig { returns(T.nilable(Loc)) }
      attr_accessor :loc

      sig { params(loc: T.nilable(Loc)).void }
      def initialize(loc: nil)
        @parent_tree = nil
        @loc = loc
      end

      sig { void }
      def detach
        tree = parent_tree
        return unless tree
        tree.nodes.delete(self)
        self.parent_tree = nil
      end
    end

    class Tree < Node
      extend T::Sig

      sig { returns(T::Array[Node]) }
      attr_reader :nodes

      sig { params(loc: T.nilable(Loc)).void }
      def initialize(loc: nil)
        super(loc: loc)
        @nodes = T.let([], T::Array[Node])
      end

      sig { params(node: Node).void }
      def <<(node)
        node.parent_tree = self
        @nodes << node
      end

      sig { returns(T::Boolean) }
      def empty?
        nodes.empty?
      end
    end

    # Scopes

    class Scope < Tree
      extend T::Helpers

      abstract!
    end

    class Module < Scope
      extend T::Sig

      sig { returns(String) }
      attr_accessor :name

      sig { params(name: String, loc: T.nilable(Loc)).void }
      def initialize(name, loc: nil)
        super(loc: loc)
        @name = name
      end
    end

    class Class < Scope
      extend T::Sig

      sig { returns(String) }
      attr_accessor :name

      sig { returns(T.nilable(String)) }
      attr_accessor :superclass_name

      sig { params(name: String, superclass_name: T.nilable(String), loc: T.nilable(Loc)).void }
      def initialize(name, superclass_name: nil, loc: nil)
        super(loc: loc)
        @name = name
        @superclass_name = superclass_name
      end
    end

    class SingletonClass < Scope
      extend T::Sig

      sig { params(loc: T.nilable(Loc)).void }
      def initialize(loc: nil)
        super(loc: loc)
      end
    end

    # Consts

    class Const < Node
      extend T::Sig

      sig { returns(String) }
      attr_reader :name, :value

      sig { params(name: String, value: String, loc: T.nilable(Loc)).void }
      def initialize(name, value, loc: nil)
        super(loc: loc)
        @name = name
        @value = value
      end
    end

    # Methods and args

    class Method < Node
      extend T::Sig

      sig { returns(String) }
      attr_accessor :name

      sig { returns(T::Array[Param]) }
      attr_reader :params

      sig { returns(T::Boolean) }
      attr_accessor :is_singleton

      sig { returns(Visibility) }
      attr_accessor :visibility

      sig { returns(T::Array[Sig]) }
      attr_accessor :sigs

      sig do
        params(
          name: String,
          params: T::Array[Param],
          is_singleton: T::Boolean,
          visibility: Visibility,
          sigs: T::Array[Sig],
          loc: T.nilable(Loc)
        ).void
      end
      def initialize(name, params: [], is_singleton: false, visibility: Visibility::Public, sigs: [], loc: nil)
        super(loc: loc)
        @name = name
        @params = params
        @is_singleton = is_singleton
        @visibility = visibility
        @sigs = sigs
      end

      sig { params(param: Param).void }
      def <<(param)
        @params << param
      end
    end

    class Param < Node
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { params(name: String, loc: T.nilable(Loc)).void }
      def initialize(name, loc: nil)
        super(loc: loc)
        @name = name
      end
    end

    class OptParam < Param
      extend T::Sig

      sig { returns(String) }
      attr_reader :value

      sig { params(name: String, value: String, loc: T.nilable(Loc)).void }
      def initialize(name, value, loc: nil)
        super(name, loc: loc)
        @value = value
      end
    end

    class RestParam < Param; end
    class KwParam < Param; end
    class KwOptParam < OptParam; end
    class KwRestParam < Param; end
    class BlockParam < Param; end

    # Mixins

    class Mixin < Node
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(String) }
      attr_reader :name

      sig { params(name: String, loc: T.nilable(Loc)).void }
      def initialize(name, loc: nil)
        super(loc: loc)
        @name = name
      end
    end

    class Include < Mixin; end
    class Extend < Mixin; end

    # Visibility

    class Visibility < Node
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(Symbol) }
      attr_reader :visibility

      sig { params(visibility: Symbol, loc: T.nilable(Loc)).void }
      def initialize(visibility, loc: nil)
        super(loc: loc)
        @visibility = visibility
      end

      sig { returns(T::Boolean) }
      def public?
        visibility == :public
      end

      Public = T.let(Visibility.new(:public), Visibility)
      Protected = T.let(Visibility.new(:protected), Visibility)
      Private = T.let(Visibility.new(:private), Visibility)
    end

    # Sorbet's sigs

    class Sig < Node
      extend T::Sig

      sig { returns(T::Array[SigParam]) }
      attr_reader :params

      sig { returns(T.nilable(String)) }
      attr_accessor :return_type

      sig { returns(T::Boolean) }
      attr_accessor :is_abstract, :is_override, :is_overridable

      sig { returns(T::Array[String]) }
      attr_reader :type_params

      sig do
        params(
          params: T::Array[SigParam],
          return_type: T.nilable(String),
          is_abstract: T::Boolean,
          is_override: T::Boolean,
          is_overridable: T::Boolean,
          type_params: T::Array[String],
          loc: T.nilable(Loc)
        ).void
      end
      def initialize(
        params: [],
        return_type: nil,
        is_abstract: false,
        is_override: false,
        is_overridable: false,
        type_params: [],
        loc: nil
      )
        super(loc: loc)
        @params = params
        @return_type = return_type
        @is_abstract = is_abstract
        @is_override = is_override
        @is_overridable = is_overridable
        @type_params = type_params
      end

      sig { params(param: SigParam).void }
      def <<(param)
        @params << param
      end
    end

    class SigParam < Node
      extend T::Sig

      sig { returns(String) }
      attr_reader :name, :type

      sig { params(name: String, type: String, loc: T.nilable(Loc)).void }
      def initialize(name, type, loc: nil)
        super(loc: loc)
        @name = name
        @type = type
      end
    end

    # Sorbet's T::Struct

    class TStruct < Class
      extend T::Sig

      sig { params(name: String, loc: T.nilable(Loc)).void }
      def initialize(name, loc: nil)
        super(name, superclass_name: "::T::Struct", loc: loc)
      end
    end

    class TStructField < Node
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(String) }
      attr_accessor :name, :type

      sig { returns(T.nilable(String)) }
      attr_accessor :default

      sig do
        params(
          name: String,
          type: String,
          default: T.nilable(String),
          loc: T.nilable(Loc)
        ).void
      end
      def initialize(name, type, default: nil, loc: nil)
        super(loc: loc)
        @name = name
        @type = type
        @default = default
      end
    end

    class TStructProp < TStructField; end
    class TStructConst < TStructField; end

    # Sorbet's T::Enum

    class TEnum < Class
      extend T::Sig

      sig { params(name: String, loc: T.nilable(Loc)).void }
      def initialize(name, loc: nil)
        super(name, superclass_name: "::T::Enum", loc: loc)
      end
    end

    class TEnumBlock < Node
      extend T::Sig

      sig { returns(T::Array[String]) }
      attr_reader :names

      sig { params(names: T::Array[String], loc: T.nilable(Loc)).void }
      def initialize(names = [], loc: nil)
        super(loc: loc)
        @names = names
      end

      sig { returns(T::Boolean) }
      def empty?
        names.empty?
      end
    end

    # Sorbet's misc.

    class Helper < Node
      extend T::Helpers

      sig { returns(String) }
      attr_reader :name

      sig { params(name: String, loc: T.nilable(Loc)).void }
      def initialize(name, loc: nil)
        super(loc: loc)
        @name = name
      end
    end

    class TypeMember < Node
      extend T::Sig

      sig { returns(String) }
      attr_reader :name, :value

      sig { params(name: String, value: String, loc: T.nilable(Loc)).void }
      def initialize(name, value, loc: nil)
        super(loc: loc)
        @name = name
        @value = value
      end
    end

    class MixesInClassMethods < Mixin; end
  end
end
