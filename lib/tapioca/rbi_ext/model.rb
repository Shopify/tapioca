# typed: strict
# frozen_string_literal: true

module RBI
  class Tree
    extend T::Sig

    sig { params(constant: ::Module, block: T.nilable(T.proc.params(scope: Scope).void)).returns(Scope) }
    def create_path(constant, &block)
      constant_name = Tapioca::Runtime::Reflection.name_of(constant)
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

    sig do
      params(
        name: String,
        comments: T::Array[RBI::Comment],
        block: T.nilable(T.proc.params(scope: Scope).void),
      ).returns(Scope)
    end
    def create_module(name, comments: [], &block)
      T.cast(create_node(RBI::Module.new(name, comments: comments)), RBI::Scope).tap do |node|
        block&.call(node)
      end
    end

    sig do
      params(
        name: String,
        superclass_name: T.nilable(String),
        comments: T::Array[RBI::Comment],
        block: T.nilable(T.proc.params(scope: RBI::Scope).void),
      ).returns(Scope)
    end
    def create_class(name, superclass_name: nil, comments: [], &block)
      T.cast(
        create_node(RBI::Class.new(name, superclass_name: superclass_name, comments: comments)),
        RBI::Scope,
      ).tap do |node|
        block&.call(node)
      end
    end

    sig { params(name: String, value: String, comments: T::Array[RBI::Comment]).void }
    def create_constant(name, value:, comments: [])
      create_node(RBI::Const.new(name, value, comments: comments))
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

    sig do
      params(
        name: String,
        type: String,
        variance: Symbol,
        fixed: T.nilable(String),
        upper: T.nilable(String),
        lower: T.nilable(String),
      ).void
    end
    def create_type_variable(name, type:, variance: :invariant, fixed: nil, upper: nil, lower: nil)
      value = Tapioca::RBIHelper.serialize_type_variable(type, variance, fixed, upper, lower)
      create_node(RBI::TypeMember.new(name, value))
    end

    sig do
      params(
        name: String,
        parameters: T::Array[TypedParam],
        return_type: String,
        class_method: T::Boolean,
        visibility: RBI::Visibility,
        comments: T::Array[RBI::Comment],
      ).void
    end
    def create_method(name, parameters: [], return_type: "T.untyped", class_method: false, visibility: RBI::Public.new,
      comments: [])
      return unless Tapioca::RBIHelper.valid_method_name?(name)

      sig = RBI::Sig.new(return_type: return_type)
      method = RBI::Method.new(
        name,
        sigs: [sig],
        is_singleton: class_method,
        visibility: visibility,
        comments: comments,
      )
      parameters.each do |param|
        method << param.param
        sig << RBI::SigParam.new(param.param.name, param.type)
      end
      self << method
    end

    sig { params(new_name: String, old_name: String).returns(RBI::Send) }
    def create_method_alias(new_name, old_name)
      alias_def = RBI::Send.new("alias") do |node|
        node << RBI::Arg.new("#{new_name} #{old_name}")
      end
      self << alias_def
      alias_def
    end

    private

    sig { returns(T::Hash[String, RBI::Node]) }
    def nodes_cache
      @nodes_cache ||= T.let({}, T.nilable(T::Hash[String, Node]))
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
end
