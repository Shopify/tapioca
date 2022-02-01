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

        sig { params(compiler: SymbolTableCompiler).void }
        def initialize(compiler)
          @compiler = compiler
        end

        sig { params(event: Tapioca::Compilers::SymbolTableCompiler::NodeEvent).void }
        def dispatch(event)
          case event
          when Tapioca::Compilers::SymbolTableCompiler::ConstEvent
            on_const(event)
          when Tapioca::Compilers::SymbolTableCompiler::ScopeEvent
            on_scope(event)
          when Tapioca::Compilers::SymbolTableCompiler::MethodEvent
            on_method(event)
          end
        end

        private

        sig { params(event: Tapioca::Compilers::SymbolTableCompiler::ConstEvent).void }
        def on_const(event); end

        sig { params(event: Tapioca::Compilers::SymbolTableCompiler::ScopeEvent).void }
        def on_scope(event); end

        sig { params(event: Tapioca::Compilers::SymbolTableCompiler::MethodEvent).void }
        def on_method(event); end
      end
    end
  end
end
