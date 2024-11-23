# typed: true
# frozen_string_literal: true

module RubyLsp
  module Tapioca
    class LockfileDiffParser
      GEM_PATTERN = /[+-](.*[\w\-]+)\s*\(/
      ADDED_LINE_PATTERN = /^\+.*[\w\-]+ \(.*\)/
      REMOVED_LINE_PATTERN = /^-.*[\w\-]+ \(.*\)/

      attr_reader :added_or_modified_gems
      attr_reader :removed_gems

      def initialize(diff_content)
        @diff_content = diff_content
        @added_or_modified_gems = parse_added_or_modified_gems
        @removed_gems = parse_removed_gems
      end

      private

      def parse_added_or_modified_gems
        @diff_content
          .lines
          .filter { |line| line.match?(ADDED_LINE_PATTERN) }
          .map { |line| extract_gem(line) }
          .uniq
      end

      def parse_removed_gems
        @diff_content
          .lines
          .filter { |line| line.match?(REMOVED_LINE_PATTERN) }
          .map { |line| extract_gem(line) }
          .reject { |gem| @added_or_modified_gems.include?(gem) }
          .uniq
      end

      def extract_gem(line)
        line.match(GEM_PATTERN)[1].strip
      end
    end
  end
end
