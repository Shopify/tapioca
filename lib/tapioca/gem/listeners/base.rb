# typed: strict
# frozen_string_literal: true

module Tapioca
  module Gem
    module Listeners
      class Base
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { params(compiler: SymbolTableCompiler).void }
        def initialize(compiler)
          @compiler = compiler
        end

        sig { params(event: NodeAdded).void }
        def dispatch(event)
          case event
          when ConstNodeAdded
            on_const(event)
          when ScopeNodeAdded
            on_scope(event)
          when MethodNodeAdded
            on_method(event)
          else
            raise "Unsupported event #{event.class}"
          end
        end

        private

        sig { params(event: ConstNodeAdded).void }
        def on_const(event)
        end

        sig { params(event: ScopeNodeAdded).void }
        def on_scope(event)
        end

        sig { params(event: MethodNodeAdded).void }
        def on_method(event)
        end
      end
    end
  end
end
