# typed: false
# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/tapioca/sorbet_config_parser"

RSpec.describe(Tapioca::SorbetConfig) do
  it("parses empty config strings") do
    config = Tapioca::SorbetConfig.parse_string('')
    expect(config.paths.empty?)
    expect(config.ignore.empty?)
  end

  it("parses a simple config string") do
    config = Tapioca::SorbetConfig.parse_string('.')
    expect(config.paths).to(eq(['.']))
    expect(config.ignore.empty?)
  end

  it("parses a config string with paths") do
    config = Tapioca::SorbetConfig.parse_string(<<~CONFIG)
      lib/a
      lib/b
    CONFIG
    expect(config.paths).to(eq(['lib/a', 'lib/b']))
    expect(config.ignore.empty?)
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
    expect(config.paths).to(eq(['a', 'b', 'c', 'd', 'e']))
    expect(config.ignore.empty?)
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
    expect(config.paths).to(eq(['a', 'b', 'c', 'd', 'e']))
    expect(config.ignore.empty?)
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
    expect(config.paths).to(eq(['a', 'c', 'e']))
    expect(config.ignore).to(eq(['b', 'd']))
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
    expect(config.paths).to(eq(['a', 'c', 'e']))
    expect(config.ignore.empty?)
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
    expect(config.paths).to(eq(['a', 'c', 'f', 'h', 'i', 'l', 'm']))
    expect(config.ignore).to(eq(['j', 'k']))
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
    expect(config.paths).to(eq(['.']))
    expect(config.ignore).to(eq(['.git/', '.idea/', 'vendor/']))
  end
end
