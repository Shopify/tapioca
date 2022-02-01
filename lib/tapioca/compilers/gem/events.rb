# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Compilers
    module Gem
      class Event
        extend T::Sig
        extend T::Helpers

        abstract!
      end

      class NewSymbolFound < Event
        extend T::Sig

        sig { returns(String) }
        attr_reader :symbol

        sig { params(symbol: String).void }
        def initialize(symbol)
          super()
          @symbol = symbol
        end
      end

      class NewConstantFound < Event
        extend T::Sig

        sig { returns(String) }
        attr_reader :symbol

        sig { returns(BasicObject).checked(:never) }
        attr_reader :constant

        sig { params(symbol: String, constant: BasicObject).void.checked(:never) }
        def initialize(symbol, constant)
          super()
          @symbol = symbol
          @constant = constant
        end
      end

      class NewNodeAdded < Event
        extend T::Helpers
        extend T::Sig

        abstract!

        sig { returns(String) }
        attr_reader :symbol

        sig { returns(Module).checked(:never) }
        attr_reader :constant

        sig { params(symbol: String, constant: Module).void.checked(:never) }
        def initialize(symbol, constant)
          super()
          @symbol = symbol
          @constant = constant
        end
      end

      class NewConstNode < NewNodeAdded
        extend T::Sig

        sig { returns(RBI::Const) }
        attr_reader :node

        sig { params(symbol: String, constant: Module, node: RBI::Const).void.checked(:never) }
        def initialize(symbol, constant, node)
          super(symbol, constant)
          @node = node
        end
      end

      class NewScopeNode < NewNodeAdded
        extend T::Sig

        sig { returns(RBI::Scope) }
        attr_reader :node

        sig { params(symbol: String, constant: Module, node: RBI::Scope).void.checked(:never) }
        def initialize(symbol, constant, node)
          super(symbol, constant)
          @node = node
        end
      end

      class NewMethodNode < NewNodeAdded
        extend T::Sig

        sig { returns(RBI::Method) }
        attr_reader :node

        sig { params(symbol: String, constant: Module, node: RBI::Method).void.checked(:never) }
        def initialize(symbol, constant, node)
          super(symbol, constant)
          @node = node
        end
      end
    end
  end
end
