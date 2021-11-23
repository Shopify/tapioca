# typed: strict
# frozen_string_literal: true

require "thor"

module Tapioca
  module CliHelper
    extend T::Sig
    extend T::Helpers

    include Thor::Shell

    sig { params(message: String, color: T.any(Symbol, T::Array[Symbol])).void }
    def say_error(message = "", *color)
      force_new_line = (message.to_s !~ /( |\t)\Z/)
      # NOTE: This is a hack. We're no longer subclassing from Thor::Shell::Color
      # so we no longer have access to the prepare_message call.
      # We should update this to remove this.
      buffer = shell.send(:prepare_message, *T.unsafe([message, *T.unsafe(color)]))
      buffer << "\n" if force_new_line && !message.to_s.end_with?("\n")

      $stderr.print(buffer)
      $stderr.flush
    end
  end
end
