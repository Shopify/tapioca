# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::SorbetHelperSpec < Minitest::Spec
  include Tapioca::SorbetHelper

  describe Tapioca::SorbetHelper do
    it "returns the value of TAPIOCA_SORBET_EXE if set" do
      with_custom_sorbet_exe_path("bin/custom-sorbet-static") do |custom_path|
        assert_equal(sorbet_path, custom_path)
      end
    end

    it "returns the default sorbet path if TAPIOCA_SORBET_EXE is empty" do
      default_path = SORBET_BIN.to_s.shellescape
      with_custom_sorbet_exe_path("") do
        assert_equal(sorbet_path, default_path)
      end
    end

    it "returns the default sorbet path if TAPIOCA_SORBET_EXE is not set" do
      default_path = SORBET_BIN.to_s.shellescape
      with_custom_sorbet_exe_path(nil) do
        assert_equal(sorbet_path, default_path)
      end
    end

    it "raises for an unknown feature check" do
      assert_raises do
        sorbet_supports?(:unknown_feature_name)
      end
    end

    it "uses the default args if no environment variable is set" do
      with_custom_sorbet_args(nil) do
        assert_equal(sorbet_default_args, [])
      end
    end

    it "uses the environment variable args if set" do
      with_custom_sorbet_args("--parser=prism ") do
        assert_equal(sorbet_default_args, ["--parser=prism"])
      end
    end
  end

  private

  #: (String? path) { (String? custom_path) -> void } -> void
  def with_custom_sorbet_exe_path(path, &block)
    sorbet_exe_env_value = ENV[SORBET_EXE_PATH_ENV_VAR]
    begin
      ENV[SORBET_EXE_PATH_ENV_VAR] = path
      block.call(path)
    ensure
      ENV[SORBET_EXE_PATH_ENV_VAR] = sorbet_exe_env_value
    end
  end

  #: (String? args) { (String? custom_args) -> void } -> void
  def with_custom_sorbet_args(args, &block)
    sorbet_args_env_value = ENV[SORBET_ARGS_ENV_VAR]
    begin
      ENV[SORBET_ARGS_ENV_VAR] = args
      block.call(args)
    ensure
      ENV[SORBET_ARGS_ENV_VAR] = sorbet_args_env_value
    end
  end
end
