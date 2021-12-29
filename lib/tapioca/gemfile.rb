# typed: strict
# frozen_string_literal: true

require "bundler"
require "logger"
require "yard-sorbet"

module Tapioca
  class Gemfile
    extend(T::Sig)

    Spec = T.type_alias do
      T.any(
        ::Bundler::StubSpecification,
        ::Gem::Specification
      )
    end

    sig { returns(Bundler::Definition) }
    attr_reader(:definition)

    sig { returns(T::Array[GemSpec]) }
    attr_reader(:dependencies)

    sig { returns(T::Array[String]) }
    attr_reader(:missing_specs)

    sig { void }
    def initialize
      @gemfile = T.let(File.new(Bundler.default_gemfile), File)
      @lockfile = T.let(File.new(Bundler.default_lockfile), File)
      @definition = T.let(Bundler::Dsl.evaluate(gemfile, lockfile, {}), Bundler::Definition)
      dependencies, missing_specs = load_dependencies
      @dependencies = T.let(dependencies, T::Array[GemSpec])
      @missing_specs = T.let(missing_specs, T::Array[String])
    end

    sig { params(gem_name: String).returns(T.nilable(GemSpec)) }
    def gem(gem_name)
      dependencies.detect { |dep| dep.name == gem_name }
    end

    sig { void }
    def require_bundle
      T.unsafe(runtime).require(*groups)
    end

    private

    sig { returns(File) }
    attr_reader(:gemfile, :lockfile)

    sig { returns([T::Array[GemSpec], T::Array[String]]) }
    def load_dependencies
      materialized_dependencies, missing_specs = materialize_deps
      dependencies = materialized_dependencies
        .map { |spec| GemSpec.new(spec) }
        .reject { |gem| gem.ignore?(dir) }
        .uniq(&:rbi_file_name)
        .sort_by(&:rbi_file_name)
      [dependencies, missing_specs]
    end

    sig { returns([T::Enumerable[Spec], T::Array[String]]) }
    def materialize_deps
      deps = definition.locked_gems.dependencies.values
      missing_specs = T::Array[String].new
      materialized_dependencies = if definition.resolve.method(:materialize).arity == 1 # Support bundler >= v2.2.25
        md = definition.resolve.materialize(deps)
        missing_spec_names = md.missing_specs.map(&:name)
        missing_specs = T.cast(md.missing_specs.map { |spec| "#{spec.name} (#{spec.version})" }, T::Array[String])
        md.to_a.reject { |spec| missing_spec_names.include?(spec.name) }
      else
        definition.resolve.materialize(deps, missing_specs)
      end
      [materialized_dependencies, missing_specs]
    end

    sig { returns(Bundler::Runtime) }
    def runtime
      Bundler::Runtime.new(File.dirname(gemfile.path), definition)
    end

    sig { returns(T::Array[Symbol]) }
    def groups
      definition.groups
    end

    sig { returns(String) }
    def dir
      File.expand_path(gemfile.path + "/..")
    end

    class GemSpec
      extend(T::Sig)

      IGNORED_GEMS = T.let(["sorbet", "sorbet-static", "sorbet-runtime"].freeze, T::Array[String])

      sig { returns(String) }
      attr_reader :full_gem_path, :version

      sig { params(spec: Spec).void }
      def initialize(spec)
        @spec = T.let(spec, Tapioca::Gemfile::Spec)
        real_gem_path = to_realpath(@spec.full_gem_path)
        @full_gem_path = T.let(real_gem_path, String)
        @version = T.let(version_string, String)
        @exported_rbi_files = T.let(nil, T.nilable(T::Array[String]))
      end

      sig { params(gemfile_dir: String).returns(T::Boolean) }
      def ignore?(gemfile_dir)
        gem_ignored? || gem_in_app_dir?(gemfile_dir)
      end

      sig { returns(T::Array[Pathname]) }
      def files
        if default_gem?
          # `Bundler::RemoteSpecification` delegates missing methods to
          # `Gem::Specification`, so `files` actually always exists on spec.
          T.unsafe(@spec).files.map do |file|
            ruby_lib_dir.join(file)
          end
        else
          @spec.full_require_paths.flat_map do |path|
            Pathname.glob((Pathname.new(path) / "**/*.rb").to_s)
          end
        end
      end

      sig { returns(String) }
      def name
        @spec.name
      end

      sig { returns(String) }
      def rbi_file_name
        "#{name}@#{version}.rbi"
      end

      sig { params(path: String).returns(T::Boolean) }
      def contains_path?(path)
        if default_gem?
          files.any? { |file| file.to_s == to_realpath(path) }
        else
          to_realpath(path).start_with?(full_gem_path) || has_parent_gemspec?(path)
        end
      end

      sig { void }
      def parse_yard_docs
        files.each { |path| YARD.parse(path.to_s, [], Logger::Severity::FATAL) }
      end

      sig { returns(T::Array[String]) }
      def exported_rbi_files
        @exported_rbi_files ||= Dir.glob("#{full_gem_path}/rbi/**/*.rbi").sort
      end

      sig { returns(T::Boolean) }
      def export_rbi_files?
        exported_rbi_files.any?
      end

      sig { returns(RBI::MergeTree) }
      def exported_rbi_tree
        rewriter = RBI::Rewriters::Merge.new(keep: RBI::Rewriters::Merge::Keep::NONE)

        exported_rbi_files.each do |file|
          rbi = RBI::Parser.parse_file(file)
          rewriter.merge(rbi)
        end

        rewriter.tree
      end

      private

      sig { returns(T::Boolean) }
      def default_gem?
        @spec.respond_to?(:default_gem?) && @spec.default_gem?
      end

      sig { returns(Pathname) }
      def ruby_lib_dir
        Pathname.new(RbConfig::CONFIG["rubylibdir"])
      end

      sig { returns(String) }
      def version_string
        version = @spec.version.to_s
        version += "-#{@spec.source.revision}" if Bundler::Source::Git === @spec.source
        version
      end

      sig { params(path: String).returns(T::Boolean) }
      def has_parent_gemspec?(path)
        # For some Git installed gems the location of the loaded file can
        # be different from the gem path as indicated by the spec file
        #
        # To compensate for these cases, we walk up the directory hierarchy
        # from the given file and try to match a <gem-name.gemspec> file in
        # one of those folders to see if the path really belongs in the given gem
        # or not.
        return false unless Bundler::Source::Git === @spec.source
        parent = Pathname.new(path)

        until parent.root?
          parent = parent.parent.expand_path
          return true if parent.join("#{name}.gemspec").file?
        end

        false
      end

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
        full_gem_path.start_with?(Bundler.bundle_path.to_s, Bundler.app_cache.to_s)
      end
    end
  end
end
