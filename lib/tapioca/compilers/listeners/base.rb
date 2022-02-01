# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    module NodeListeners
      class Base
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { params(event: Tapioca::Compilers::SymbolTableCompiler::NodeEvent).void }
        def dispatch(event)
          on_node(event)
        end

        private

        sig { abstract.params(event: Tapioca::Compilers::SymbolTableCompiler::NodeEvent).void }
        def on_node(event); end
      end
    end
  end
end
