# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    class SourceLocation
      # this looks something like:
      # "(eval at /path/to/file.rb:123)"
      # and we are interested in the "/path/to/file.rb" and "123" parts
      EVAL_SOURCE_FILE_PATTERN = /^\(eval at (?<file>.+):(?<line>\d+)\)/ #: Regexp

      #: String
      attr_reader :file

      #: Integer
      attr_reader :line

      def initialize(file:, line:)
        # Ruby 3.3 adds automatic definition of source location for evals if
        # `file` and `line` arguments are not provided. This results in the source
        # file being something like `(eval at /path/to/file.rb:123)`. We try to parse
        # this string to get the actual source file.
        eval_pattern_match = EVAL_SOURCE_FILE_PATTERN.match(file)
        if eval_pattern_match
          file = eval_pattern_match[:file]
          line = eval_pattern_match[:line].to_i
        end

        @file = file
        @line = line
      end

      # force all callers to use the from_loc method
      private_class_method :new

      class << self
        #: ([String?, Integer?]? loc) -> SourceLocation?
        def from_loc(loc)
          new(file: loc.first, line: loc.last) if loc&.first && loc.last
        end
      end
    end
  end
end
