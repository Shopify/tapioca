# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    class SymbolTableCompiler
      extend T::Sig
      include Reflection

      class Event; end

      class SymbolEvent < Event
        extend T::Sig

        sig { returns(RBI::Tree) }
        attr_reader :tree

        sig { returns(String) }
        attr_reader :symbol

        sig { params(tree: RBI::Tree, symbol: String).void }
        def initialize(tree, symbol)
          @tree = tree
          @symbol = symbol
        end
      end

      class ConstantEvent < Event
        extend T::Sig

        sig { returns(RBI::Tree) }
        attr_reader :tree

        sig { returns(String) }
        attr_reader :symbol

        sig { returns(BasicObject).checked(:never) }
        attr_reader :constant

        sig { params(tree: RBI::Tree, symbol: String, constant: BasicObject).void.checked(:never) }
        def initialize(tree, symbol, constant)
          @tree = tree
          @symbol = symbol
          @constant = constant
        end
      end

      class NodeEvent < Event
        extend T::Sig

        sig { returns(RBI::Tree) }
        attr_reader :tree

        sig { returns(String) }
        attr_reader :symbol

        sig { returns(Module).checked(:never) }
        attr_reader :constant

        sig { returns(RBI::Node) }
        attr_reader :node

        sig { params(tree: RBI::Tree, symbol: String, constant: Module, node: RBI::Node).void.checked(:never) }
        def initialize(tree, symbol, constant, node)
          @tree = tree
          @symbol = symbol
          @constant = constant
          @node = node
        end
      end

      class MethodEvent < NodeEvent
        extend T::Sig

        sig { returns(T.untyped) }
        attr_reader :signature

        sig { returns(T::Array[[Symbol, String]]) }
        attr_reader :parameters

        sig do
          params(
            tree: RBI::Tree,
            symbol: String,
            constant: BasicObject,
            node: RBI::Node,
            signature: T.untyped,
            parameters: T::Array[[Symbol, String]]
          ).void.checked(:never)
        end
        def initialize(tree, symbol, constant, node, signature, parameters)
          super(tree, symbol, constant, node)
          @signature = signature
          @parameters = parameters
        end
      end

      IGNORED_SYMBOLS = T.let(["YAML", "MiniTest", "Mutex"], T::Array[String])

      sig { params(gem: Gemfile::GemSpec, include_doc: T::Boolean).void }
      def initialize(gem, include_doc: false)
        @gem = gem
        @seen = T.let(Set.new, T::Set[String])
        @alias_namespace = T.let(Set.new, T::Set[String])

        @payload_symbols = T.let(SymbolLoader.payload_symbols, T::Set[String])
        @bootstrap_symbols = T.let(SymbolLoader.gem_symbols(@gem).union(SymbolLoader.engine_symbols), T::Set[String])

        @node_listeners = T.let([], T::Array[NodeListeners::Base])
        @node_listeners << NodeListeners::Mixins.new(self)
        @node_listeners << NodeListeners::DynamicMixins.new(self)
        @node_listeners << NodeListeners::Helpers.new(self)
        @node_listeners << NodeListeners::Methods.new(self)
        @node_listeners << NodeListeners::Enums.new(self)
        @node_listeners << NodeListeners::Props.new(self)
        @node_listeners << NodeListeners::RequiresAncestor.new(self)
        @node_listeners << NodeListeners::Signatures.new(self)
        @node_listeners << NodeListeners::TypeVariables.new(self)
        @node_listeners << NodeListeners::YardDoc.new(self) if include_doc

        @events = T.let([], T::Array[Event])
        @include_doc = include_doc

        gem.parse_yard_docs if include_doc
      end

      sig { params(rbi: RBI::File).void }
      def compile(rbi)
        @bootstrap_symbols.sort.each { |symbol| push_symbol(rbi.root, symbol) }
        dispatch_next until @events.empty?
      end

      sig { params(tree: RBI::Tree, symbol: String).void }
      def push_symbol(tree, symbol)
        @events << SymbolEvent.new(tree, symbol)
      end

      sig { params(tree: RBI::Tree, symbol: String, constant: BasicObject).void.checked(:never) }
      def push_constant(tree, symbol, constant)
        @events << ConstantEvent.new(tree, symbol, constant)
      end

      sig { params(tree: RBI::Tree, symbol: String, constant: Module, node: RBI::Node).void.checked(:never) }
      def push_node(tree, symbol, constant, node)
        @events << NodeEvent.new(tree, symbol, constant, node)
      end

      sig do
        params(
          tree: RBI::Tree,
          symbol: String,
          constant: BasicObject,
          node: RBI::Node,
          signature: T.untyped,
          parameters: T::Array[[Symbol, String]]
        ).void.checked(:never)
      end
      def push_method(tree, symbol, constant, node, signature, parameters)
        @events << MethodEvent.new(tree, symbol, constant, node, signature, parameters)
      end

      sig { params(sig_string: String).returns(String) }
      def sanitize_signature_types(sig_string)
        sig_string
          .gsub(".returns(<VOID>)", ".void")
          .gsub("<VOID>", "void")
          .gsub("<NOT-TYPED>", "T.untyped")
          .gsub(".params()", "")
      end

      sig { params(method: UnboundMethod).returns(T::Boolean) }
      def method_in_gem?(method)
        source_location = method.source_location&.first
        return false if source_location.nil?

        @gem.contains_path?(source_location)
      end

      sig { params(symbol_name: String).returns(T::Boolean) }
      def symbol_in_payload?(symbol_name)
        symbol_name = T.must(symbol_name[2..-1]) if symbol_name.start_with?("::")
        @payload_symbols.include?(symbol_name)
      end

      private

      sig { void }
      def dispatch_next
        dispatch_event(T.must(@events.shift))
      end

      sig { params(event: Event).void }
      def dispatch_event(event)
        case event
        when SymbolEvent
          on_symbol(event)
        when ConstantEvent
          on_constant(event)
        when NodeEvent
          on_node(event)
        end
      end

      sig { params(event: SymbolEvent).void }
      def on_symbol(event)
        symbol = event.symbol
        return if symbol_in_payload?(symbol) && !@bootstrap_symbols.include?(symbol)
        constant = constantize(symbol)
        return unless constant

        push_constant(event.tree, symbol, constant)
      end

      sig { params(event: ConstantEvent).void.checked(:never) }
      def on_constant(event)
        name = event.symbol

        return if name.strip.empty?
        return if name.start_with?("#<")
        return if name.downcase == name
        return if alias_namespaced?(name)
        return if seen?(name)

        constant = event.constant
        return if T::Enum === constant # T::Enum instances are defined via `compile_enums`

        mark_seen(name)

        case constant
        when Module
          if name_of(constant) != name
            compile_alias(event.tree, name, constant)
          else
            compile_module(event.tree, name, constant)
          end
        else
          compile_object(event.tree, name, constant)
        end
      end

      sig { params(event: NodeEvent).void }
      def on_node(event)
        @node_listeners.each { |listener| listener.dispatch(event) }
      end

      # Compiling

      sig { params(tree: RBI::Tree, name: String, constant: Module).void }
      def compile_alias(tree, name, constant)
        return if symbol_in_payload?(name)

        target = name_of(constant)
        # If target has no name, let's make it an anonymous class or module with `Class.new` or `Module.new`
        target = "#{constant.class}.new" unless target

        add_to_alias_namespace(name)

        return if IGNORED_SYMBOLS.include?(name)

        node = RBI::Const.new(name, target)
        push_node(tree, name, constant, node)
        tree << node
      end

      sig { params(tree: RBI::Tree, name: String, value: BasicObject).void.checked(:never) }
      def compile_object(tree, name, value)
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
          push_node(tree, klass_name,  klass, node)
          tree << node
          return
        end

        return if klass_name&.start_with?("T::Types::", "T::Private::")

        type_name = klass_name || "T.untyped"
        node = RBI::Const.new(name, "T.let(T.unsafe(nil), #{type_name})")
        push_node(tree, name, klass, node)
        tree << node
      end

      sig { params(tree: RBI::Tree, name: String, constant: Module).void }
      def compile_module(tree, name, constant)
        return unless defined_in_gem?(constant, strict: false)
        return if Tapioca::TypeVariableModule === constant

        scope =
          if constant.is_a?(Class)
            superclass = compile_superclass(tree, constant)
            RBI::Class.new(name, superclass_name: superclass)
          else
            RBI::Module.new(name)
          end

        # return if symbol_in_payload?(name) && scope.empty?

        push_node(tree, name,  constant, scope)
        tree << scope
        compile_subconstants(tree, name, constant)
      end

      sig { params(tree: RBI::Tree, name: String, constant: Module).void }
      def compile_subconstants(tree, name, constant)
        constants_of(constant).sort.uniq.map do |constant_name|
          symbol = (name == "Object" ? "" : name) + "::#{constant_name}"
          subconstant = constantize(symbol)

          # Don't compile modules of Object because Object::Foo == Foo
          # Don't compile modules of BasicObject because BasicObject::BasicObject == BasicObject
          next if (Object == constant || BasicObject == constant) && Module === subconstant
          next unless subconstant

          push_constant(tree, symbol, subconstant)
        end
      end

      sig { params(tree: RBI::Tree, constant: Class).returns(T.nilable(String)) }
      def compile_superclass(tree, constant)
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

        push_symbol(tree, name)

        "::#{name}"
      end

      sig { params(constant: Module, strict: T::Boolean).returns(T::Boolean) }
      def defined_in_gem?(constant, strict: true)
        files = Set.new(get_file_candidates(constant))
          .merge(Tapioca::Trackers::ConstantDefinition.files_for(constant))

        return !strict if files.empty?

        files.any? do |file|
          @gem.contains_path?(file)
        end
      end

      sig do
        params(
          mod: Module,
          mixin_type: Trackers::Mixin::Type,
          mixin_locations: T::Hash[Trackers::Mixin::Type, T::Hash[Module, T::Array[String]]]
        ).returns(T::Boolean)
      end
      def mixed_in_by_gem?(mod, mixin_type, mixin_locations)
        locations = mixin_locations.dig(mixin_type, mod)
        return true unless locations
        locations.any? { |location| @gem.contains_path?(location) }
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

      sig { params(constant: Module).returns(T.nilable(String)) }
      def name_of(constant)
        name = name_of_proxy_target(constant, super(class_of(constant)))
        return name if name
        name = super(constant)
        return if name.nil?
        return unless are_equal?(constant, constantize(name, inherit: true))
        name = "Struct" if name =~ /^(::)?Struct::[^:]+$/
        name
      end

      sig { params(constant: T.all(Module, T::Generic)).returns(String) }
      def generic_name_of(constant)
        type_name = T.must(constant.name)
        return type_name if type_name =~ /\[.*\]$/

        type_variables = Tapioca::GenericTypeRegistry.lookup_type_variables(constant)
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
end
