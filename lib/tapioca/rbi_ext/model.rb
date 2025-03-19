# typed: strict
# frozen_string_literal: true

module RBI
  class Tree
    extend T::Sig

    #: (::Module constant) ?{ (Scope scope) -> void } -> Scope
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

    #: (String name) ?{ (Scope scope) -> void } -> Scope
    def create_module(name, &block)
      T.cast(create_node(RBI::Module.new(name)), RBI::Scope).tap do |node|
        block&.call(node)
      end
    end

    #: (String name, ?superclass_name: String?) ?{ (RBI::Scope scope) -> void } -> Scope
    def create_class(name, superclass_name: nil, &block)
      T.cast(create_node(RBI::Class.new(name, superclass_name: superclass_name)), RBI::Scope).tap do |node|
        block&.call(node)
      end
    end

    #: (String name, value: String) -> void
    def create_constant(name, value:)
      create_node(RBI::Const.new(name, value))
    end

    #: (String name) -> void
    def create_include(name)
      create_node(RBI::Include.new(name))
    end

    #: (String name) -> void
    def create_extend(name)
      create_node(RBI::Extend.new(name))
    end

    #: (String name) -> void
    def create_mixes_in_class_methods(name)
      create_node(RBI::MixesInClassMethods.new(name))
    end

    #: (String name, type: String, ?variance: Symbol, ?fixed: String?, ?upper: String?, ?lower: String?) -> void
    def create_type_variable(name, type:, variance: :invariant, fixed: nil, upper: nil, lower: nil)
      value = Tapioca::RBIHelper.serialize_type_variable(type, variance, fixed, upper, lower)
      create_node(RBI::TypeMember.new(name, value))
    end

    #: (String name, ?parameters: Array[TypedParam], ?return_type: String?, ?class_method: bool, ?visibility: RBI::Visibility, ?comments: Array[RBI::Comment]) ?{ (RBI::Method node) -> void } -> void
    def create_method(name, parameters: [], return_type: nil, class_method: false, visibility: RBI::Public.new,
      comments: [], &block)
      return unless Tapioca::RBIHelper.valid_method_name?(name)

      sigs = []

      if !block || !parameters.empty? || return_type
        # If there is no block, and the params and return type have not been supplied, then
        # we create a single signature with the given parameters and return type
        params = parameters.map { |param| RBI::SigParam.new(param.param.name.to_s, param.type) }
        sigs << RBI::Sig.new(params: params, return_type: return_type || "T.untyped")
      end

      method = RBI::Method.new(
        name,
        sigs: sigs,
        params: parameters.map(&:param),
        is_singleton: class_method,
        visibility: visibility,
        comments: comments,
        &block
      )
      self << method
    end

    private

    #: -> Hash[String, RBI::Node]
    def nodes_cache
      @nodes_cache ||= {} #: Hash[String, Node]?
    end

    #: (RBI::Node node) -> RBI::Node
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
