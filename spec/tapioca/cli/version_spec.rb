# typed: strict
# frozen_string_literal: true

require "spec_with_project"

module Tapioca
  class VersionSpec < SpecWithProject
    describe("#cli::version") do
      before(:all) do
        project.bundle_install
      end

      it "must display the version when passing --version" do
        result = @project.tapioca("--version")
        assert_equal("Tapioca v#{Tapioca::VERSION}", result.out.strip)
        assert_empty_stderr(result)
        assert_success_status(result)
      end

      it "must display the version when passing -v" do
        result = @project.tapioca("-v")
        assert_equal("Tapioca v#{Tapioca::VERSION}", result.out.strip)
        assert_empty_stderr(result)
        assert_success_status(result)
      end
    end
  end
end
