# typed: strict
# frozen_string_literal: true

module Tapioca
  module Compilers
    module Gem
      class Base
        extend T::Sig
        extend T::Helpers
        include Reflection

        abstract!

        sig { returns(Gemfile::GemSpec) }
        attr_reader :gem

        sig { returns(T::Boolean) }
        attr_reader :include_docs

        sig { params(gem: Gemfile::GemSpec, include_docs: T::Boolean).void }
        def initialize(gem, include_docs: false)
          @gem = gem
          @include_docs = include_docs
          @engine_paths = T.let(engine_paths, T::Array[Pathname])
        end

        sig { params(rbi: RBI::File).void }
        def compile(rbi)
          SymbolGenerator
            .new(gem, symbols, ignored_symbols, include_doc: include_docs)
            .generate(rbi)
        end

        private

        sig { abstract.returns(T::Set[String]) }
        def symbols
        end

        sig { returns(T::Set[String]) }
        def ignored_symbols
          Set.new
        end

        sig {returns(T::Array[Pathname])}
        def files
          gem.files + engine_paths
        end

        sig { returns(T::Array[Pathname]) }
        def engine_paths
          return [] unless Object.const_defined?("Rails::Engine")

          engine = descendants_of(Object.const_get("Rails::Engine"))
            .reject(&:abstract_railtie?)
            .find do |klass|
              name_of(klass)
            end

          return [] unless engine

          engine.config.eager_load_paths.flat_map do |load_path|
            Pathname.glob("#{load_path}/**/*.rb")
          end
        rescue
          []
        end
      end
    end
  end
end
