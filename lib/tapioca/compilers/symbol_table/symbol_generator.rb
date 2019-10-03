# frozen_string_literal: true
# typed: true

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
          symbols
            .sort
            .map(&method(:generate_from_symbol))
            .compact
            .join("\n\n")
            .concat("\n")
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

        sig { params(symbol: String).returns(T.nilable(String)) }
        def generate_from_symbol(symbol)
          constant = resolve_constant(symbol)

          return unless constant

          compile(symbol, constant)
        end

        sig { params(symbol: String).returns(BasicObject) }
        def resolve_constant(symbol)
          Object.const_get(symbol, false)
        rescue NameError, LoadError, RuntimeError, ArgumentError, TypeError
          nil
        end

        sig { params(name: T.nilable(String), constant: BasicObject).returns(T.nilable(String)) }
        def compile(name, constant)
          return unless constant
          return unless name
          return if name.strip.empty?
          return if name.start_with?('#<')
          return if name.downcase == name
          return if alias_namespaced?(name)
          return if seen?(name)
          return unless parent_declares_constant?(name)

          mark_seen(name)
          compile_constant(name, constant)
        end

        sig { params(name: String, constant: BasicObject).returns(T.nilable(String)) }
        def compile_constant(name, constant)
          case constant
          when Module
            if name_of(constant) != name
              compile_alias(name, constant)
            else
              compile_module(name, constant)
            end
          else
            compile_object(name, constant)
          end
        end

        sig { params(name: String, constant: Module).returns(T.nilable(String)) }
        def compile_alias(name, constant)
          return if symbol_ignored?(name)

          constant_name = name_of(constant)
          add_to_alias_namespace(name)

          return if IGNORED_SYMBOLS.include?(name)

          indented("#{name} = #{constant_name}")
        end

        sig { params(name: String, value: BasicObject).returns(T.nilable(String)) }
        def compile_object(name, value)
          indented("#{name} = T.let(T.unsafe(nil), #{type_name_of(value)})")
        end

        sig { params(value: BasicObject).returns(String) }
        def type_name_of(value)
          klass = class_of(value)

          public_module?(klass) && name_of(klass) || "T.untyped"
        end

        sig { params(name: String, constant: Module).returns(T.nilable(String)) }
        def compile_module(name, constant)
          return unless public_module?(constant)
          return unless defined_in_gem?(constant, strict: false)

          header =
            if constant.is_a?(Class)
              indented("class #{name}#{compile_superclass(constant)}")
            else
              indented("module #{name}")
            end

          body = compile_body(name, constant)

          return if symbol_ignored?(name) && body.nil?

          [
            header,
            body,
            indented("end"),
            compile_subconstants(name, constant),
          ].select { |b| !b.nil? && b.strip != "" }.join("\n")
        end

        sig { params(name: String, constant: Module).returns(T.nilable(String)) }
        def compile_body(name, constant)
          with_indentation do
            methods = compile_methods(name, constant)

            return if symbol_ignored?(name) && methods.nil?

            [
              compile_mixins(constant),
              methods,
            ].select { |b| b != "" }.join("\n\n")
          end
        end

        sig { params(name: String, constant: Module).returns(T.nilable(String)) }
        def compile_subconstants(name, constant)
          output = constants_of(constant).sort.uniq.map do |constant_name|
            symbol = (name == "Object" ? "" : name) + "::#{constant_name}"
            subconstant = resolve_constant(symbol)

            # Don't compile modules of Object because Object::Foo == Foo
            # Don't compile modules of BasicObject because BasicObject::BasicObject == BasicObject
            next if (Object == constant || BasicObject == constant) && Module === subconstant
            next unless subconstant

            compile(symbol, subconstant)
          end.compact

          return "" if output.empty?

          "\n" + output.join("\n\n")
        end

        sig { params(constant: Class).returns(String) }
        def compile_superclass(constant)
          superclass = T.let(nil, T.nilable(Class)) # rubocop:disable Lint/UselessAssignment

          while (superclass = superclass_of(constant))
            constant_name = name_of(constant)
            constant = superclass

            # Some classes have superclasses that are private constants
            # so if we generate code with that superclass, the output
            # will not be compilable (since private constants are not
            # publicly visible).
            #
            # So we skip superclasses that are not public and walk up the
            # chain.
            next unless public_module?(superclass)

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

          return "" if superclass == ::Object || superclass == ::Delegator
          return "" if superclass.nil?

          name = name_of(superclass)
          return "" if name.nil? || name.empty?

          " < ::#{name}"
        end

        sig { params(constant: Module).returns(String) }
        def compile_mixins(constant)
          ignorable_ancestors =
            if constant.is_a?(Class)
              ancestors = constant.superclass&.ancestors || Object.ancestors
              Set.new(ancestors)
            else
              Module.ancestors
            end

          inherited_singleton_class_ancestors =
            if constant.is_a?(Class)
              Set.new(constant.superclass.singleton_class.ancestors)
            else
              Module.ancestors
            end

          interesting_ancestors =
            constant.ancestors.reject { |mod| ignorable_ancestors.include?(mod) }

          prepend = interesting_ancestors.take_while { |c| !are_equal?(constant, c) }
          include = interesting_ancestors.drop(prepend.size + 1)
          extend  = constant.singleton_class.ancestors
            .reject do |mod|
              mod == constant.singleton_class ||
                inherited_singleton_class_ancestors.include?(mod) ||
                !public_module?(mod) ||
                Module != class_of(mod)
            end

          prepends = prepend
            .select(&method(:name_of))
            .select(&method(:public_module?))
            .map do |mod|
              # TODO: Sorbet currently does not handle prepend
              # properly for method resolution, so we generate an
              # include statement instead
              indented("include(#{qualified_name_of(mod)})")
            end

          includes = include
            .select(&method(:name_of))
            .select(&method(:public_module?))
            .map do |mod|
              indented("include(#{qualified_name_of(mod)})")
            end

          extends = extend
            .select(&method(:name_of))
            .select(&method(:public_module?))
            .map do |mod|
              indented("extend(#{qualified_name_of(mod)})")
            end

          mixes_class_methods = extend
            .select do |mod|
              qualified_name_of(mod) == "::ActiveSupport::Concern" &&
                Module === resolve_constant("#{name_of(constant)}::ClassMethods")
            end
            .first(1)
            .flat_map do
              ["", indented("mixes_in_class_methods(ClassMethods)")]
            end

          (prepends + includes + extends + mixes_class_methods).join("\n")
        end

        sig { params(name: String, constant: Module).returns(T.nilable(String)) }
        def compile_methods(name, constant)
          initialize_method = compile_method(
            name,
            constant,
            initialize_method_for(constant)
          )

          instance_methods = compile_directly_owned_methods(name, constant)
          singleton_methods = compile_directly_owned_methods(name, constant.singleton_class, [:public])

          return if symbol_ignored?(name) && instance_methods.empty? && singleton_methods.empty?

          [
            initialize_method || "",
            instance_methods,
            singleton_methods,
          ].select { |b| b.strip != "" }.join("\n\n")
        end

        sig { params(module_name: String, mod: Module, for_visibility: T::Array[Symbol]).returns(String) }
        def compile_directly_owned_methods(module_name, mod, for_visibility = [:public, :protected, :private])
          method_names_by_visibility(mod)
            .delete_if { |visibility, _method_list| !for_visibility.include?(visibility) }
            .flat_map do |visibility, method_list|
              compiled = method_list.sort!.map do |name|
                next if name == :initialize
                compile_method(module_name, mod, mod.instance_method(name))
              end
              compiled.compact!

              unless compiled.empty? || visibility == :public
                # add visibility badge
                compiled.unshift('', indented(visibility.to_s), '')
              end

              compiled
            end
            .compact
            .join("\n")
        end

        sig { params(mod: Module).returns(T::Hash[Symbol, T::Array[Symbol]]) }
        def method_names_by_visibility(mod)
          {
            public: Module.instance_method(:public_instance_methods).bind(mod).call,
            protected: Module.instance_method(:protected_instance_methods).bind(mod).call,
            private: Module.instance_method(:private_instance_methods).bind(mod).call,
          }
        end

        sig do
          params(
            symbol_name: String,
            constant: Module,
            method: T.nilable(UnboundMethod)
          ).returns(T.nilable(String))
        end
        def compile_method(symbol_name, constant, method)
          return unless method
          return unless method.owner == constant
          return if symbol_ignored?(symbol_name) && !method_in_gem?(method)

          method_name = method.name.to_s
          return unless valid_method_name?(method_name)

          params = T.let(method.parameters, T::Array[T::Array[Symbol]])
          parameters = params.map do |(type, name)|
            name ||= :_

            case type
            when :req
              name.to_s
            when :opt
              "#{name} = _"
            when :rest
              "*#{name}"
            when :keyreq
              "#{name}:"
            when :key
              "#{name}: _"
            when :keyrest
              "**#{name}"
            when :block
              "&#{name}"
            end
          end.join(', ')

          method_name.prepend(constant.singleton_class? ? 'self.' : '')
          parameters = "(#{parameters})" if parameters != ""

          indented("def #{method_name}#{parameters}; end")
        end

        sig { params(symbol_name: String).returns(T::Boolean) }
        def symbol_ignored?(symbol_name)
          SymbolLoader.ignore_symbol?(symbol_name)
        end

        sig { params(path: String).returns(T::Boolean) }
        def path_in_gem?(path)
          path.start_with?(gem.full_gem_path)
        end

        SPECIAL_METHOD_NAMES = %w[! ~ +@ ** -@ * / % + - << >> & | ^ < <= => > >= == === != =~ !~ <=> [] []= `]

        sig { params(name: String).returns(T::Boolean) }
        def valid_method_name?(name)
          return true if SPECIAL_METHOD_NAMES.include?(name)
          !!name.match(/^[[:word:]]+[?!=]?$/)
        end

        sig do
          type_parameters(:U)
            .params(
              _blk: T.proc
                .returns(T.type_parameter(:U))
            )
            .returns(T.type_parameter(:U))
        end
        def with_indentation(&_blk)
          @indent += 2
          yield
        ensure
          @indent -= 2
        end

        sig { params(str: String).returns(String) }
        def indented(str)
          " " * @indent + str
        end

        sig { params(method: UnboundMethod).returns(T::Boolean) }
        def method_in_gem?(method)
          source_location = method.source_location&.first
          return false if source_location.nil?

          path_in_gem?(source_location)
        end

        sig { params(constant: Module, strict: T::Boolean).returns(T::Boolean) }
        def defined_in_gem?(constant, strict: true)
          files = Set.new(get_file_candidates(constant))
            .merge(Tapioca::ConstantLocator.files_for(constant))

          return !strict if files.empty?

          files.any? do |file|
            path_in_gem?(file)
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

        def parent_declares_constant?(name)
          name_parts = name.split("::")

          parent_name = name_parts[0...-1].join("::")
          parent_name = parent_name[2..-1] if parent_name.start_with?("::")
          parent_name = 'Object' if parent_name == ""
          parent = T.cast(resolve_constant(parent_name), T.nilable(Module))

          return false unless parent

          constants_of(parent).include?(name_parts.last.to_sym)
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

        sig { params(constant: BasicObject).returns(Class) }
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

        sig { params(constant: Module).returns(T.nilable(String)) }
        def name_of(constant)
          name = name_of_proxy_target(constant)
          return name if name
          name = raw_name_of(constant)
          return if name.nil?
          return unless are_equal?(constant, resolve_constant(name))
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
            return nil
          end

          name_of(target)
        end

        sig { params(constant: Module).returns(T.nilable(String)) }
        def qualified_name_of(constant)
          name = name_of(constant)
          return if name.nil?
          name.prepend("::") unless name.start_with?("::")
          name
        end

        sig { params(constant: Class).returns(T.nilable(Class)) }
        def superclass_of(constant)
          Class.instance_method(:superclass).bind(constant).call
        end

        sig { params(constant: Module, other: BasicObject).returns(T::Boolean) }
        def are_equal?(constant, other)
          BasicObject.instance_method(:equal?).bind(constant).call(other)
        end
      end
    end
  end
end
