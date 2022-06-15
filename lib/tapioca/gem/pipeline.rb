# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    class Pipeline < RBIGenerator
      extend T::Sig
      include Runtime::Reflection
      include RBIHelper

      IGNORED_SYMBOLS = T.let(["YAML", "MiniTest", "Mutex"], T::Array[String])

      sig { returns(Gemfile::GemSpec) }
      attr_reader :gem

      sig { params(gem: Gemfile::GemSpec, include_doc: T::Boolean).void }
      def initialize(gem, include_doc: false)
        super()

        @gem = gem
        @payload_symbols = T.let(Static::SymbolLoader.payload_symbols, T::Set[String])
        @bootstrap_symbols = T.let(Static::SymbolLoader.gem_symbols(@gem).union(Static::SymbolLoader.engine_symbols),
          T::Set[String])
        @bootstrap_symbols.each { |symbol| push_symbol(symbol) }

        @node_listeners << Gem::Listeners::YardDoc.new(self) if include_doc
        @node_listeners << Gem::Listeners::ForeignConstants.new(self)
        @node_listeners << Gem::Listeners::RemoveEmptyPayloadScopes.new(self)
      end

      # Constants and properties filtering

      sig { params(name: String, constant: BasicObject).returns(T::Boolean).checked(:never) }
      def skip_subconstant?(name, constant)
        symbol_in_payload?(name)
      end

      sig { override.params(name: String).returns(T::Boolean) }
      def skip_symbol?(name)
        symbol_in_payload?(name) && !@bootstrap_symbols.include?(name)
      end

      sig { override.params(name: String, constant: Module).returns(T::Boolean) }
      def skip_alias?(name, constant)
        symbol_in_payload?(name)
      end

      sig { override.params(name: String, constant: BasicObject).returns(T::Boolean).checked(:never) }
      def skip_object?(name, constant)
        symbol_in_payload?(name)
      end

      sig { override.params(name: String, constant: Module).returns(T::Boolean) }
      def skip_foreign_constant?(name, constant)
        Tapioca::TypeVariableModule === constant
      end

      sig { override.params(name: String, constant: Module).returns(T::Boolean) }
      def skip_module?(name, constant)
        Tapioca::TypeVariableModule === constant || !defined_in_gem?(constant, strict: false)
      end

      sig { override.params(constant: Module, locations: T::Array[String]).returns(T::Boolean) }
      def skip_mixin?(constant, locations)
        defined_by_application?(constant) || !mixed_in_by_gem?(locations)
      end

      sig { override.params(symbol_name: String, constant: Module, method: UnboundMethod).returns(T::Boolean) }
      def skip_method?(symbol_name, constant, method)
        symbol_in_payload?(symbol_name) && !method_in_gem?(method)
      end

      private

      # Constants and properties filtering

      sig { params(symbol_name: String).returns(T::Boolean) }
      def symbol_in_payload?(symbol_name)
        symbol_name = symbol_name[2..-1] if symbol_name.start_with?("::")
        return false unless symbol_name

        @payload_symbols.include?(symbol_name)
      end

      sig { params(method: UnboundMethod).returns(T::Boolean) }
      def method_in_gem?(method)
        source_location = method.source_location&.first
        return false if source_location.nil?

        @gem.contains_path?(source_location)
      end

      # Compiling

      sig { params(name: String, constant: Module).void }
      def compile_alias(name, constant)
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

      sig { params(constant: Module, strict: T::Boolean).returns(T::Boolean) }
      def defined_in_gem?(constant, strict: true)
        files = Set.new(get_file_candidates(constant))
          .merge(Runtime::Trackers::ConstantDefinition.files_for(constant))

        return !strict if files.empty?

        files.any? do |file|
          @gem.contains_path?(file)
        end
      end

      sig do
        params(
          locations: T::Array[String]
        ).returns(T::Boolean)
      end
      def mixed_in_by_gem?(locations)
        locations.compact.any? { |location| gem.contains_path?(location) }
      end

      sig do
        params(
          constant: Module
        ).returns(T::Boolean)
      end
      def defined_by_application?(constant)
        application_dir = (Bundler.default_gemfile / "..").to_s
        Tapioca::Runtime::Trackers::ConstantDefinition.files_for(constant).any? do |location|
          location.start_with?(application_dir) && !in_bundle_path?(location)
        end
      end

      sig { params(path: String).returns(T::Boolean) }
      def in_bundle_path?(path)
        path.start_with?(Bundler.bundle_path.to_s, Bundler.app_cache.to_s)
      end

      sig { params(constant: Module).returns(T::Array[String]) }
      def get_file_candidates(constant)
        wrapped_module = Pry::WrappedModule.new(constant)

        wrapped_module.candidates.map(&:file).to_a.compact
      rescue ArgumentError, NameError
        []
      end
    end
  end
end
