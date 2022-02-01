# typed: strict
# frozen_string_literal: true

module Tapioca
  module Compilers
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

          sig { params(event: NewNodeAdded).void }
          def dispatch(event)
            case event
            when NewConstNode
              on_const(event)
            when NewScopeNode
              on_scope(event)
            when NewMethodNode
              on_method(event)
            else
              raise "Unsupported event #{event.class}"
            end
          end

          private

          sig { params(event: NewConstNode).void }
          def on_const(event)
          end

          sig { params(event: NewScopeNode).void }
          def on_scope(event)
          end

          sig { params(event: NewMethodNode).void }
          def on_method(event)
          end
        end
      end
    end
  end
end
