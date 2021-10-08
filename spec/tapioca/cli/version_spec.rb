# typed: true
# frozen_string_literal: true

require "cli_spec"

module Tapioca
  class VersionSpec < CliSpec
    describe("#version") do
      it "must display the version when passing --version" do
        output = tapioca("--version")
        assert_equal("Tapioca v#{Tapioca::VERSION}", output.strip)
      end

      it "must display the version when passing -v" do
        output = tapioca("-v")
        assert_equal("Tapioca v#{Tapioca::VERSION}", output.strip)
      end
    end
  end
end
