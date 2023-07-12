# typed: strict
# frozen_string_literal: true

module Tapioca
  class RBIGenerator
    extend T::Sig
    include Runtime::Reflection
    include RBIHelper

    sig { params(include_doc: T::Boolean).void }
    def initialize(include_doc: false)
      @root = T.let(RBI::Tree.new, RBI::Tree)
      @seen = T.let(Set.new, T::Set[String])
      @events = T.let([], T::Array[Gem::Event])
      @alias_namespace = T.let(Set.new, T::Set[String])
      @node_listeners = T.let([], T::Array[Gem::Listeners::Base])
      @node_listeners << Gem::Listeners::SorbetTypeVariables.new(self)
      @node_listeners << Gem::Listeners::Mixins.new(self)
      @node_listeners << Gem::Listeners::DynamicMixins.new(self)
      @node_listeners << Gem::Listeners::Methods.new(self)
      @node_listeners << Gem::Listeners::SorbetHelpers.new(self)
      @node_listeners << Gem::Listeners::SorbetEnums.new(self)
      @node_listeners << Gem::Listeners::SorbetProps.new(self)
      @node_listeners << Gem::Listeners::SorbetRequiredAncestors.new(self)
      @node_listeners << Gem::Listeners::SorbetSignatures.new(self)
      @node_listeners << Gem::Listeners::Subconstants.new(self)
      @node_listeners << Gem::Listeners::YardDoc.new(self) if include_doc
      @node_listeners << Gem::Listeners::ForeignConstants.new(self)
      @node_listeners << Gem::Listeners::RemoveEmptyPayloadScopes.new(self)
    end

    sig { returns(RBI::Tree) }
    def compile
      dispatch(next_event) until @events.empty?
      @root
    end

    sig { params(symbol: String).void }
    def push_symbol(symbol)
      @events << Gem::SymbolFound.new(symbol)
    end

    sig { params(symbol: String, constant: BasicObject).void.checked(:never) }
    def push_constant(symbol, constant)
      @events << Gem::ConstantFound.new(symbol, constant)
    end

    sig { params(symbol: String, constant: Module).void.checked(:never) }
    def push_foreign_constant(symbol, constant)
      @events << Gem::ForeignConstantFound.new(symbol, constant)
    end

    sig { params(symbol: String, constant: Module, node: RBI::Const).void.checked(:never) }
    def push_const(symbol, constant, node)
      @events << Gem::ConstNodeAdded.new(symbol, constant, node)
    end

    sig do
      params(symbol: String, constant: Module, node: RBI::Scope).void.checked(:never)
    end
    def push_scope(symbol, constant, node)
      @events << Gem::ScopeNodeAdded.new(symbol, constant, node)
    end

    sig do
      params(symbol: String, constant: Module, node: RBI::Scope).void.checked(:never)
    end
    def push_foreign_scope(symbol, constant, node)
      @events << Gem::ForeignScopeNodeAdded.new(symbol, constant, node)
    end

    sig do
      params(
        symbol: String,
        constant: Module,
        node: RBI::Method,
        signature: T.untyped,
        parameters: T::Array[[Symbol, String]]
      ).void.checked(:never)
    end
    def push_method(symbol, constant, node, signature, parameters)
      @events << Gem::MethodNodeAdded.new(symbol, constant, node, signature, parameters)
    end

    private

    sig { returns(Gem::Event) }
    def next_event
      T.must(@events.shift)
    end

    sig { params(event: Gem::Event).void }
    def dispatch(event)
      case event
      when Gem::SymbolFound
        on_symbol(event)
      when Gem::ConstantFound
        on_constant(event)
      when Gem::NodeAdded
        on_node(event)
      else
        raise "Unsupported event #{event.class}"
      end
    end

    sig { params(event: Gem::SymbolFound).void }
    def on_symbol(event)
      symbol = event.symbol.delete_prefix("::")
      return if symbol_in_payload?(symbol) && !@bootstrap_symbols.include?(symbol)

      constant = constantize(symbol)
      push_constant(symbol, constant) if constant
    end

    sig { params(event: Gem::ConstantFound).void.checked(:never) }
    def on_constant(event)
      name = event.symbol

      return if name.strip.empty?
      return if name.start_with?("#<")
      return if name.downcase == name
      return if alias_namespaced?(name)
      return if seen?(name)

      return if T::Enum === event.constant # T::Enum instances are defined via `compile_enums`

      mark_seen(name)

      if event.is_a?(Gem::ForeignConstantFound)
        compile_foreign_constant(name, event.constant)
      else
        compile_constant(name, event.constant)
      end
    end

    sig { params(event: Gem::NodeAdded).void }
    def on_node(event)
      @node_listeners.each { |listener| listener.dispatch(event) }
    end

    # Compile

    sig { params(symbol: String, constant: Module).void }
    def compile_foreign_constant(symbol, constant)
      compile_module(symbol, constant, foreign_constant: true)
    end

    sig { params(symbol: String, constant: BasicObject).void.checked(:never) }
    def compile_constant(symbol, constant)
      case constant
      when Module
        if name_of(constant) != symbol
          compile_alias(symbol, constant)
        else
          compile_module(symbol, constant)
        end
      else
        compile_object(symbol, constant)
      end
    end

    sig { params(name: String, constant: Module).void }
    def compile_alias(name, constant)
      return if symbol_in_payload?(name)

      target = name_of(constant)
      # If target has no name, let's make it an anonymous class or module with `Class.new` or `Module.new`
      target = "#{constant.class}.new" unless target

      add_to_alias_namespace(name)

      return if IGNORED_SYMBOLS.include?(name)

      node = RBI::Const.new(name, target)
      push_const(name, constant, node)
      @root << node
    end

    sig { params(name: String, value: BasicObject).void.checked(:never) }
    def compile_object(name, value)
      return if symbol_in_payload?(name)

      klass = class_of(value)

      klass_name = if klass == ObjectSpace::WeakMap
        # WeakMap is an implicit generic with one type variable
        "ObjectSpace::WeakMap[T.untyped]"
      elsif T::Generic === klass
        generic_name_of(klass)
      else
        name_of(klass)
      end

      if klass_name == "T::Private::Types::TypeAlias"
        type_alias = sanitize_signature_types(T.unsafe(value).aliased_type.to_s)
        node = RBI::Const.new(name, "T.type_alias { #{type_alias} }")
        push_const(name, klass, node)
        @root << node
        return
      end

      return if klass_name&.start_with?("T::Types::", "T::Private::")

      type_name = klass_name || "T.untyped"
      node = RBI::Const.new(name, "T.let(T.unsafe(nil), #{type_name})")
      push_const(name, klass, node)
      @root << node
    end

    sig { params(name: String, constant: Module, foreign_constant: T::Boolean).void }
    def compile_module(name, constant, foreign_constant: false)
      return unless defined_in_gem?(constant, strict: false) || foreign_constant
      return if Tapioca::TypeVariableModule === constant

      scope =
        if constant.is_a?(Class)
          superclass = compile_superclass(constant)
          RBI::Class.new(name, superclass_name: superclass)
        else
          RBI::Module.new(name)
        end

      if foreign_constant
        push_foreign_scope(name, constant, scope)
      else
        push_scope(name, constant, scope)
      end

      @root << scope
    end

    sig { params(constant: Class).returns(T.nilable(String)) }
    def compile_superclass(constant)
      superclass = T.let(nil, T.nilable(Class)) # rubocop:disable Lint/UselessAssignment

      while (superclass = superclass_of(constant))
        constant_name = name_of(constant)
        constant = superclass

        # Some types have "themselves" as their superclass
        # which can happen via:
        #
        # class A < Numeric; end
        # A = Class.new(A)
        # A.superclass #=> A
        #
        # We compare names here to make sure we skip those
        # superclass instances and walk up the chain.
        #
        # The name comparison is against the name of the constant
        # resolved from the name of the superclass, since
        # this is also possible:
        #
        # B = Class.new
        # class A < B; end
        # B = A
        # A.superclass.name #=> "B"
        # B #=> A
        superclass_name = name_of(superclass)
        next unless superclass_name

        resolved_superclass = constantize(superclass_name)
        next unless Module === resolved_superclass
        next if name_of(resolved_superclass) == constant_name

        # We found a suitable superclass
        break
      end

      return if superclass == ::Object || superclass == ::Delegator
      return if superclass.nil?

      name = name_of(superclass)
      return if name.nil? || name.empty?

      push_symbol(name)

      "::#{name}"
    end

    sig { params(constant: Module).returns(T::Array[String]) }
    def get_file_candidates(constant)
      wrapped_module = Pry::WrappedModule.new(constant)

      wrapped_module.candidates.map(&:file).to_a.compact
    rescue ArgumentError, NameError
      []
    end

    sig { params(name: String).void }
    def add_to_alias_namespace(name)
      @alias_namespace.add("#{name}::")
    end

    sig { params(name: String).returns(T::Boolean) }
    def alias_namespaced?(name)
      @alias_namespace.any? do |namespace|
        name.start_with?(namespace)
      end
    end

    sig { params(name: String).void }
    def mark_seen(name)
      @seen.add(name)
    end

    sig { params(name: String).returns(T::Boolean) }
    def seen?(name)
      @seen.include?(name)
    end

    sig { params(constant: T.all(Module, T::Generic)).returns(String) }
    def generic_name_of(constant)
      type_name = T.must(constant.name)
      return type_name if type_name =~ /\[.*\]$/

      type_variables = Runtime::GenericTypeRegistry.lookup_type_variables(constant)
      return type_name unless type_variables

      type_variable_names = type_variables.map { "T.untyped" }.join(", ")

      "#{type_name}[#{type_variable_names}]"
    end

    sig { params(constant: Module, class_name: T.nilable(String)).returns(T.nilable(String)) }
    def name_of_proxy_target(constant, class_name)
      return unless class_name == "ActiveSupport::Deprecation::DeprecatedConstantProxy"

      # We are dealing with a ActiveSupport::Deprecation::DeprecatedConstantProxy
      # so try to get the name of the target class
      begin
        target = constant.__send__(:target)
      rescue NoMethodError
        return
      end

      name_of(target)
    end
  end
end
