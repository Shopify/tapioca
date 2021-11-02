# typed: strict
# frozen_string_literal: true

module Tapioca
  module Compilers
    module Gem
      class YardCompiler < Base
        extend(T::Sig)

        module YARDHandlerOverride

          def register_docstring(object, docstring = statement.comments, stmt = statement)
            return unless YARDHandlerOverride.include_docs
            super
          end

          class << self
            attr_accessor :include_docs
          end

          YARD::Handlers::Base.prepend(self)
        end

        sig { override.returns(T::Set[String]) }
        def symbols
          YARD::Registry.clear
          YARDHandlerOverride.include_docs = include_docs
          YARD.parse(gem.full_require_paths + engine_paths.map(&:to_s))
          YARD::Registry.all(:class, :module, :constant).map(&:path)
        end
      end
    end
  end
end
