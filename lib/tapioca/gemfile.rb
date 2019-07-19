# frozen_string_literal: true
# typed: strict

require "bundler"

module Tapioca
  class Gemfile
    extend(T::Sig)

    Spec = T.type_alias(T.any(::Bundler::StubSpecification, ::Gem::Specification))

    sig { void }
    def initialize
      @gemfile = T.let(File.new(Bundler.default_gemfile), File)
      @lockfile = T.let(File.new(Bundler.default_lockfile), File)
      @dependencies = T.let(nil, T.nilable(T::Array[Gem]))
      @definition = T.let(nil, T.nilable(Bundler::Definition))
    end

    sig { returns(T::Array[Gem]) }
    def dependencies
      @dependencies ||= begin
        specs = definition.specs.to_a

        definition
          .resolve
          .materialize(specs)
          .reject { |spec| ignore_gem_spec?(spec) }
          .map { |spec| Gem.new(spec) }
          .uniq(&:rbi_file_name)
          .sort_by(&:rbi_file_name)
      end
    end

    sig { params(gem_name: String).returns(T.nilable(Gem)) }
    def gem(gem_name)
      dependencies.detect { |dep| dep.name == gem_name }
    end

    sig { params(initialize_file: T.nilable(String), require_file: T.nilable(String)).void }
    def require_bundle(initialize_file, require_file)
      require(initialize_file) if initialize_file && File.exist?(initialize_file)

      runtime = Bundler::Runtime.new(File.dirname(gemfile.path), definition)
      groups = Bundler.definition.groups
      runtime.setup(*groups).require(*groups)

      require(require_file) if require_file && File.exist?(require_file)

      load_rails_engines
    end

    private

    sig { returns(File) }
    attr_reader(:gemfile, :lockfile)

    sig { returns(Bundler::Definition) }
    def definition
      @definition ||= Bundler::Dsl.evaluate(gemfile, lockfile, {})
    end

    sig { params(spec: Spec).returns(T::Boolean) }
    def ignore_gem_spec?(spec)
      ["sorbet", "sorbet-static", "sorbet-runtime"].include?(spec.name) ||
        spec.full_gem_path.start_with?(gemfile_dir)
    end

    sig { returns(String) }
    def gemfile_dir
      File.expand_path(gemfile.path + "/..")
    end

    sig { returns(T::Array[T.untyped]) }
    def rails_engines
      engines = []

      return engines unless Object.const_defined?("Rails::Engine")

      base = Object.const_get("Rails::Engine")
      ObjectSpace.each_object(base.singleton_class) do |k|
        k = T.cast(k, Class)
        next if k.singleton_class?
        engines.unshift(k) unless k == base
      end

      engines.reject(&:abstract_railtie?)
    end

    sig { void }
    def load_rails_engines
      rails_engines.each do |engine|
        errored_files = []

        engine.config.eager_load_paths.each do |load_path|
          Dir.glob("#{load_path}/**/*.rb").sort.each do |file|
            require(file)
          rescue LoadError, StandardError
            errored_files << file
          end
        end

        # Try files that have errored one more time
        # It might have been a load order problem
        errored_files.each do |file|
          require(file)
        rescue LoadError, StandardError
          nil
        end
      end
    end

    class Gem
      extend(T::Sig)

      sig { params(spec: Spec).void }
      def initialize(spec)
        @spec = T.let(spec, Tapioca::Gemfile::Spec)
      end

      sig { returns(String) }
      def full_gem_path
        @spec.full_gem_path.to_s
      end

      sig { returns(T::Array[Pathname]) }
      def files
        @spec.full_require_paths.flat_map do |path|
          Pathname.new(path).glob("**/*.rb")
        end
      end

      sig { returns(String) }
      def name
        @spec.name
      end

      sig { returns(::Gem::Version) }
      def version
        @spec.version
      end

      sig { returns(String) }
      def rbi_file_name
        "#{name}@#{version}.rbi"
      end
    end
  end
end
