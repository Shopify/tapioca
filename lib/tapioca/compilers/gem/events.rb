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
    end
  end
end
