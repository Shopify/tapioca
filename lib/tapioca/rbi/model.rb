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

      sig { returns(T.nilable(Scope)) }
      def parent_scope
        parent = T.let(parent_tree, T.nilable(Tree))
        parent = parent.parent_tree until parent.is_a?(Scope) || parent.nil?
        parent
      end
    end

    class Comment < Node
      extend T::Helpers

      sig { returns(String) }
      attr_accessor :text

      sig { params(text: String, loc: T.nilable(Loc)).void }
      def initialize(text, loc: nil)
        super(loc: loc)
        @text = text
      end

      sig { params(other: Object).returns(T::Boolean) }
      def ==(other)
        return false unless other.is_a?(Comment)
        text == other.text
      end
    end

    class NodeWithComments < Node
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(T::Array[Comment]) }
      attr_accessor :comments

      sig { params(loc: T.nilable(Loc), comments: T::Array[Comment]).void }
      def initialize(loc: nil, comments: [])
        super(loc: loc)
        @comments = comments
      end
    end

    class Tree < NodeWithComments
      extend T::Sig

      sig { returns(T::Array[Node]) }
      attr_reader :nodes

      sig do
        params(
          loc: T.nilable(Loc),
          comments: T::Array[Comment],
          block: T.nilable(T.proc.params(tree: Tree).void)
        ).void
      end
      def initialize(loc: nil, comments: [], &block)
        super(loc: loc, comments: comments)
        @nodes = T.let([], T::Array[Node])
        block&.call(self)
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

      sig { abstract.returns(String) }
      def fully_qualified_name; end

      sig { override.returns(String) }
      def to_s
        fully_qualified_name
      end
    end

    class Module < Scope
      extend T::Sig

      sig { returns(String) }
      attr_accessor :name

      sig do
        params(
          name: String,
          loc: T.nilable(Loc),
          comments: T::Array[Comment],
          block: T.nilable(T.proc.params(mod: Module).void)
        ).void
      end
      def initialize(name, loc: nil, comments: [], &block)
        super(loc: loc, comments: comments) {}
        @name = name
        block&.call(self)
      end

      sig { override.returns(String) }
      def fully_qualified_name
        return name if name.start_with?("::")
        "#{parent_scope&.fully_qualified_name}::#{name}"
      end
    end

    class Class < Scope
      extend T::Sig

      sig { returns(String) }
      attr_accessor :name

      sig { returns(T.nilable(String)) }
      attr_accessor :superclass_name

      sig do
        params(
          name: String,
          superclass_name: T.nilable(String),
          loc: T.nilable(Loc),
          comments: T::Array[Comment],
          block: T.nilable(T.proc.params(klass: Class).void)
        ).void
      end
      def initialize(name, superclass_name: nil, loc: nil, comments: [], &block)
        super(loc: loc, comments: comments) {}
        @name = name
        @superclass_name = superclass_name
        block&.call(self)
      end

      sig { override.returns(String) }
      def fully_qualified_name
        return name if name.start_with?("::")
        "#{parent_scope&.fully_qualified_name}::#{name}"
      end
    end

    class SingletonClass < Scope
      extend T::Sig

      sig do
        params(
          loc: T.nilable(Loc),
          comments: T::Array[Comment],
          block: T.nilable(T.proc.params(klass: SingletonClass).void)
        ).void
      end
      def initialize(loc: nil, comments: [], &block)
        super(loc: loc, comments: comments) {}
        block&.call(self)
      end

      sig { override.returns(String) }
      def fully_qualified_name
        "#{parent_scope&.fully_qualified_name}::<self>"
      end
    end

    # Consts

    class Const < NodeWithComments
      extend T::Sig

      sig { returns(String) }
      attr_reader :name, :value

      sig { params(name: String, value: String, loc: T.nilable(Loc), comments: T::Array[Comment]).void }
      def initialize(name, value, loc: nil, comments: [])
        super(loc: loc, comments: comments)
        @name = name
        @value = value
      end

      sig { returns(String) }
      def fully_qualified_name
        return name if name.start_with?("::")
        "#{parent_scope&.fully_qualified_name}::#{name}"
      end

      sig { override.returns(String) }
      def to_s
        fully_qualified_name
      end
    end

    # Attributes

    class Attr < NodeWithComments
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(T::Array[Symbol]) }
      attr_accessor :names

      sig { returns(Visibility) }
      attr_accessor :visibility

      sig { returns(T::Array[Sig]) }
      attr_reader :sigs

      sig do
        params(
          name: Symbol,
          names: Symbol,
          visibility: Visibility,
          sigs: T::Array[Sig],
          loc: T.nilable(Loc),
          comments: T::Array[Comment]
        ).void
      end
      def initialize(name, *names, visibility: Visibility::Public, sigs: [], loc: nil, comments: [])
        super(loc: loc, comments: comments)
        @names = T.let([name, *names], T::Array[Symbol])
        @visibility = visibility
        @sigs = sigs
      end

      sig { abstract.returns(T::Array[String]) }
      def fully_qualified_names; end
    end

    class AttrAccessor < Attr
      extend T::Sig

      sig { override.returns(T::Array[String]) }
      def fully_qualified_names
        parent_name = parent_scope&.fully_qualified_name
        names.flat_map { |name| ["#{parent_name}##{name}", "#{parent_name}##{name}="] }
      end

      sig { override.returns(String) }
      def to_s
        symbols = names.map { |name| ":#{name}" }.join(", ")
        "#{parent_scope&.fully_qualified_name}.attr_accessor(#{symbols})"
      end
    end

    class AttrReader < Attr
      extend T::Sig

      sig { override.returns(T::Array[String]) }
      def fully_qualified_names
        parent_name = parent_scope&.fully_qualified_name
        names.map { |name| "#{parent_name}##{name}" }
      end

      sig { override.returns(String) }
      def to_s
        symbols = names.map { |name| ":#{name}" }.join(", ")
        "#{parent_scope&.fully_qualified_name}.attr_reader(#{symbols})"
      end
    end

    class AttrWriter < Attr
      extend T::Sig

      sig { override.returns(T::Array[String]) }
      def fully_qualified_names
        parent_name = parent_scope&.fully_qualified_name
        names.map { |name| "#{parent_name}##{name}=" }
      end

      sig { override.returns(String) }
      def to_s
        symbols = names.map { |name| ":#{name}" }.join(", ")
        "#{parent_scope&.fully_qualified_name}.attr_writer(#{symbols})"
      end
    end

    # Methods and args

    class Method < NodeWithComments
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
          loc: T.nilable(Loc),
          comments: T::Array[Comment]
        ).void
      end
      def initialize(
        name,
        params: [],
        is_singleton: false,
        visibility: Visibility::Public,
        sigs: [],
        loc: nil,
        comments: []
      )
        super(loc: loc, comments: comments)
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

      sig { returns(String) }
      def fully_qualified_name
        if is_singleton
          "#{parent_scope&.fully_qualified_name}::#{name}"
        else
          "#{parent_scope&.fully_qualified_name}##{name}"
        end
      end

      sig { override.returns(String) }
      def to_s
        "#{fully_qualified_name}(#{params.join(", ")})"
      end
    end

    class Param < NodeWithComments
      extend T::Sig

      sig { returns(String) }
      attr_reader :name

      sig { params(name: String, loc: T.nilable(Loc), comments: T::Array[Comment]).void }
      def initialize(name, loc: nil, comments: [])
        super(loc: loc, comments: comments)
        @name = name
      end

      sig { override.returns(String) }
      def to_s
        name
      end

      sig { params(other: T.nilable(Object)).returns(T::Boolean) }
      def ==(other)
        return false unless other.instance_of?(Param)
        name == T.cast(other, Param).name
      end
    end

    class OptParam < Param
      extend T::Sig

      sig { returns(String) }
      attr_reader :value

      sig { params(name: String, value: String, loc: T.nilable(Loc), comments: T::Array[Comment]).void }
      def initialize(name, value, loc: nil, comments: [])
        super(name, loc: loc, comments: comments)
        @value = value
      end

      sig { params(other: T.nilable(Object)).returns(T::Boolean) }
      def ==(other)
        return false unless other.instance_of?(OptParam)
        other = T.cast(other, OptParam)
        return false unless name == other.name
        value == other.value
      end
    end

    class RestParam < Param
      extend T::Sig

      sig { params(other: T.nilable(Object)).returns(T::Boolean) }
      def ==(other)
        return false unless other.instance_of?(RestParam)
        name == T.cast(other, RestParam).name
      end

      sig { override.returns(String) }
      def to_s
        "*#{name}"
      end
    end

    class KwParam < Param
      extend T::Sig

      sig { override.returns(String) }
      def to_s
        "#{name}:"
      end

      sig { params(other: T.nilable(Object)).returns(T::Boolean) }
      def ==(other)
        return false unless other.instance_of?(KwParam)
        name == T.cast(other, KwParam).name
      end
    end

    class KwOptParam < OptParam
      extend T::Sig

      sig { override.returns(String) }
      def to_s
        "#{name}:"
      end

      sig { params(other: T.nilable(Object)).returns(T::Boolean) }
      def ==(other)
        return false unless other.instance_of?(KwOptParam)
        other = T.cast(other, KwOptParam)
        return false unless name == other.name
        value == other.value
      end
    end

    class KwRestParam < Param
      extend T::Sig

      sig { override.returns(String) }
      def to_s
        "**#{name}:"
      end

      sig { params(other: T.nilable(Object)).returns(T::Boolean) }
      def ==(other)
        return false unless other.instance_of?(KwRestParam)
        name == T.cast(other, KwRestParam).name
      end
    end

    class BlockParam < Param
      extend T::Sig

      sig { override.returns(String) }
      def to_s
        "&#{name}"
      end

      sig { params(other: T.nilable(Object)).returns(T::Boolean) }
      def ==(other)
        return false unless other.instance_of?(BlockParam)
        name == T.cast(other, BlockParam).name
      end
    end

    # Mixins

    class Mixin < NodeWithComments
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(T::Array[String]) }
      attr_accessor :names

      sig { params(name: String, names: String, loc: T.nilable(Loc), comments: T::Array[Comment]).void }
      def initialize(name, *names, loc: nil, comments: [])
        super(loc: loc, comments: comments)
        @names = T.let([name, *names], T::Array[String])
      end
    end

    class Include < Mixin
      extend T::Sig

      sig { override.returns(String) }
      def to_s
        "#{parent_scope&.fully_qualified_name}.include(#{names.join(", ")})"
      end
    end

    class Extend < Mixin
      extend T::Sig

      sig { override.returns(String) }
      def to_s
        "#{parent_scope&.fully_qualified_name}.extend(#{names.join(", ")})"
      end
    end

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

      sig { params(other: Visibility).returns(T::Boolean) }
      def ==(other)
        visibility == other.visibility
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

      sig { returns(T.nilable(Symbol)) }
      attr_accessor :checked

      sig do
        params(
          params: T::Array[SigParam],
          return_type: T.nilable(String),
          is_abstract: T::Boolean,
          is_override: T::Boolean,
          is_overridable: T::Boolean,
          type_params: T::Array[String],
          checked: T.nilable(Symbol),
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
        checked: nil,
        loc: nil
      )
        super(loc: loc)
        @params = params
        @return_type = return_type
        @is_abstract = is_abstract
        @is_override = is_override
        @is_overridable = is_overridable
        @type_params = type_params
        @checked = checked
      end

      sig { params(param: SigParam).void }
      def <<(param)
        @params << param
      end

      sig { params(other: Object).returns(T::Boolean) }
      def ==(other)
        return false unless other.is_a?(Sig)
        params == other.params && return_type == other.return_type && is_abstract == other.is_abstract &&
          is_override == other.is_override && is_overridable == other.is_overridable &&
          type_params == other.type_params && checked == other.checked
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

      sig { params(other: Object).returns(T::Boolean) }
      def ==(other)
        other.is_a?(SigParam) && name == other.name && type == other.type
      end
    end

    # Sorbet's T::Struct

    class TStruct < Class
      extend T::Sig

      sig do
        params(
          name: String,
          loc: T.nilable(Loc),
          comments: T::Array[Comment],
          block: T.nilable(T.proc.params(klass: TStruct).void)
        ).void
      end
      def initialize(name, loc: nil, comments: [], &block)
        super(name, superclass_name: "::T::Struct", loc: loc, comments: comments) {}
        block&.call(self)
      end
    end

    class TStructField < NodeWithComments
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
          loc: T.nilable(Loc),
          comments: T::Array[Comment]
        ).void
      end
      def initialize(name, type, default: nil, loc: nil, comments: [])
        super(loc: loc, comments: comments)
        @name = name
        @type = type
        @default = default
      end

      sig { abstract.returns(T::Array[String]) }
      def fully_qualified_names; end
    end

    class TStructConst < TStructField
      extend T::Sig

      sig { override.returns(T::Array[String]) }
      def fully_qualified_names
        parent_name = parent_scope&.fully_qualified_name
        ["#{parent_name}##{name}"]
      end

      sig { override.returns(String) }
      def to_s
        "#{parent_scope&.fully_qualified_name}.const(:#{name})"
      end
    end

    class TStructProp < TStructField
      extend T::Sig

      sig { override.returns(T::Array[String]) }
      def fully_qualified_names
        parent_name = parent_scope&.fully_qualified_name
        ["#{parent_name}##{name}", "#{parent_name}##{name}="]
      end

      sig { override.returns(String) }
      def to_s
        "#{parent_scope&.fully_qualified_name}.prop(:#{name})"
      end
    end

    # Sorbet's T::Enum

    class TEnum < Class
      extend T::Sig

      sig do
        params(
          name: String,
          loc: T.nilable(Loc),
          comments: T::Array[Comment],
          block: T.nilable(T.proc.params(klass: TEnum).void)
        ).void
      end
      def initialize(name, loc: nil, comments: [], &block)
        super(name, superclass_name: "::T::Enum", loc: loc, comments: comments) {}
        block&.call(self)
      end
    end

    class TEnumBlock < NodeWithComments
      extend T::Sig

      sig { returns(T::Array[String]) }
      attr_reader :names

      sig { params(names: T::Array[String], loc: T.nilable(Loc), comments: T::Array[Comment]).void }
      def initialize(names = [], loc: nil, comments: [])
        super(loc: loc, comments: comments)
        @names = names
      end

      sig { returns(T::Boolean) }
      def empty?
        names.empty?
      end

      sig { params(name: String).void }
      def <<(name)
        @names << name
      end

      sig { override.returns(String) }
      def to_s
        "#{parent_scope&.fully_qualified_name}.enums"
      end
    end

    # Sorbet's misc.

    class Helper < NodeWithComments
      extend T::Helpers

      sig { returns(String) }
      attr_reader :name

      sig { params(name: String, loc: T.nilable(Loc), comments: T::Array[Comment]).void }
      def initialize(name, loc: nil, comments: [])
        super(loc: loc, comments: comments)
        @name = name
      end

      sig { override.returns(String) }
      def to_s
        "#{parent_scope&.fully_qualified_name}.#{name}!"
      end
    end

    class TypeMember < NodeWithComments
      extend T::Sig

      sig { returns(String) }
      attr_reader :name, :value

      sig { params(name: String, value: String, loc: T.nilable(Loc), comments: T::Array[Comment]).void }
      def initialize(name, value, loc: nil, comments: [])
        super(loc: loc, comments: comments)
        @name = name
        @value = value
      end

      sig { returns(String) }
      def fully_qualified_name
        return name if name.start_with?("::")
        "#{parent_scope&.fully_qualified_name}::#{name}"
      end

      sig { override.returns(String) }
      def to_s
        fully_qualified_name
      end
    end

    class MixesInClassMethods < Mixin
      extend T::Sig

      sig { override.returns(String) }
      def to_s
        "#{parent_scope&.fully_qualified_name}.mixes_in_class_methods(#{names.join(", ")})"
      end
    end
  end
end
