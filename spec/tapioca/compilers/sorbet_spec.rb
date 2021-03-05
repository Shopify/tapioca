# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::SorbetSpec < Minitest::Spec
  before do
    @temp_env_value = T.let(nil, T.nilable(String))
    @temp_env_value = ENV["TAPIOCA_SORBET_EXE"]
  end

  after do
    ENV["TAPIOCA_SORBET_EXE"] = @temp_env_value
  end

  it("returns the value of TAPIOCA_SORBET_EXE if set") do
    custom_path = 'bin/custom-sorbet-static'
    ENV["TAPIOCA_SORBET_EXE"] = custom_path
    sorbet_path = Tapioca::Compilers::Sorbet.sorbet_path
    assert_equal(sorbet_path, custom_path)
  end

  it("returns the default sorbet path if TAPIOCA_SORBET_EXE is not set") do
    ENV["TAPIOCA_SORBET_EXE"] = ''
    gem_path = Gem::Specification.find_by_name("sorbet-static").full_gem_path
    default_path = Tapioca::Compilers::Sorbet::SORBET
    sorbet_path = Tapioca::Compilers::Sorbet.sorbet_path
    assert_equal(sorbet_path, default_path)
  end
end
