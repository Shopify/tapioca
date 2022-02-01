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
        @node_listeners << Gem::Listeners::SorbetRequiredAncestors.new(self)
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

      sig { params(symbol: String, constant: Module, node: RBI::Method).void.checked(:never) }
      def push_method(symbol, constant, node)
        @events << Gem::NewMethodNode.new(symbol, constant, node)
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
        compile_type_variables(tree, constant)
        compile_methods(tree, name, constant)
        compile_module_helpers(tree, constant)
        compile_mixins(tree, constant)
        compile_props(tree, constant)
        compile_enums(tree, constant)
        compile_dynamic_mixins(tree, constant)
      end

      sig { params(tree: RBI::Tree, constant: Module).void }
      def compile_dynamic_mixins(tree, constant)
        return if constant.is_a?(Class)

        mixin_compiler = DynamicMixinCompiler.new(constant)
        mixin_compiler.compile_class_attributes(tree)
        dynamic_extends, dynamic_includes = mixin_compiler.compile_mixes_in_class_methods(tree)

        (dynamic_includes + dynamic_extends).each do |mod|
          name = name_of(mod)
          push_symbol(name) if name
        end
      end

      sig { params(tree: RBI::Tree, constant: Module).void }
      def compile_module_helpers(tree, constant)
        abstract_type = T::Private::Abstract::Data.get(constant, :abstract_type) ||
          T::Private::Abstract::Data.get(singleton_class_of(constant), :abstract_type)

        tree << RBI::Helper.new(abstract_type.to_s) if abstract_type
        tree << RBI::Helper.new("final") if T::Private::Final.final_module?(constant)
        tree << RBI::Helper.new("sealed") if T::Private::Sealed.sealed_module?(constant)
      end

      sig { params(tree: RBI::Tree, constant: Module).void }
      def compile_props(tree, constant)
        return unless T::Props::ClassMethods === constant

        constant.props.map do |name, prop|
          type = prop.fetch(:type_object, "T.untyped").to_s.gsub(".returns(<VOID>)", ".void")

          default = prop.key?(:default) ? "T.unsafe(nil)" : nil
          tree << if prop.fetch(:immutable, false)
            RBI::TStructConst.new(name.to_s, type, default: default)
          else
            RBI::TStructProp.new(name.to_s, type, default: default)
          end
        end
      end

      sig { params(tree: RBI::Tree, constant: Module).void }
      def compile_enums(tree, constant)
        return unless T::Enum > constant

        enums = T.unsafe(constant).values.map do |enum_type|
          enum_type.instance_variable_get(:@const_name).to_s
        end

        tree << RBI::TEnumBlock.new(enums)
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

      sig { params(tree: RBI::Tree, constant: Module).void }
      def compile_type_variables(tree, constant)
        compile_type_variable_declarations(tree, constant)

        sclass = RBI::SingletonClass.new
        compile_type_variable_declarations(sclass, singleton_class_of(constant))
        tree << sclass if sclass.nodes.length > 1
      end

      sig { params(tree: RBI::Tree, constant: Module).void }
      def compile_type_variable_declarations(tree, constant)
        # Try to find the type variables defined on this constant, bail if we can't
        type_variables = GenericTypeRegistry.lookup_type_variables(constant)
        return unless type_variables

        # Map each type variable to its string representation.
        #
        # Each entry of `type_variables` maps a Module to a String,
        # and the order they are inserted into the hash is the order they should be
        # defined in the source code.
        type_variable_declarations = type_variables.map do |type_variable|
          type_variable_name = type_variable.name
          next unless type_variable_name

          tree << RBI::TypeMember.new(type_variable_name, type_variable.serialize)
        end

        return if type_variable_declarations.empty?

        tree << RBI::Extend.new("T::Generic")
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

      sig { params(tree: RBI::Tree, constant: Module).void }
      def compile_mixins(tree, constant)
        singleton_class = singleton_class_of(constant)

        interesting_ancestors = interesting_ancestors_of(constant)
        interesting_singleton_class_ancestors = interesting_ancestors_of(singleton_class)

        prepends = interesting_ancestors.take_while { |c| !are_equal?(constant, c) }
        includes = interesting_ancestors.drop(prepends.size + 1)
        extends  = interesting_singleton_class_ancestors.reject do |mod|
          Module != class_of(mod) || are_equal?(mod, singleton_class)
        end

        add_mixins(tree, prepends.reverse, Trackers::Mixin::Type::Prepend)
        add_mixins(tree, includes.reverse, Trackers::Mixin::Type::Include)
        add_mixins(tree, extends.reverse, Trackers::Mixin::Type::Extend)
      end

      sig do
        params(
          tree: RBI::Tree,
          mods: T::Array[Module],
          mixin_type: Trackers::Mixin::Type
        ).void
      end
      def add_mixins(tree, mods, mixin_type)
        mods
          .select do |mod|
            name = name_of(mod)

            name && !filtered_mixin?(name)
          end
          .map do |mod|
            name = name_of(mod)
            push_symbol(name) if name

            qname = qualified_name_of(mod)
            case mixin_type
            # TODO: Sorbet currently does not handle prepend
            # properly for method resolution, so we generate an
            # include statement instead
            when Trackers::Mixin::Type::Include, Trackers::Mixin::Type::Prepend
              tree << RBI::Include.new(T.must(qname))
            when Trackers::Mixin::Type::Extend
              tree << RBI::Extend.new(T.must(qname))
            end
          end
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

        rbi_method.sigs << compile_signature(signature, sanitized_parameters) if signature

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

        push_method(symbol_name, constant, rbi_method)
        tree << rbi_method
      end

      TYPE_PARAMETER_MATCHER = /T\.type_parameter\(:?([[:word:]]+)\)/

      sig { params(signature: T.untyped, parameters: T::Array[[Symbol, String]]).returns(RBI::Sig) }
      def compile_signature(signature, parameters)
        parameter_types = T.let(signature.arg_types.to_h, T::Hash[Symbol, T::Types::Base])
        parameter_types.merge!(signature.kwarg_types)
        parameter_types[signature.rest_name] = signature.rest_type if signature.has_rest
        parameter_types[signature.keyrest_name] = signature.keyrest_type if signature.has_keyrest
        parameter_types[signature.block_name] = signature.block_type if signature.block_name

        sig = RBI::Sig.new

        parameters.each do |_, name|
          type = sanitize_signature_types(parameter_types[name.to_sym].to_s)
          push_symbol(type)
          sig << RBI::SigParam.new(name, type)
        end

        return_type = name_of_type(signature.return_type)
        return_type = sanitize_signature_types(return_type)
        sig.return_type = return_type
        push_symbol(return_type)

        parameter_types.values.join(", ").scan(TYPE_PARAMETER_MATCHER).flatten.uniq.each do |k, _|
          sig.type_params << k
        end

        case signature.mode
        when "abstract"
          sig.is_abstract = true
        when "override"
          sig.is_override = true
        when "overridable_override"
          sig.is_overridable = true
          sig.is_override = true
        when "overridable"
          sig.is_overridable = true
        end

        sig
      end

      sig { params(sig_string: String).returns(String) }
      def sanitize_signature_types(sig_string)
        sig_string
          .gsub(".returns(<VOID>)", ".void")
          .gsub("<VOID>", "void")
          .gsub("<NOT-TYPED>", "T.untyped")
          .gsub(".params()", "")
      end

      sig { params(symbol_name: String).returns(T::Boolean) }
      def symbol_in_payload?(symbol_name)
        symbol_name = symbol_name[2..-1] if symbol_name.start_with?("::")
        return false unless symbol_name
        @payload_symbols.include?(symbol_name)
      end

      sig { params(mixin_name: String).returns(T::Boolean) }
      def filtered_mixin?(mixin_name)
        # filter T:: namespace mixins that aren't T::Props
        # T::Props and subconstants have semantic value
        mixin_name.start_with?("T::") && !mixin_name.start_with?("T::Props")
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

      sig { params(constant: Module).returns(T::Array[Module]) }
      def interesting_ancestors_of(constant)
        inherited_ancestors_ids = Set.new(
          inherited_ancestors_of(constant).map { |mod| object_id_of(mod) }
        )
        # TODO: There is actually a bug here where this will drop modules that
        # may be included twice. For example:
        #
        # ```ruby
        # class Foo
        #   prepend Kernel
        # end
        # ````
        # would give:
        # ```ruby
        # Foo.ancestors #=> [Kernel, Foo, Object, Kernel, BasicObject]
        # ````
        # but since we drop `Kernel` whenever we match it, we would miss
        # the `prepend Kernel` in the output.
        #
        # Instead, we should only drop the tail matches of the ancestors and
        # inherited ancestors, past the location of the constant itself.
        constant.ancestors.reject do |mod|
          inherited_ancestors_ids.include?(object_id_of(mod))
        end
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
