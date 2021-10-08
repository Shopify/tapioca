# typed: true
# frozen_string_literal: true

require "cli_spec"

module Tapioca
  class DeprecationsSpec < CliSpec
    describe("deprecations") do
      it "prints the correct deprecation message with -c" do
        output = tapioca("dsl -c foo")
        assert_includes(output, "DEPRECATION: The `-c` and `--cmd` flags will be removed in a future release.")
      end

      it "prints the correct deprecation message with --cmd" do
        output = tapioca("dsl --cmd foo")
        assert_includes(output, "DEPRECATION: The `-c` and `--cmd` flags will be removed in a future release.")
      end

      it "doesn't print the correct deprecation message with no flag" do
        output = tapioca("dsl")
        refute_includes(output, "DEPRECATION: The `-c` and `--cmd` flags will be removed in a future release.")
      end
    end
  end
end
