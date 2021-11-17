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
        out, err, status = @project.tapioca("--version")
        assert_equal("Tapioca v#{Tapioca::VERSION}", out.strip)
        assert_empty(err)
        assert(status)
      end

      it "must display the version when passing -v" do
        out, err, status = @project.tapioca("-v")
        assert_equal("Tapioca v#{Tapioca::VERSION}", out.strip)
        assert_empty(err)
        assert(status)
      end
    end
  end
end
