# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    class SymbolTableCompiler
      extend T::Sig
      include Reflection

      IGNORED_SYMBOLS = T.let(["YAML", "MiniTest", "Mutex"], T::Array[String])

      sig { returns(Gemfile::GemSpec) }
      attr_reader :gem

      sig { params(gem: Gemfile::GemSpec, include_doc: T::Boolean).void }
      def initialize(gem, include_doc: false)
        @root = T.let(RBI::Tree.new, RBI::Tree)
        @gem = gem
        @seen = T.let(Set.new, T::Set[String])
        @alias_namespace = T.let(Set.new, T::Set[String])

        @events = T.let([], T::Array[Gem::Event])

        @payload_symbols = T.let(SymbolLoader.payload_symbols, T::Set[String])
        @bootstrap_symbols = T.let(SymbolLoader.gem_symbols(@gem).union(SymbolLoader.engine_symbols), T::Set[String])
        @bootstrap_symbols.each { |symbol| push_symbol(symbol) }

        @node_listeners = T.let([], T::Array[Gem::Listeners::Base])
        @node_listeners << Gem::Listeners::SorbetTypeVariables.new(self)
        @node_listeners << Gem::Listeners::Mixins.new(self)
        @node_listeners << Gem::Listeners::DynamicMixins.new(self)
        @node_listeners << Gem::Listeners::SorbetHelpers.new(self)
        @node_listeners << Gem::Listeners::SorbetEnums.new(self)
        @node_listeners << Gem::Listeners::SorbetProps.new(self)
        @node_listeners << Gem::Listeners::SorbetRequiredAncestors.new(self)
        @node_listeners << Gem::Listeners::SorbetSignatures.new(self)
        @node_listeners << Gem::Listeners::YardDoc.new(self) if include_doc
      end

      sig { returns(RBI::Tree) }
      def compile
        dispatch(next_event) until @events.empty?
        @root
      end

      sig { params(symbol: String).void }
      def push_symbol(symbol)
        @events << Gem::NewSymbolFound.new(symbol)
      end

      sig { params(symbol: String, constant: BasicObject).void.checked(:never) }
      def push_constant(symbol, constant)
        @events << Gem::NewConstantFound.new(symbol, constant)
      end

      sig { params(symbol: String, constant: Module, node: RBI::Const).void.checked(:never) }
      def push_const(symbol, constant, node)
        @events << Gem::NewConstNode.new(symbol, constant, node)
      end

      sig { params(symbol: String, constant: Module, node: RBI::Scope).void.checked(:never) }
      def push_scope(symbol, constant, node)
        @events << Gem::NewScopeNode.new(symbol, constant, node)
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
        @events << Gem::NewMethodNode.new(symbol, constant, node, signature, parameters)
      end

      sig { params(sig_string: String).returns(String) }
      def sanitize_signature_types(sig_string)
        sig_string
          .gsub(".returns(<VOID>)", ".void")
          .gsub("<VOID>", "void")
          .gsub("<NOT-TYPED>", "T.untyped")
          .gsub(".params()", "")
      end

      private

      sig { returns(Gem::Event) }
      def next_event
        T.must(@events.pop)
      end

      sig { params(event: Gem::Event).void }
      def dispatch(event)
        case event
        when Gem::NewSymbolFound
          on_symbol(event)
        when Gem::NewConstantFound
          on_constant(event)
        when Gem::NewNodeAdded
          on_node(event)
        else
          raise "Unsupported event #{event.class}"
        end
      end

      sig { params(event: Gem::NewSymbolFound).void }
      def on_symbol(event)
        symbol = event.symbol
        return if symbol_in_payload?(symbol) && !@bootstrap_symbols.include?(symbol)

        constant = constantize(symbol)
        push_constant(symbol, constant) if constant
      end

      sig { params(event: Gem::NewConstantFound).void.checked(:never) }
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
        compile_constant(name, constant)
      end

      sig { params(event: Gem::NewNodeAdded).void }
      def on_node(event)
        @node_listeners.each { |listener| listener.dispatch(event) }
      end

      # Compile

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

      sig { params(name: String, constant: Module).void }
      def compile_module(name, constant)
        return unless defined_in_gem?(constant, strict: false)
        return if Tapioca::TypeVariableModule === constant

        scope =
          if constant.is_a?(Class)
            superclass = compile_superclass(constant)
            RBI::Class.new(name, superclass_name: superclass)
          else
            RBI::Module.new(name)
          end

        compile_body(scope, name, constant)

        return if symbol_in_payload?(name) && scope.empty?

        push_scope(name, constant, scope)
        @root << scope
        compile_subconstants(name, constant)
      end

      sig { params(tree: RBI::Tree, name: String, constant: Module).void }
      def compile_body(tree, name, constant)
        # Compiling type variables must happen first to populate generic names
        compile_methods(tree, name, constant)
      end

      sig { params(name: String, constant: Module).void }
      def compile_subconstants(name, constant)
        constants_of(constant).sort.uniq.map do |constant_name|
          symbol = (name == "Object" ? "" : name) + "::#{constant_name}"
          subconstant = constantize(symbol)

          # Don't compile modules of Object because Object::Foo == Foo
          # Don't compile modules of BasicObject because BasicObject::BasicObject == BasicObject
          next if (Object == constant || BasicObject == constant) && Module === subconstant
          next unless subconstant

          push_constant(symbol, subconstant)
        end
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

      sig { params(tree: RBI::Tree, name: String, constant: Module).void }
      def compile_methods(tree, name, constant)
        compile_method(
          tree,
          name,
          constant,
          initialize_method_for(constant)
        )

        compile_directly_owned_methods(tree, name, constant)
        compile_directly_owned_methods(tree, name, singleton_class_of(constant))
      end

      sig do
        params(
          tree: RBI::Tree,
          module_name: String,
          mod: Module,
          for_visibility: T::Array[Symbol]
        ).void
      end
      def compile_directly_owned_methods(tree, module_name, mod, for_visibility = [:public, :protected, :private])
        method_names_by_visibility(mod)
          .delete_if { |visibility, _method_list| !for_visibility.include?(visibility) }
          .each do |visibility, method_list|
            method_list.sort!.map do |name|
              next if name == :initialize
              vis = case visibility
              when :protected
                RBI::Protected.new
              when :private
                RBI::Private.new
              else
                RBI::Public.new
              end
              compile_method(tree, module_name, mod, mod.instance_method(name), vis)
            end
          end
      end

      sig { params(mod: Module).returns(T::Hash[Symbol, T::Array[Symbol]]) }
      def method_names_by_visibility(mod)
        {
          public: public_instance_methods_of(mod),
          protected: protected_instance_methods_of(mod),
          private: private_instance_methods_of(mod),
        }
      end

      sig { params(constant: Module, method_name: String).returns(T::Boolean) }
      def struct_method?(constant, method_name)
        return false unless T::Props::ClassMethods === constant

        constant
          .props
          .keys
          .include?(method_name.gsub(/=$/, "").to_sym)
      end

      sig do
        params(
          tree: RBI::Tree,
          symbol_name: String,
          constant: Module,
          method: T.nilable(UnboundMethod),
          visibility: RBI::Visibility
        ).void
      end
      def compile_method(tree, symbol_name, constant, method, visibility = RBI::Public.new)
        return unless method
        return unless method.owner == constant
        return if symbol_in_payload?(symbol_name) && !method_in_gem?(method)

        signature = signature_of(method)
        method = T.let(signature.method, UnboundMethod) if signature

        method_name = method.name.to_s
        return unless valid_method_name?(method_name)
        return if struct_method?(constant, method_name)
        return if method_name.start_with?("__t_props_generated_")

        parameters = T.let(method.parameters, T::Array[[Symbol, T.nilable(Symbol)]])

        sanitized_parameters = parameters.each_with_index.map do |(type, name), index|
          fallback_arg_name = "_arg#{index}"

          name = if name
            name.to_s
          else
            # For attr_writer methods, Sorbet signatures have the name
            # of the method (without the trailing = sign) as the name of
            # the only parameter. So, if the parameter does not have a name
            # then the replacement name should be the name of the method
            # (minus trailing =) if and only if there is a signature for the
            # method and the parameter is required and there is a single
            # parameter and the signature also defines a single parameter and
            # the name of the method ends with a = character.
            writer_method_with_sig = (
              signature && type == :req &&
              parameters.size == 1 &&
              signature.arg_types.size == 1 &&
              method_name[-1] == "="
            )

            if writer_method_with_sig
              method_name.delete_suffix("=")
            else
              fallback_arg_name
            end
          end

          # Sanitize param names
          name = fallback_arg_name unless valid_parameter_name?(name)

          [type, name]
        end

        rbi_method = RBI::Method.new(
          method_name,
          is_singleton: constant.singleton_class?,
          visibility: visibility
        )

        sanitized_parameters.each do |type, name|
          case type
          when :req
            rbi_method << RBI::Param.new(name)
          when :opt
            rbi_method << RBI::OptParam.new(name, "T.unsafe(nil)")
          when :rest
            rbi_method << RBI::RestParam.new(name)
          when :keyreq
            rbi_method << RBI::KwParam.new(name)
          when :key
            rbi_method << RBI::KwOptParam.new(name, "T.unsafe(nil)")
          when :keyrest
            rbi_method << RBI::KwRestParam.new(name)
          when :block
            rbi_method << RBI::BlockParam.new(name)
          end
        end

        push_method(symbol_name, constant, rbi_method, signature, sanitized_parameters)
        tree << rbi_method
      end

      sig { params(symbol_name: String).returns(T::Boolean) }
      def symbol_in_payload?(symbol_name)
        symbol_name = symbol_name[2..-1] if symbol_name.start_with?("::")
        return false unless symbol_name
        @payload_symbols.include?(symbol_name)
      end

      SPECIAL_METHOD_NAMES = T.let([
        "!", "~", "+@", "**", "-@", "*", "/", "%", "+", "-", "<<", ">>", "&", "|", "^",
        "<", "<=", "=>", ">", ">=", "==", "===", "!=", "=~", "!~", "<=>", "[]", "[]=", "`",
      ], T::Array[String])

      sig { params(name: String).returns(T::Boolean) }
      def valid_method_name?(name)
        return true if SPECIAL_METHOD_NAMES.include?(name)
        !!name.match(/^[[:word:]]+[?!=]?$/)
      end

      sig { params(name: String).returns(T::Boolean) }
      def valid_parameter_name?(name)
        name.match?(/^[[[:alnum:]]_]+$/)
      end

      sig { params(method: UnboundMethod).returns(T::Boolean) }
      def method_in_gem?(method)
        source_location = method.source_location&.first
        return false if source_location.nil?

        @gem.contains_path?(source_location)
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

      sig { params(constant: Module).returns(T.nilable(UnboundMethod)) }
      def initialize_method_for(constant)
        constant.instance_method(:initialize)
      rescue
        nil
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
