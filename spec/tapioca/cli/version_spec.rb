# typed: true
# frozen_string_literal: true

require_relative "../cli_spec"

module Tapioca
  class VersionSpec < CliSpec
    describe("#version") do
      it "must display the version when passing --version" do
        output = execute("--version")
        assert_equal("Tapioca v#{Tapioca::VERSION}", output&.strip)
      end

      it "must display the version when passing -v" do
        output = execute("-v")
        assert_equal("Tapioca v#{Tapioca::VERSION}", output&.strip)
      end
    end
  end
end
