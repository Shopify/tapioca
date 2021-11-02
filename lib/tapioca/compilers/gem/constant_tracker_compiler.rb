# typed: strict
# frozen_string_literal: true

module Tapioca
  module Compilers
    module Gem
      class ConstantTrackerCompiler < Base
        extend(T::Sig)

        sig { override.returns(T::Set[String]) }
        def symbols
          Tapioca::ConstantTracker.constants_for_files(files)
        end
      end
    end
  end
end
