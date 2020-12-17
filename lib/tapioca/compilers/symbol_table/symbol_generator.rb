# typed: true
# frozen_string_literal: true

require 'pathname'

module Tapioca
  module Compilers
    module SymbolTable
      class SymbolGenerator
        extend(T::Sig)

        IGNORED_SYMBOLS = %w{
          YAML
          MiniTest
          Mutex
        }

        attr_reader(:gem, :indent)

        sig { params(gem: Gemfile::Gem, indent: Integer).void }
        def initialize(gem, indent = 0)
          @gem = gem
          @indent = indent
          @seen = Set.new
          @alias_namespace ||= Set.new
        end

        sig { returns(String) }
        def generate
          rbi = RBI::Tree.new
          symbols.sort.each { |symbol| generate_from_symbol(rbi, symbol) }
          rbi.nest_singleton_methods!
          rbi.nest_non_public_methods!
          rbi.group_nodes!
          rbi.sort_nodes!
          rbi.string
        end

        private

        sig { returns(T::Set[String]) }
        def symbols
          symbols = Tapioca::Compilers::SymbolTable::SymbolLoader.list_from_paths(gem.files)
          symbols.union(engine_symbols(symbols))
        end

        sig { params(symbols: T::Set[String]).returns(T::Set[String]) }
        def engine_symbols(symbols)
          return Set.new unless Object.const_defined?("Rails::Engine")

          engine = Object.const_get("Rails::Engine")
            .descendants.reject(&:abstract_railtie?)
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
          constant = resolve_constant(symbol)

          return unless constant

          compile(tree, symbol, constant)
        end

        sig do
          params(
            symbol: String,
            inherit: T::Boolean,
            namespace: Module
          ).returns(BasicObject).checked(:never)
        end
        def resolve_constant(symbol, inherit: false, namespace: Object)
          namespace.const_get(symbol, inherit)
        rescue NameError, LoadError, RuntimeError, ArgumentError, TypeError
          nil
        end

        sig { params(tree: RBI::Tree, name: T.nilable(String), constant: BasicObject).void.checked(:never) }
        def compile(tree, name, constant)
          return unless constant
          return unless name
          return if name.strip.empty?
          return if name.start_with?('#<')
          return if name.downcase == name
          return if alias_namespaced?(name)
          return if seen?(name)
          return if T::Enum === constant # T::Enum instances are defined via `compile_enums`

          mark_seen(name)
          compile_constant(tree, name, constant)
        end

        sig { params(tree: RBI::Tree, name: String, constant: BasicObject).void.checked(:never) }
        def compile_constant(tree, name, constant)
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
          klass_name = name_of(klass)

          return if klass_name&.start_with?("T::Types::", "T::Private::")

          type_name = public_module?(klass) && klass_name || "T.untyped"
          tree << RBI::Const.new(name, "T.let(T.unsafe(nil), #{type_name})")
        end

        sig { params(tree: RBI::Tree, name: String, constant: Module).void }
        def compile_module(tree, name, constant)
          return unless defined_in_gem?(constant, strict: false)

          scope =
            if constant.is_a?(Class)
              superclass = compile_superclass(constant)
              RBI::Class.new(name, superclass_name: superclass)
            else
              RBI::Module.new(name)
            end

          compile_body(scope, name, constant)

          return if symbol_ignored?(name) && scope.empty?

          tree << scope
          compile_subconstants(tree, name, constant)
        end

        sig { params(tree: RBI::Tree, name: String, constant: Module).void }
        def compile_body(tree, name, constant)
          compile_methods(tree, name, constant)
          compile_module_helpers(tree, constant)
          compile_type_variables(tree, constant)
          compile_mixins(tree, constant)
          compile_mixes_in_class_methods(tree, constant)
          compile_props(tree, constant)
          compile_enums(tree, constant)
        end

        sig { params(tree: RBI::Tree, constant: Module).void }
        def compile_module_helpers(tree, constant)
          abstract_type = T::Private::Abstract::Data.get(constant, :abstract_type)

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
            subconstant = resolve_constant(symbol)

            # Don't compile modules of Object because Object::Foo == Foo
            # Don't compile modules of BasicObject because BasicObject::BasicObject == BasicObject
            next if (Object == constant || BasicObject == constant) && Module === subconstant
            next unless subconstant

            compile(tree, symbol, subconstant)
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

          # Create a map of subconstants (via their object ids) to their names.
          # We need this later when we want to lookup the name of the registered type
          # variable via the value of the type variable constant.
          subconstant_to_name_lookup = constants_of(constant).map do |constant_name|
            [
              object_id_of(resolve_constant(constant_name.to_s, namespace: constant)),
              constant_name,
            ]
          end.to_h

          # Map each type variable to its string representation.
          #
          # Each entry of `type_variables` maps an object_id to a String,
          # and the order they are inserted into the hash is the order they should be
          # defined in the source code.
          #
          # By looping over these entries and then getting the actual constant name
          # from the `subconstant_to_name_lookup` we defined above, gives us all the
          # information we need to serialize type variable definitions.
          type_variable_declarations = type_variables.map do |type_variable_id, serialized_type_variable|
            constant_name = subconstant_to_name_lookup[type_variable_id]
            # Here, we know that constant_value will be an instance of
            # T::Types::CustomTypeVariable, which knows how to serialize
            # itself to a type_member/type_template
            tree << RBI::TypeMember.new(constant_name.to_s, serialized_type_variable)
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
            superclass_name = T.must(name_of(superclass))
            resolved_superclass = resolve_constant(superclass_name)
            next unless Module === resolved_superclass
            next if name_of(resolved_superclass) == constant_name

            # We found a suitable superclass
            break
          end

          return if superclass == ::Object || superclass == ::Delegator
          return if superclass.nil?

          name = name_of(superclass)
          return if name.nil? || name.empty?

          "::#{name}"
        end

        sig { params(tree: RBI::Tree, constant: Module).void }
        def compile_mixins(tree, constant)
          singleton_class = singleton_class_of(constant)

          interesting_ancestors = interesting_ancestors_of(constant)
          interesting_singleton_class_ancestors = interesting_ancestors_of(singleton_class)

          prepend = interesting_ancestors.take_while { |c| !are_equal?(constant, c) }
          include = interesting_ancestors.drop(prepend.size + 1)
          extend  = interesting_singleton_class_ancestors.reject do |mod|
            !public_module?(mod) || Module != class_of(mod) || are_equal?(mod, singleton_class)
          end

          prepend
            .reverse
            .select { |mod| (name = name_of(mod)) && !name.start_with?("T::") }
            .select(&method(:public_module?))
            .map do |mod|
              # TODO: Sorbet currently does not handle prepend
              # properly for method resolution, so we generate an
              # include statement instead
              qname = qualified_name_of(mod)
              tree << RBI::Include.new(T.must(qname))
            end

          include
            .reverse
            .select { |mod| (name = name_of(mod)) && !name.start_with?("T::") }
            .select(&method(:public_module?))
            .map do |mod|
              qname = qualified_name_of(mod)
              tree << RBI::Include.new(T.must(qname))
            end

          extend
            .reverse
            .select { |mod| (name = name_of(mod)) && !name.start_with?("T::") }
            .select(&method(:public_module?))
            .map do |mod|
              qname = qualified_name_of(mod)
              tree << RBI::Extend.new(T.must(qname))
            end
        end

        sig { params(tree: RBI::Tree, constant: Module).void }
        def compile_mixes_in_class_methods(tree, constant)
          return if constant.is_a?(Class)

          mixins_from_modules = {}

          Class.new do
            # rubocop:disable Style/MethodMissingSuper, Style/MissingRespondToMissing
            def method_missing(symbol, *args)
            end

            define_singleton_method(:include) do |mod|
              begin
                before = singleton_class.ancestors
                super(mod).tap do
                  mixins_from_modules[mod] = singleton_class.ancestors - before
                end
              rescue Exception # rubocop:disable Lint/RescueException
                # this is a best effort, bail if we can't perform this
              end
            end

            class << self
              def method_missing(symbol, *args)
              end
            end
            # rubocop:enable Style/MethodMissingSuper, Style/MissingRespondToMissing
          end.include(constant)

          all_dynamic_extends = mixins_from_modules.delete(constant)
          all_dynamic_includes = mixins_from_modules.keys
          dynamic_extends_from_dynamic_includes = mixins_from_modules.values.flatten
          dynamic_extends = all_dynamic_extends - dynamic_extends_from_dynamic_includes

          all_dynamic_includes
            .select { |mod| (name = name_of(mod)) && !name.start_with?("T::") }
            .select(&method(:public_module?))
            .map do |mod|
              qname = qualified_name_of(mod)
              tree << RBI::Include.new(T.must(qname))
            end.join("\n")

          ancestors = singleton_class_of(constant).ancestors
          extends_as_concern = ancestors.any? do |mod|
            qualified_name_of(mod) == "::ActiveSupport::Concern"
          end
          class_methods_module = resolve_constant("#{name_of(constant)}::ClassMethods")

          mixed_in_module = if extends_as_concern && Module === class_methods_module
            class_methods_module
          else
            dynamic_extends.find do |mod|
              mod != constant && public_module?(mod)
            end
          end

          return if mixed_in_module.nil?

          qualified_name = qualified_name_of(mixed_in_module)
          return if qualified_name.nil? || qualified_name == ""

          tree << RBI::MixesInClassMethods.new(qualified_name)
        rescue
          nil # silence errors
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
                  RBI::Visibility::Protected
                when :private
                  RBI::Visibility::Private
                else
                  RBI::Visibility::Public
                end
                compile_method(tree, module_name, mod, mod.instance_method(name), vis)
              end
            end
        end

        sig { params(mod: Module).returns(T::Hash[Symbol, T::Array[Symbol]]) }
        def method_names_by_visibility(mod)
          {
            public: Module.instance_method(:public_instance_methods).bind(mod).call,
            protected: Module.instance_method(:protected_instance_methods).bind(mod).call,
            private: Module.instance_method(:private_instance_methods).bind(mod).call,
          }
        end

        sig { params(constant: Module, method_name: String).returns(T::Boolean) }
        def struct_method?(constant, method_name)
          return false unless T::Props::ClassMethods === constant

          constant
            .props
            .keys
            .include?(method_name.gsub(/=$/, '').to_sym)
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
        def compile_method(tree, symbol_name, constant, method, visibility = RBI::Visibility::Public)
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

            unless name
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

              name = if writer_method_with_sig
                T.must(method_name[0...-1]).to_sym
              else
                fallback_arg_name
              end
            end

            # Sanitize param names
            name = name.to_s.gsub(/[^a-zA-Z0-9_]/, fallback_arg_name)

            [type, name]
          end

          rbi_method = RBI::Method.new(method_name, is_singleton: constant.singleton_class?, visibility: visibility)
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
            sig << RBI::SigParam.new(name, type)
          end

          return_type = type_of(signature.return_type)
          sig.return_type = sanitize_signature_types(return_type)

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

        sig { params(symbol_name: String).returns(T::Boolean) }
        def symbol_ignored?(symbol_name)
          SymbolLoader.ignore_symbol?(symbol_name)
        end

        SPECIAL_METHOD_NAMES = %w[! ~ +@ ** -@ * / % + - << >> & | ^ < <= => > >= == === != =~ !~ <=> [] []= `]

        sig { params(name: String).returns(T::Boolean) }
        def valid_method_name?(name)
          return true if SPECIAL_METHOD_NAMES.include?(name)
          !!name.match(/^[[:word:]]+[?!=]?$/)
        end

        sig { params(method: UnboundMethod).returns(T::Boolean) }
        def method_in_gem?(method)
          source_location = method.source_location&.first
          return false if source_location.nil?

          gem.contains_path?(source_location)
        end

        sig { params(constant: Module, strict: T::Boolean).returns(T::Boolean) }
        def defined_in_gem?(constant, strict: true)
          files = Set.new(get_file_candidates(constant))
            .merge(Tapioca::ConstantLocator.files_for(constant))

          return !strict if files.empty?

          files.any? do |file|
            gem.contains_path?(file)
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

        def initialize_method_for(constant)
          constant.instance_method(:initialize)
        rescue
          nil
        end

        sig { params(constant: Module).returns(T::Boolean) }
        def public_module?(constant)
          constant_name = name_of(constant)
          return false unless constant_name
          return false if constant_name.start_with?('T::Private')

          begin
            # can't use !! here because the constant might override ! and mess with us
            Module === eval(constant_name) # rubocop:disable Security/Eval
          rescue NameError
            false
          end
        end

        sig { params(constant: BasicObject).returns(Class).checked(:never) }
        def class_of(constant)
          Kernel.instance_method(:class).bind(constant).call
        end

        sig { params(constant: Module).returns(T::Array[Symbol]) }
        def constants_of(constant)
          Module.instance_method(:constants).bind(constant).call(false)
        end

        sig { params(constant: Module).returns(T.nilable(String)) }
        def raw_name_of(constant)
          Module.instance_method(:name).bind(constant).call
        end

        sig { params(constant: Module).returns(Class) }
        def singleton_class_of(constant)
          Object.instance_method(:singleton_class).bind(constant).call
        end

        sig { params(constant: Module).returns(T::Array[Module]) }
        def ancestors_of(constant)
          Module.instance_method(:ancestors).bind(constant).call
        end

        sig { params(constant: Module).returns(T::Array[Module]) }
        def inherited_ancestors_of(constant)
          if Class === constant
            ancestors_of(superclass_of(constant) || Object)
          else
            Module.ancestors
          end
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
          name = name_of_proxy_target(constant)
          return name if name
          name = raw_name_of(constant)
          return if name.nil?
          return unless are_equal?(constant, resolve_constant(name, inherit: true))
          name = "Struct" if name =~ /^(::)?Struct::[^:]+$/
          name
        end

        sig { params(constant: Module).returns(T.nilable(String)) }
        def name_of_proxy_target(constant)
          klass = class_of(constant)
          return unless raw_name_of(klass) == "ActiveSupport::Deprecation::DeprecatedConstantProxy"
          # We are dealing with a ActiveSupport::Deprecation::DeprecatedConstantProxy
          # so try to get the name of the target class
          begin
            target = Kernel.instance_method(:send).bind(constant).call(:target)
          rescue NoMethodError
            return
          end

          raw_name_of(target)
        end

        sig { params(constant: Module).returns(T.nilable(String)) }
        def qualified_name_of(constant)
          name = name_of(constant)
          return if name.nil?

          if name.start_with?("::")
            name
          else
            "::#{name}"
          end
        end

        sig { params(constant: Class).returns(T.nilable(Class)) }
        def superclass_of(constant)
          Class.instance_method(:superclass).bind(constant).call
        end

        sig { params(method: T.any(UnboundMethod, Method)).returns(T.untyped) }
        def signature_of(method)
          T::Private::Methods.signature_for_method(method)
        rescue LoadError, StandardError
          nil
        end

        sig { params(sig_string: String).returns(String) }
        def sanitize_signature_types(sig_string)
          sig_string
            .gsub(".returns(<VOID>)", ".void")
            .gsub("<VOID>", "void")
            .gsub("<NOT-TYPED>", "T.untyped")
            .gsub(".params()", "")
        end

        sig { params(constant: T::Types::Base).returns(String) }
        def type_of(constant)
          constant.to_s.gsub(/\bAttachedClass\b/, "T.attached_class")
        end

        sig { params(object: BasicObject).returns(Integer).checked(:never) }
        def object_id_of(object)
          Object.instance_method(:object_id).bind(object).call
        end

        sig { params(constant: Module, other: BasicObject).returns(T::Boolean).checked(:never) }
        def are_equal?(constant, other)
          BasicObject.instance_method(:equal?).bind(constant).call(other)
        end
      end
    end
  end
end
