# frozen_string_literal: true
# typed: strict

module Tapioca
  class Loader
    extend(T::Sig)

    sig { params(gemfile: Tapioca::Gemfile).void }
    def initialize(gemfile)
      @gemfile = T.let(gemfile, Tapioca::Gemfile)
    end

    sig { params(initialize_file: T.nilable(String), require_file: T.nilable(String)).void }
    def load_bundle(initialize_file, require_file)
      require(initialize_file) if initialize_file && File.exist?(initialize_file)

      require_bundle

      require(require_file) if require_file && File.exist?(require_file)

      load_rails_engines
    end

    private

    sig { returns(Tapioca::Gemfile) }
    attr_reader :gemfile

    sig { void }
    def require_bundle
      gemfile.require
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
  end
end
