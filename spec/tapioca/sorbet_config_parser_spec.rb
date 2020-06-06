# typed: false
# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/tapioca/sorbet_config_parser"

describe(Tapioca::SorbetConfig) do
  it("parses empty config strings") do
    config = Tapioca::SorbetConfig.parse_string('')
    assert_empty(config.paths)
    assert_empty(config.ignore)
  end

  it("parses a simple config string") do
    config = Tapioca::SorbetConfig.parse_string('.')
    assert_equal(config.paths, ['.'])
    assert_empty(config.ignore)
  end

  it("parses a config string with paths") do
    config = Tapioca::SorbetConfig.parse_string(<<~CONFIG)
      lib/a
      lib/b
    CONFIG
    assert_equal(config.paths, ['lib/a', 'lib/b'])
    assert_empty(config.ignore)
  end

  it("parses a config string with --file options") do
    config = Tapioca::SorbetConfig.parse_string(<<~CONFIG)
      a
      --file=b
      c
      --file
      d
      e
    CONFIG
    assert_equal(config.paths, ['a', 'b', 'c', 'd', 'e'])
    assert_empty(config.ignore)
  end

  it("parses a config string with --dir options") do
    config = Tapioca::SorbetConfig.parse_string(<<~CONFIG)
      a
      --dir=b
      c
      --dir
      d
      e
    CONFIG
    assert_equal(config.paths, ['a', 'b', 'c', 'd', 'e'])
    assert_empty(config.ignore)
  end

  it("parses a config string with --ignore options") do
    config = Tapioca::SorbetConfig.parse_string(<<~CONFIG)
      a
      --ignore=b
      c
      --ignore
      d
      e
    CONFIG
    assert_equal(config.paths, ['a', 'c', 'e'])
    assert_equal(config.ignore, ['b', 'd'])
  end

  it("parses a config string with other options") do
    config = Tapioca::SorbetConfig.parse_string(<<~CONFIG)
      a
      --other=b
      c
      --d
      d
      e
      -f
    CONFIG
    assert_equal(config.paths, ['a', 'c', 'e'])
    assert_empty(config.ignore)
  end

  it("parses a config string with mixed options") do
    config = Tapioca::SorbetConfig.parse_string(<<~CONFIG)
      a
      --other=b
      --file
      c
      --d
      e
      --dir=f
      -g
      --dir
      h
      --file=i
      --ignore
      j
      --ignore=k
      l
      m
      -n
      --o
      p
    CONFIG
    assert_equal(config.paths, ['a', 'c', 'f', 'h', 'i', 'l', 'm'])
    assert_equal(config.ignore, ['j', 'k'])
  end

  it("parses a real config string") do
    config = Tapioca::SorbetConfig.parse_string(<<~CONFIG)
      .
      --error-black-list=4002
      --ignore=.git/
      --ignore=.idea/
      --ignore=vendor/
      --allowed-extension=.rb
      --allowed-extension=.rbi
      --allowed-extension=.rake
      --allowed-extension=.ru
    CONFIG
    assert_equal(config.paths, ['.'])
    assert_equal(config.ignore, ['.git/', '.idea/', 'vendor/'])
  end
end
