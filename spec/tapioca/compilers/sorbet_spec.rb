# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::SorbetSpec < Minitest::Spec
  before do
    @temp_env_value = T.let(nil, T.nilable(String))
    @temp_env_value = ENV["TPC_SORBET_EXE"]
  end

  after do
    ENV["TPC_SORBET_EXE"] = @temp_env_value
  end

  it("returns the value of TPC_SORBET_EXE if set") do
    custom_path = 'bin/custom-sorbet-static'
    ENV["TPC_SORBET_EXE"] = custom_path
    sorbet_path = Tapioca::Compilers::Sorbet.sorbet_path
    assert_equal(sorbet_path, custom_path)
  end

  it("returns the default sorbet path if TPC_SORBET_EXE is not set") do
    ENV["TPC_SORBET_EXE"] = ''
    gem_path = Gem::Specification.find_by_name("sorbet-static").full_gem_path
    default_path = File.join(gem_path, "libexec", "sorbet")
    sorbet_path = Tapioca::Compilers::Sorbet.sorbet_path
    assert_equal(sorbet_path, default_path)
  end
end
