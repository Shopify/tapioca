# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBI
    class Loc
      extend T::Sig

      sig { returns(T.nilable(String)) }
      attr_reader :file

      sig { returns(T.nilable(Integer)) }
      attr_reader :begin_line, :end_line, :begin_column, :end_column

      sig do
        params(
          file: T.nilable(String),
          begin_line: T.nilable(Integer),
          end_line: T.nilable(Integer),
          begin_column: T.nilable(Integer),
          end_column: T.nilable(Integer)
        ).void
      end
      def initialize(file: nil, begin_line: nil, end_line: nil, begin_column: nil, end_column: nil)
        @file = file
        @begin_line = begin_line
        @end_line = end_line
        @begin_column = begin_column
        @end_column = end_column
      end

      sig { returns(String) }
      def to_s
        "#{file}:#{begin_line}:#{begin_column}-#{end_line}:#{end_column}"
      end
    end
  end
end
