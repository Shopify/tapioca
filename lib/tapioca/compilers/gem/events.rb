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
    end
  end
end
