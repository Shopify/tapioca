# frozen_string_literal: true
# typed: true

module Tapioca
  class Gemfile
    extend(T::Sig)

    Spec = T.type_alias(T.any(::Bundler::StubSpecification, ::Gem::Specification))

    sig { params(gemfile: T.any(Pathname, String), gemfile_lock: T.any(Pathname, String)).void }
    def initialize(gemfile: Bundler.default_gemfile, gemfile_lock: Bundler.default_lockfile)
      @gemfile = File.new(gemfile.to_s)
      @gemfile_lock = File.new(gemfile_lock.to_s)
    end

    sig { returns(T::Array[Gem]) }
    def dependencies
      bundler = Bundler::Dsl.evaluate(gemfile, gemfile_lock, {})
      bundler
        .resolve
        .materialize(bundler.specs.to_a)
        .reject { |gem| gem == "sorbet" }
        .map { |gem| Gem.new(gem) }
        .reject { |gem| gem.full_gem_path.start_with?(gemfile_dir) }
        .uniq(&:rbi_file_name)
        .sort_by(&:rbi_file_name)
    end

    sig { returns(String) }
    def gemfile_dir
      File.expand_path(gemfile.path + "/..")
    end

    sig { params(gem_name: String).returns(T.nilable(Gem)) }
    def gem(gem_name)
      dependencies.detect { |dep| dep.name == gem_name }
    end

    sig { params(initialize_file: T.nilable(String), require_file: T.nilable(String)).void }
    def require_bundle(initialize_file, require_file)
      require(initialize_file) if initialize_file && File.exist?(initialize_file)

      Bundler.require(*T.unsafe(Bundler.definition.groups))

      require(require_file) if require_file && File.exist?(require_file)

      load_rails_engines
    end

    private

    sig { void }
    def load_rails_engines
      return unless Object.const_defined?("Rails::Engine")
      engines = Object.const_get("Rails::Engine").descendants.reject(&:abstract_railtie?)

      engines.each do |engine|
        errored_files = []

        engine.config.eager_load_paths.each do |load_path|
          Dir.glob("#{load_path}/**/*.rb").sort.each do |file|
            require(T.must(file))
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

    attr_reader(:gemfile, :gemfile_lock)

    class Gem
      extend(T::Sig)

      sig { params(spec: Spec).void }
      def initialize(spec)
        @spec = T.let(spec, Spec)
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
