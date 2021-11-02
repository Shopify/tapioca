# typed: strict
# frozen_string_literal: true

require "spec_with_project"

module Tapioca
  class DeprecationsSpec < SpecWithProject
    describe("#cli::dsl::deprecations") do
      before(:all) do
        project.bundle_install
      end

      it "prints the correct deprecation message with -c" do
        out, _, _ = @project.tapioca("dsl -c foo")
        assert_includes(out, "DEPRECATION: The `-c` and `--cmd` flags will be removed in a future release.")
      end

      it "prints the correct deprecation message with --cmd" do
        out, _, _ = @project.tapioca("dsl --cmd foo")
        assert_includes(out, "DEPRECATION: The `-c` and `--cmd` flags will be removed in a future release.")
      end

      it "doesn't print the correct deprecation message with no flag" do
        out, _, _ = @project.tapioca("dsl")
        refute_includes(out, "DEPRECATION: The `-c` and `--cmd` flags will be removed in a future release.")
      end
    end
  end
end
