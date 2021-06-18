# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::SorbetSpec < Minitest::Spec
  it("returns the value of TAPIOCA_SORBET_EXE if set") do
    with_custom_sorbet_exe_path("bin/custom-sorbet-static") do |custom_path|
      assert_equal(Tapioca::Compilers::Sorbet.sorbet_path, custom_path)
    end
  end

  it("returns the default sorbet path if TAPIOCA_SORBET_EXE is empty") do
    default_path = Tapioca::Compilers::Sorbet::SORBET.to_s.shellescape
    with_custom_sorbet_exe_path("") do
      assert_equal(Tapioca::Compilers::Sorbet.sorbet_path, default_path)
    end
  end

  it("returns the default sorbet path if TAPIOCA_SORBET_EXE is not set") do
    default_path = Tapioca::Compilers::Sorbet::SORBET.to_s.shellescape
    with_custom_sorbet_exe_path(nil) do
      assert_equal(Tapioca::Compilers::Sorbet.sorbet_path, default_path)
    end
  end

  it("returns false for feature check for old versions of Sorbet") do
    version = Gem::Version.new("0.5.5000")

    refute(Tapioca::Compilers::Sorbet.supports?(:mixes_in_class_methods_multiple_args, version: version))
  end

  it("returns true for feature check for new versions of Sorbet") do
    version = Gem::Version.new("0.5.7000")

    assert(Tapioca::Compilers::Sorbet.supports?(:mixes_in_class_methods_multiple_args, version: version))
  end

  it("raises for an unknown feature check") do
    assert_raises do
      Tapioca::Compilers::Sorbet.supports?(:unknown_feature_name)
    end
  end

  private

  sig { params(path: T.nilable(String), block: T.proc.params(custom_path: T.nilable(String)).void).void }
  def with_custom_sorbet_exe_path(path, &block)
    sorbet_exe_env_value = ENV[Tapioca::Compilers::Sorbet::EXE_PATH_ENV_VAR]
    begin
      ENV[Tapioca::Compilers::Sorbet::EXE_PATH_ENV_VAR] = path
      block.call(path)
    ensure
      ENV[Tapioca::Compilers::Sorbet::EXE_PATH_ENV_VAR] = sorbet_exe_env_value
    end
  end
end
