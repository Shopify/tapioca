# typed: true
# frozen_string_literal: true

require "bundler"

module RubyLsp
  module Tapioca
    class LockfileDiffParser
      GEM_NAME_PATTERN = /[\w\-]+/
      DIFF_LINE_PATTERN = /[+-](.*#{GEM_NAME_PATTERN})\s*\(/
      ADDED_LINE_PATTERN = /^\+.*#{GEM_NAME_PATTERN} \(.*\)/

      attr_reader :added_or_modified_gems

      def initialize(diff_content, direct_dependencies: nil)
        @diff_content = diff_content.lines
        @current_dependencies = direct_dependencies ||
          Bundler::LockfileParser.new(Bundler.default_lockfile.read).dependencies.keys
        @added_or_modified_gems = parse_added_or_modified_gems
      end

      private

      def parse_added_or_modified_gems
        @diff_content
          .filter_map { |line| extract_gem(line) if line.match?(ADDED_LINE_PATTERN) }
          .uniq
      end

      def extract_gem(line)
        line.match(DIFF_LINE_PATTERN)[1].strip
      end
    end
  end
end
