# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class HelpSpec < SpecWithProject
    describe("cli::help") do
      before(:all) do
        project.bundle_install!
      end

      it "must display the help when passing --help" do
        result = @project.tapioca("--help")
        stdout_lines = result.out.strip.split("\n")
        assert_equal("Commands:", stdout_lines.first)
        assert_empty_stderr(result)
        assert_success_status(result)
      end

      it "must display the help when passing -h" do
        result = @project.tapioca("-h")
        stdout_lines = result.out.strip.split("\n")
        assert_equal("Commands:", stdout_lines.first)
        assert_empty_stderr(result)
        assert_success_status(result)
      end

      it "must begin every command description of help text with a capital letter" do
        result = @project.tapioca("--help")
        stdout_lines = result.out.strip.split("\n")
        assert_equal(stdout_lines.reject { / # [a-z]/.match?(_1) }.size, stdout_lines.size)
        assert_empty_stderr(result)
        assert_success_status(result)
      end
    end
  end
end
