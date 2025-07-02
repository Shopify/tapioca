# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    class Pipeline
      extend T::Sig
      include Runtime::Reflection
      include RBIHelper

      IGNORED_SYMBOLS = ["YAML", "MiniTest", "Mutex"] #: Array[String]

      #: Gemfile::GemSpec
      attr_reader :gem

      #: ^(String error) -> void
      attr_reader :error_handler

      #: (Gemfile::GemSpec gem, error_handler: ^(String error) -> void, ?include_doc: bool, ?include_loc: bool) -> void
      def initialize(
        gem,
        error_handler:,
        include_doc: false,
        include_loc: false
      )
        @root = RBI::Tree.new #: RBI::Tree
        @gem = gem
        @seen = Set.new #: Set[String]
        @alias_namespace = Set.new #: Set[String]
        @error_handler = error_handler

        @events = [] #: Array[Gem::Event]

        @payload_symbols = Static::SymbolLoader.payload_symbols #: Set[String]
        @bootstrap_symbols = load_bootstrap_symbols(@gem) #: Set[String]

        @bootstrap_symbols.each { |symbol| push_symbol(symbol) }

        @node_listeners = [] #: Array[Gem::Listeners::Base]
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
        @node_listeners << Gem::Listeners::SourceLocation.new(self) if include_loc
        @node_listeners << Gem::Listeners::RemoveEmptyPayloadScopes.new(self)
      end

      #: -> RBI::Tree
      def compile
        dispatch(next_event) until @events.empty?
        @root
      end

      # Events handling

      #: (String symbol) -> void
      def push_symbol(symbol)
        @events << Gem::SymbolFound.new(symbol)
      end

      # @without_runtime
      #: (String symbol, BasicObject constant) -> void
      def push_constant(symbol, constant)
        @events << Gem::ConstantFound.new(symbol, constant)
      end

      #: (String symbol, Module constant) -> void
      def push_foreign_constant(symbol, constant)
        @events << Gem::ForeignConstantFound.new(symbol, constant)
      end

      #: (String symbol, Module constant, RBI::Const node) -> void
      def push_const(symbol, constant, node)
        @events << Gem::ConstNodeAdded.new(symbol, constant, node)
      end

      #: (String symbol, Module constant, RBI::Scope node) -> void
      def push_scope(symbol, constant, node)
        @events << Gem::ScopeNodeAdded.new(symbol, constant, node)
      end

      #: (String symbol, Module constant, RBI::Scope node) -> void
      def push_foreign_scope(symbol, constant, node)
        @events << Gem::ForeignScopeNodeAdded.new(symbol, constant, node)
      end

      #: (String symbol, Module constant, UnboundMethod method, RBI::Method node, untyped signature, Array[[Symbol, String]] parameters) -> void
      def push_method(symbol, constant, method, node, signature, parameters) # rubocop:disable Metrics/ParameterLists
        @events << Gem::MethodNodeAdded.new(symbol, constant, method, node, signature, parameters)
      end

      # Constants and properties filtering

      #: (String symbol_name) -> bool
      def symbol_in_payload?(symbol_name)
        symbol_name = symbol_name[2..-1] if symbol_name.start_with?("::")
        return false unless symbol_name

        @payload_symbols.include?(symbol_name)
      end

      #: ((String | Symbol) name) -> bool
      def constant_in_gem?(name)
        loc = const_source_location(name)

        # If the source location of the constant isn't available or is "(eval)", all bets are off.
        return true if loc.nil? || loc.file.nil? || loc.file == "(eval)"

        gem.contains_path?(loc.file)
      end

      class MethodDefinitionLookupResult
        extend T::Helpers
        abstract!
      end

      # The method doesn't seem to exist
      class MethodUnknown < MethodDefinitionLookupResult; end

      # The method is not defined in the gem
      class MethodNotInGem < MethodDefinitionLookupResult; end

      # The method probably defined in the gem but doesn't have a source location
      class MethodInGemWithoutLocation < MethodDefinitionLookupResult; end

      # The method defined in gem and has a source location
      class MethodInGemWithLocation < MethodDefinitionLookupResult
        extend T::Sig

        #: Runtime::SourceLocation
        attr_reader :location

        #: (Runtime::SourceLocation location) -> void
        def initialize(location)
          @location = location
          super()
        end
      end

      #: (Symbol method_name, Module owner) -> MethodDefinitionLookupResult
      def method_definition_in_gem(method_name, owner)
        definitions = Tapioca::Runtime::Trackers::MethodDefinition.method_definitions_for(method_name, owner)

        # If the source location of the method isn't available, signal that by returning nil.
        return MethodUnknown.new if definitions.empty?

        # Look up the first entry that matches a file in the gem.
        found = definitions.find { |loc| @gem.contains_path?(loc.file) }

        unless found
          # If the source location of the method is "(eval)", err on the side of caution and include the method.
          found = definitions.find { |loc| loc.file == "(eval)" }
          # However, we can just return true to signal that the method should be included.
          # We can't provide a source location for it, but we want it to be included in the gem RBI.
          return MethodInGemWithoutLocation.new if found
        end

        # If we searched but couldn't find a source location in the gem, return false to signal that.
        return MethodNotInGem.new unless found

        MethodInGemWithLocation.new(found)
      end

      # Helpers

      #: (Module constant) -> String?
      def name_of(constant)
        name = name_of_proxy_target(constant, super(class_of(constant)))
        return name if name

        name = super(constant)
        return if name.nil?
        return unless are_equal?(constant, constantize(name, inherit: true))

        name = "Struct" if name =~ /^(::)?Struct::[^:]+$/
        name
      end

      private

      #: (Gemfile::GemSpec gem) -> Set[String]
      def load_bootstrap_symbols(gem)
        engine_symbols = Static::SymbolLoader.engine_symbols(gem)
        gem_symbols = Static::SymbolLoader.gem_symbols(gem)

        gem_symbols.union(engine_symbols)
      end

      # Events handling

      #: -> Gem::Event
      def next_event
        T.must(@events.shift)
      end

      #: (Gem::Event event) -> void
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

      #: (Gem::SymbolFound event) -> void
      def on_symbol(event)
        symbol = event.symbol.delete_prefix("::")
        return if skip_symbol?(symbol)

        constant = constantize(symbol)
        push_constant(symbol, constant) if Runtime::Reflection.constant_defined?(constant)
      end

      #: (Gem::ConstantFound event) -> void
      def on_constant(event)
        name = event.symbol
        return if skip_constant?(name, event.constant)

        if event.is_a?(Gem::ForeignConstantFound)
          compile_foreign_constant(name, event.constant)
        else
          compile_constant(name, event.constant)
        end
      end

      #: (Gem::NodeAdded event) -> void
      def on_node(event)
        @node_listeners.each { |listener| listener.dispatch(event) }
      end

      # Compiling

      #: (String symbol, Module constant) -> void
      def compile_foreign_constant(symbol, constant)
        return if skip_foreign_constant?(symbol, constant)
        return if seen?(symbol)

        seen!(symbol)

        scope = compile_scope(symbol, constant)
        push_foreign_scope(symbol, constant, scope)
      end

      # @without_runtime
      #: (String symbol, BasicObject constant) -> void
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

      #: (String name, Module constant) -> void
      def compile_alias(name, constant)
        return if seen?(name)

        seen!(name)

        return if skip_alias?(name, constant)

        target = name_of(constant)
        # If target has no name, let's make it an anonymous class or module with `Class.new` or `Module.new`
        target = "#{constant.class}.new" unless target

        add_to_alias_namespace(name)

        return if IGNORED_SYMBOLS.include?(name)

        node = RBI::Const.new(name, target)
        push_const(name, constant, node)
        @root << node
      end

      # @without_runtime
      #: (String name, BasicObject value) -> void
      def compile_object(name, value)
        return if seen?(name)

        seen!(name)

        return if skip_object?(name, value)

        klass = class_of(value)

        klass_name = if T::Generic === klass
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
        type_name = "T.untyped" if type_name == "NilClass"
        node = RBI::Const.new(name, "T.let(T.unsafe(nil), #{type_name})")
        push_const(name, klass, node)
        @root << node
      end

      #: (String name, Module constant) -> void
      def compile_module(name, constant)
        return if skip_module?(name, constant)
        return if seen?(name)

        seen!(name)

        scope = compile_scope(name, constant)
        push_scope(name, constant, scope)
      end

      #: (String name, Module constant) -> RBI::Scope
      def compile_scope(name, constant)
        scope = if constant.is_a?(Class)
          superclass = compile_superclass(constant)
          RBI::Class.new(name, superclass_name: superclass)
        else
          RBI::Module.new(name)
        end

        @root << scope

        scope
      end

      #: (Class[top] constant) -> String?
      def compile_superclass(constant)
        superclass = nil #: Class[top]? # rubocop:disable Lint/UselessAssignment

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
          next unless Module === resolved_superclass && Runtime::Reflection.constant_defined?(resolved_superclass)
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

      # Constants and properties filtering

      #: (String name) -> bool
      def skip_symbol?(name)
        symbol_in_payload?(name) && !@bootstrap_symbols.include?(name)
      end

      # @without_runtime
      #: (String name, top constant) -> bool
      def skip_constant?(name, constant)
        return true if name.strip.empty?
        return true if name.start_with?("#<")
        return true if name.downcase == name
        return true if alias_namespaced?(name)

        return true if T::Enum === constant # T::Enum instances are defined via `compile_enums`

        false
      end

      #: (String name, Module constant) -> bool
      def skip_alias?(name, constant)
        return true if symbol_in_payload?(name)
        return true unless constant_in_gem?(name)
        return true if has_aliased_namespace?(name)

        false
      end

      # @without_runtime
      #: (String name, BasicObject constant) -> bool
      def skip_object?(name, constant)
        return true if symbol_in_payload?(name)
        return true unless constant_in_gem?(name)

        false
      end

      #: (String name, Module constant) -> bool
      def skip_foreign_constant?(name, constant)
        Tapioca::TypeVariableModule === constant
      end

      #: (String name, Module constant) -> bool
      def skip_module?(name, constant)
        return true unless defined_in_gem?(constant, strict: false)
        return true if Tapioca::TypeVariableModule === constant

        false
      end

      #: (Module constant, ?strict: bool) -> bool
      def defined_in_gem?(constant, strict: true)
        files = get_file_candidates(constant)
          .merge(Runtime::Trackers::ConstantDefinition.files_for(constant))

        return !strict if files.empty?

        files.any? do |file|
          @gem.contains_path?(file)
        end
      end

      #: (Module constant) -> Set[String]
      def get_file_candidates(constant)
        file_candidates_for(constant)
      rescue ArgumentError, NameError
        Set.new
      end

      #: (String name) -> void
      def add_to_alias_namespace(name)
        @alias_namespace.add("#{name}::")
      end

      #: (String name) -> bool
      def alias_namespaced?(name)
        @alias_namespace.any? do |namespace|
          name.start_with?(namespace)
        end
      end

      #: (String name) -> void
      def seen!(name)
        @seen.add(name)
      end

      #: (String name) -> bool
      def seen?(name)
        @seen.include?(name)
      end

      # Helpers

      #: ((Module & T::Generic) constant) -> String
      def generic_name_of(constant)
        type_name = T.must(constant.name)
        return type_name if type_name =~ /\[.*\]$/

        type_variables = Runtime::GenericTypeRegistry.lookup_type_variables(constant)
        return type_name unless type_variables

        type_variables = type_variables.reject(&:fixed?)
        return type_name if type_variables.empty?

        type_variable_names = type_variables.map { "T.untyped" }.join(", ")

        "#{type_name}[#{type_variable_names}]"
      end

      #: (Module constant, String? class_name) -> String?
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
