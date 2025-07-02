# typed: strict
# frozen_string_literal: true

module Tapioca
  # @requires_ancestor: Thor::Shell
  module CliHelper
    extend T::Sig
    #: (?String message, *(Symbol | Array[Symbol]) color) -> void
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

    #: (Hash[Symbol, untyped] options) -> RBIFormatter
    def rbi_formatter(options)
      rbi_formatter = DEFAULT_RBI_FORMATTER
      rbi_formatter.max_line_length = options[:rbi_max_line_length]
      rbi_formatter
    end

    #: (Hash[Symbol, untyped] options) -> String?
    def netrc_file(options)
      return if options[:auth]
      return unless options[:netrc]

      options[:netrc_file] || ENV["TAPIOCA_NETRC_FILE"] || File.join(ENV["HOME"].to_s, ".netrc")
    end
  end
end
