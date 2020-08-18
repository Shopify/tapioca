# frozen_string_literal: true
# typed: strict

require "bundler"

module Tapioca
  class Gemfile
    extend(T::Sig)

    Spec = T.type_alias do
      T.any(
        T.all(
          ::Bundler::StubSpecification,
          ::Bundler::RemoteSpecification
        ),
        ::Gem::Specification
      )
    end

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
          .map { |spec| Gem.new(spec) }
          .reject { |gem| gem.ignore?(dir) }
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

    sig { returns(String) }
    def dir
      File.expand_path(gemfile.path + "/..")
    end

    class Gem
      extend(T::Sig)

      IGNORED_GEMS = T.let(%w{
        sorbet sorbet-static sorbet-runtime
      }.freeze, T::Array[String])

      sig { returns(String) }
      attr_reader :full_gem_path

      sig { params(spec: Spec).void }
      def initialize(spec)
        @spec = T.let(spec, Tapioca::Gemfile::Spec)
        real_gem_path = to_realpath(@spec.full_gem_path)
        @full_gem_path = T.let(real_gem_path, String)
      end

      sig { params(gemfile_dir: String).returns(T::Boolean) }
      def ignore?(gemfile_dir)
        gem_ignored? || gem_in_app_dir?(gemfile_dir)
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

      sig { params(path: String).returns(T::Boolean) }
      def contains_path?(path)
        to_realpath(path).start_with?(full_gem_path)
      end

      private

      sig { params(path: T.any(String, Pathname)).returns(String) }
      def to_realpath(path)
        path_string = path.to_s
        path_string = File.realpath(path_string) if File.exist?(path_string)
        path_string
      end

      sig { returns(T::Boolean) }
      def gem_ignored?
        IGNORED_GEMS.include?(name)
      end

      sig { params(gemfile_dir: String).returns(T::Boolean) }
      def gem_in_app_dir?(gemfile_dir)
        !gem_in_bundle_path? && full_gem_path.start_with?(gemfile_dir)
      end

      sig { returns(T::Boolean) }
      def gem_in_bundle_path?
        full_gem_path.start_with?(Bundler.bundle_path.to_s)
      end
    end
  end
end
