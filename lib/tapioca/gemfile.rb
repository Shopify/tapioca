# frozen_string_literal: true
# typed: strict

require "bundler"

module Tapioca
  class Gemfile
    extend(T::Sig)

    Spec = T.type_alias(
      T.any(
        T.all(
          ::Bundler::StubSpecification,
          ::Bundler::RemoteSpecification
        ),
        ::Gem::Specification
      )
    )

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

    sig { void }
    def require
      T.unsafe(runtime).setup(*groups).require(*groups)
    end

    private

    sig { returns(File) }
    attr_reader(:gemfile, :lockfile)

    sig { returns(Bundler::Runtime) }
    def runtime
      Bundler::Runtime.new(File.dirname(gemfile.path), definition)
    end

    sig { returns(T::Array[Symbol]) }
    def groups
      definition.groups
    end

    sig { returns(Bundler::Definition) }
    def definition
      @definition ||= Bundler::Dsl.evaluate(gemfile, lockfile, {})
    end

    IGNORED_GEMS = T.let(%w{
      sorbet sorbet-static sorbet-runtime tapioca
    }.freeze, T::Array[String])

    sig { params(spec: Spec).returns(T::Boolean) }
    def ignore_gem_spec?(spec)
      IGNORED_GEMS.include?(spec.name) ||
        spec.full_gem_path.start_with?(gemfile_dir)
    end

    sig { returns(String) }
    def gemfile_dir
      File.expand_path(gemfile.path + "/..")
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
          Pathname.glob((Pathname.new(path) / "**/*.rb").to_s)
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
