# typed: strict
# frozen_string_literal: true

require "rbi"

module RBI
  class FileWithConflicts < File
    extend T::Sig

    sig do
      params(
        strictness: T.nilable(String),
        comments: T::Array[RBI::Comment],
        block: T.nilable(T.proc.params(file: RBI::FileWithConflicts).void)
      ).void
    end
    def initialize(strictness: T.unsafe(nil), comments: T.unsafe(nil), &block)
      @conflicts = T.let([], T::Array[RBI::Rewriters::Merge::Conflict])
      super
    end

    sig { returns(String) }
    def transformed_string
      transform_rbi!
      string
    end

    sig { void }
    def transform_rbi!
      root.nest_singleton_methods!
      root.nest_non_public_methods!
      root.group_nodes!
      root.sort_nodes!
    end

    sig do
      params(
        rbi: RBI::Tree,
        keep: RBI::Rewriters::Merge::Keep
      ).void
    end
    def merge_with(rbi, keep: RBI::Rewriters::Merge::Keep::LEFT)
      root.nest_singleton_methods!
      rbi.nest_singleton_methods!
      merger = RBI::Rewriters::Merge.new
      merger.merge(root)
      @conflicts |= merger.merge(rbi)

      merger = RBI::Rewriters::Merge.new(keep: keep)
      merger.merge(root)
      merger.merge(rbi)
      root.nodes.replace(merger.tree.nodes)
      root.nodes.each { |node| node.parent_tree = root }
      self.comments = merger.tree.comments
    end


    sig { returns(T::Array[RBI::Rewriters::Merge::Conflict]) }
    attr_reader :conflicts
  end

  class Tree
    extend T::Sig

    sig { params(constant: ::Module, block: T.nilable(T.proc.params(scope: Scope).void)).void }
    def create_path(constant, &block)
      constant_name = Tapioca::Reflection.name_of(constant)
      raise "given constant does not have a name" unless constant_name

      instance = ::Module.const_get(constant_name)
      case instance
      when ::Class
        create_class(constant.to_s, &block)
      when ::Module
        create_module(constant.to_s, &block)
      else
        raise "unexpected type: #{constant_name} is a #{instance.class}"
      end
    end

    sig { params(name: String, block: T.nilable(T.proc.params(scope: Scope).void)).void }
    def create_module(name, &block)
      node = create_node(RBI::Module.new(name))
      block&.call(T.cast(node, RBI::Scope))
    end

    sig do
      params(
        name: String,
        superclass_name: T.nilable(String),
        block: T.nilable(T.proc.params(scope: RBI::Scope).void)
      ).void
    end
    def create_class(name, superclass_name: nil, &block)
      node = create_node(RBI::Class.new(name, superclass_name: superclass_name))
      block&.call(T.cast(node, RBI::Scope))
    end

    sig { params(name: String, value: String).void }
    def create_constant(name, value:)
      create_node(RBI::Const.new(name, value))
    end

    sig { params(name: String).void }
    def create_include(name)
      create_node(RBI::Include.new(name))
    end

    sig { params(name: String).void }
    def create_extend(name)
      create_node(RBI::Extend.new(name))
    end

    sig { params(name: String).void }
    def create_mixes_in_class_methods(name)
      create_node(RBI::MixesInClassMethods.new(name))
    end

    sig { params(name: String, value: String).void }
    def create_type_member(name, value: "type_member")
      create_node(RBI::TypeMember.new(name, value))
    end

    sig do
      params(
        name: String,
        parameters: T::Array[TypedParam],
        return_type: String,
        class_method: T::Boolean
      ).void
    end
    def create_method(name, parameters: [], return_type: "T.untyped", class_method: false)
      return unless valid_method_name?(name)

      sig = RBI::Sig.new(return_type: return_type)
      method = RBI::Method.new(name, sigs: [sig], is_singleton: class_method)
      parameters.each do |param|
        method << param.param
        sig << RBI::SigParam.new(param.param.name, param.type)
      end
      self << method
    end

    private

    SPECIAL_METHOD_NAMES = T.let(
      ["!", "~", "+@", "**", "-@", "*", "/", "%", "+", "-", "<<", ">>", "&", "|", "^", "<", "<=", "=>", ">", ">=",
       "==", "===", "!=", "=~", "!~", "<=>", "[]", "[]=", "`"].freeze,
      T::Array[String]
    )

    sig { params(name: String).returns(T::Boolean) }
    def valid_method_name?(name)
      return true if SPECIAL_METHOD_NAMES.include?(name)
      !!name.match(/^[a-zA-Z_][[:word:]]*[?!=]?$/)
    end

    sig { returns(T::Hash[String, RBI::Node]) }
    def nodes_cache
      T.must(@nodes_cache ||= T.let({}, T.nilable(T::Hash[String, Node])))
    end

    sig { params(node: RBI::Node).returns(RBI::Node) }
    def create_node(node)
      cached = nodes_cache[node.to_s]
      return cached if cached
      nodes_cache[node.to_s] = node
      self << node
      node
    end
  end

  class TypedParam < T::Struct
    const :param, RBI::Param
    const :type, String
  end

  class MergeResult < T::Struct
    const :tree, RBI::Tree
    const :conflicts, T::Array[RBI::Rewriters::Merge::Conflict]
  end
end
