# typed: strict
# frozen_string_literal: true

require "thor"

module Tapioca
  module CliHelper
    extend T::Sig
    extend T::Helpers

    requires_ancestor { Thor::Shell }

    sig { params(message: String, color: T.any(Symbol, T::Array[Symbol])).void }
    def say_error(message = "", *color)
      # Thor has its own `say_error` now, but it has two problems:
      # 1. it adds the padding around all the messages, even if they continue on
      #    the same line, and
      # 2. it accepts a last parameter which breaks the ability to pass color values
      #    as splats.
      #
      # So we implement our own version here to work around those problems.
      shell.indent(-shell.padding) do
        super(message, color)
      end
    end
  end
end
