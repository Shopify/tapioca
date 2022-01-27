# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    class SymbolTableCompiler
      extend T::Sig
      include Reflection

      IGNORED_SYMBOLS = T.let(["YAML", "MiniTest", "Mutex"], T::Array[String])
      IGNORED_COMMENTS = T.let([
        ":doc:",
        ":nodoc:",
        "typed:",
        "frozen_string_literal:",
        "encoding:",
        "warn_indent:",
        "shareable_constant_value:",
        "rubocop:",
      ], T::Array[String])

      sig { params(gem: Gemfile::GemSpec, include_doc: T::Boolean).void }
      def initialize(gem, include_doc: false)
        @gem = gem
        @seen = T.let(Set.new, T::Set[String])
        @alias_namespace = T.let(Set.new, T::Set[String])
        @symbol_queue = T.let(symbols.sort.dup, T::Array[String])
        @symbols = T.let(nil, T.nilable(T::Set[String]))
        @include_doc = include_doc

        gem.parse_yard_docs if include_doc
      end

      sig { params(rbi: RBI::File).void }
      def compile(rbi)
        generate_from_symbol(rbi.root, T.must(@symbol_queue.shift)) until @symbol_queue.empty?
      end

      private

      sig { params(name: T.nilable(String)).void }
      def add_to_symbol_queue(name)
        @symbol_queue << name unless name.nil? || symbols.include?(name) || symbol_ignored?(name)
      end

      sig { returns(T::Set[String]) }
      def symbols
        @symbols ||= begin
          symbols = Tapioca::Compilers::SymbolTable::SymbolLoader.list_from_paths(@gem.files)
          symbols.union(engine_symbols(symbols))
        end
      end

      sig { params(symbols: T::Set[String]).returns(T::Set[String]) }
      def engine_symbols(symbols)
        return Set.new unless Object.const_defined?("Rails::Engine")

        engine = descendants_of(Object.const_get("Rails::Engine"))
          .reject(&:abstract_railtie?)
          .find do |klass|
            name = name_of(klass)
            !name.nil? && symbols.include?(name)
          end

        return Set.new unless engine

        paths = engine.config.eager_load_paths.flat_map do |load_path|
          Pathname.glob("#{load_path}/**/*.rb")
        end

        Tapioca::Compilers::SymbolTable::SymbolLoader.list_from_paths(paths)
      rescue
        Set.new
      end

      sig { params(tree: RBI::Tree, symbol: String).void }
      def generate_from_symbol(tree, symbol)
        constant = constantize(symbol)

        return unless constant

        compile_constant(tree, symbol, constant)
      end

      sig { params(tree: RBI::Tree, name: T.nilable(String), constant: BasicObject).void.checked(:never) }
      def compile_constant(tree, name, constant)
        return unless constant
        return unless name
        return if name.strip.empty?
        return if name.start_with?("#<")
        return if name.downcase == name
        return if alias_namespaced?(name)
        return if seen?(name)
        return if T::Enum === constant # T::Enum instances are defined via `compile_enums`

        mark_seen(name)

        case constant
        when Module
          if name_of(constant) != name
            compile_alias(tree, name, constant)
          else
            compile_module(tree, name, constant)
          end
        else
          compile_object(tree, name, constant)
        end
      end

      sig { params(tree: RBI::Tree, name: String, constant: Module).void }
      def compile_alias(tree, name, constant)
        return if symbol_ignored?(name)

        target = name_of(constant)
        # If target has no name, let's make it an anonymous class or module with `Class.new` or `Module.new`
        target = "#{constant.class}.new" unless target

        add_to_alias_namespace(name)

        return if IGNORED_SYMBOLS.include?(name)

        tree << RBI::Const.new(name, target)
      end

      sig { params(tree: RBI::Tree, name: String, value: BasicObject).void.checked(:never) }
      def compile_object(tree, name, value)
        return if symbol_ignored?(name)

        klass = class_of(value)

        klass_name = if klass == ObjectSpace::WeakMap
          # WeakMap is an implicit generic with one type variable
          "ObjectSpace::WeakMap[T.untyped]"
        elsif T::Generic === klass
          generic_name_of(klass)
        else
          name_of(klass)
        end

        comments = documentation_comments(name)

        if klass_name == "T::Private::Types::TypeAlias"
          type_alias = sanitize_signature_types(T.unsafe(value).aliased_type.to_s)
          constant = RBI::Const.new(name, "T.type_alias { #{type_alias} }", comments: comments)
          tree << constant
          return
        end

        return if klass_name&.start_with?("T::Types::", "T::Private::")

        type_name = klass_name || "T.untyped"
        constant = RBI::Const.new(name, "T.let(T.unsafe(nil), #{type_name})", comments: comments)

        tree << constant
      end

      sig { params(tree: RBI::Tree, name: String, constant: Module).void }
      def compile_module(tree, name, constant)
        return unless defined_in_gem?(constant, strict: false)
        return if Tapioca::TypeVariableModule === constant

        comments = documentation_comments(name)
        scope =
          if constant.is_a?(Class)
            superclass = compile_superclass(constant)
            RBI::Class.new(name, superclass_name: superclass, comments: comments)
          else
            RBI::Module.new(name, comments: comments)
          end

        compile_body(scope, name, constant)

        return if symbol_ignored?(name) && scope.empty?

        tree << scope
        compile_subconstants(tree, name, constant)
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
          add_to_symbol_queue(name_of(mod))
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

      sig { params(tree: RBI::Tree, name: String, constant: Module).void }
      def compile_subconstants(tree, name, constant)
        constants_of(constant).sort.uniq.map do |constant_name|
          symbol = (name == "Object" ? "" : name) + "::#{constant_name}"
          subconstant = constantize(symbol)

          # Don't compile modules of Object because Object::Foo == Foo
          # Don't compile modules of BasicObject because BasicObject::BasicObject == BasicObject
          next if (Object == constant || BasicObject == constant) && Module === subconstant
          next unless subconstant

          compile_constant(tree, symbol, subconstant)
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

        add_to_symbol_queue(name)

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
            add_to_symbol_queue(name_of(mod))

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
        return if symbol_ignored?(symbol_name) && !method_in_gem?(method)

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

        separator = constant.singleton_class? ? "." : "#"
        comments = documentation_comments("#{symbol_name}#{separator}#{method_name}")
        rbi_method = RBI::Method.new(
          method_name,
          is_singleton: constant.singleton_class?,
          visibility: visibility,
          comments: comments
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
          add_to_symbol_queue(type)
          sig << RBI::SigParam.new(name, type)
        end

        return_type = name_of_type(signature.return_type)
        sig.return_type = sanitize_signature_types(return_type)
        add_to_symbol_queue(sig.return_type)

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
      def symbol_ignored?(symbol_name)
        Compilers::SymbolTable::SymbolLoader.ignore_symbol?(symbol_name)
      end

      sig { params(mixin_name: String).returns(T::Boolean) }
      def filtered_mixin?(mixin_name)
        # filter T:: namespace mixins that aren't T::Props
        # T::Props and subconstants have semantic value
        mixin_name.start_with?("T::") && !mixin_name.start_with?("T::Props")
      end

      SPECIAL_METHOD_NAMES = T.let([
        "!", "~", "+@", "**", "-@", "*", "/", "%", "+", "-", "<<", ">>", "&", "|", "^",
        "<", "<=", "=>", ">", ">=", "==", "===", "!=", "=~", "!~", "<=>", "[]", "[]=", "`"
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

      sig { params(name: String).returns(T::Array[RBI::Comment]) }
      def documentation_comments(name)
        return [] unless @include_doc

        yard_docs = YARD::Registry.at(name)
        return [] unless yard_docs

        docstring = yard_docs.docstring
        return [] if /(copyright|license)/i.match?(docstring)

        docstring.lines
          .reject { |line| IGNORED_COMMENTS.any? { |comment| line.include?(comment) } }
          .map! { |line| RBI::Comment.new(line) }
      end
    end
  end
end
