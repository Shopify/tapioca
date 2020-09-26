# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::RequiresCompilerSpec < Minitest::HooksSpec
  it("it does nothing on an empty project") do
    compiler = Tapioca::Compilers::RequiresCompiler.new('spec/support/require/empty/sorbet/config')
    assert_equal('', compiler.compile)
  end

  it("it extracts the requires from a simple project") do
    compiler = Tapioca::Compilers::RequiresCompiler.new('spec/support/require/simple/sorbet/config')
    assert_equal(<<~REQ, compiler.compile)
      require 'a'
      require 'b'
      require 'c'
      require 'd'
      require 'e'
      require 'f'
      require 'g'
      require 'h'
      require 'i'
      require 'j'
    REQ
  end

  it("it extracts the requires from all the files listed in the sorbet config") do
    compiler = Tapioca::Compilers::RequiresCompiler.new('spec/support/require/multi/sorbet/config')
    assert_equal(<<~REQ, compiler.compile)
      require 'a'
      require 'b'
      require 'c'
      require 'd'
    REQ
  end

  it("it ignores files ignored in the sorbet config") do
    compiler = Tapioca::Compilers::RequiresCompiler.new('spec/support/require/sorbet_ignore/sorbet/config')
    assert_equal(<<~REQ, compiler.compile)
      require 'c'
      require 'd'
    REQ
  end

  it("it ignores files located in the project") do
    compiler = Tapioca::Compilers::RequiresCompiler.new('spec/support/require/project_ignore/sorbet/config')
    assert_equal(<<~REQ, compiler.compile)
      require 'liba'
      require 'libb'
      require 'libc'
      require 'libd'
    REQ
  end
end
