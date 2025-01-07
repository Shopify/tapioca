# typed: strict
# frozen_string_literal: true

require "spec_helper"
require "ruby_lsp/tapioca/lockfile_diff_parser"

module RubyLsp
  module Tapioca
    class LockFileDiffParserSpec < Minitest::Spec
      describe "#parse_added_or_modified_gems" do
        it "parses added or modified gems from git diff" do
          diff_output = <<~DIFF
            +    new_gem (1.0.0)
            +    updated_gem (2.0.0)
            -    removed_gem (1.0.0)
          DIFF

          lockfile_parser = RubyLsp::Tapioca::LockfileDiffParser.new(diff_output)
          assert_equal ["new_gem", "updated_gem"], lockfile_parser.added_or_modified_gems
        end

        it "is empty when there is no diff" do
          diff_output = ""

          lockfile_parser = RubyLsp::Tapioca::LockfileDiffParser.new(diff_output)
          assert_empty lockfile_parser.added_or_modified_gems
        end
      end

      describe "#parse_removed_gems" do
        it "parses removed gems from git diff" do
          diff_output = <<~DIFF
            +    new_gem (1.0.0)
            -    removed_gem (1.0.0)
            -    outdated_gem (2.3.4)
          DIFF

          lockfile_parser = RubyLsp::Tapioca::LockfileDiffParser.new(diff_output)
          assert_equal ["removed_gem", "outdated_gem"], lockfile_parser.removed_gems
        end

        it "ignores direct dependencies" do
          diff_output = <<~DIFF
            foo (1.1.1)
            bar (1.2.3)
            -    foo (> 0)
          DIFF

          lockfile_parser = RubyLsp::Tapioca::LockfileDiffParser.new(
            diff_output,
            direct_dependencies: ["foo"],
          )
          assert_empty lockfile_parser.removed_gems
        end
      end

      it "handles gem names with hyphens and underscores" do
        diff_output = <<~DIFF
          -    my-gem_extra2 (1.0.0.beta1)
        DIFF

        lockfile_parser = RubyLsp::Tapioca::LockfileDiffParser.new(diff_output)
        assert_equal ["my-gem_extra2"], lockfile_parser.removed_gems
      end

      it "handles gem names with multiple hyphens" do
        diff_output = <<~DIFF
          -    sorbet-static-and-runtime (0.5.0)
        DIFF

        lockfile_parser = RubyLsp::Tapioca::LockfileDiffParser.new(diff_output)
        assert_equal ["sorbet-static-and-runtime"], lockfile_parser.removed_gems
      end
    end
  end
end
