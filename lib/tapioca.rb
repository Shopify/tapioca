# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Tapioca
  extend T::Sig

  sig do
    type_parameters(:Result)
      .params(blk: T.proc.returns(T.type_parameter(:Result)))
      .returns(T.type_parameter(:Result))
  end
  def self.silence_warnings(&blk)
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
      blk.call
    end
  ensure
    $VERBOSE = original_verbosity
  end

  class Error < StandardError; end

  SORBET_PATH = T.let("sorbet", String)
  SORBET_CONFIG = T.let("#{SORBET_PATH}/config", String)
  TAPIOCA_PATH = T.let("#{SORBET_PATH}/tapioca", String)
  TAPIOCA_CONFIG = T.let("#{TAPIOCA_PATH}/config.yml", String)

  DEFAULT_COMMAND = T.let("bin/tapioca", String)
  DEFAULT_POSTREQUIRE = T.let("#{TAPIOCA_PATH}/require.rb", String)
  DEFAULT_RBIDIR = T.let("#{SORBET_PATH}/rbi", String)
  DEFAULT_DSLDIR = T.let("#{DEFAULT_RBIDIR}/dsl", String)
  DEFAULT_GEMDIR = T.let("#{DEFAULT_RBIDIR}/gems", String)
  DEFAULT_SHIMDIR = T.let("#{DEFAULT_RBIDIR}/shims", String)
  DEFAULT_TODOSPATH = T.let("#{DEFAULT_RBIDIR}/todo.rbi", String)

  DEFAULT_OVERRIDES = T.let({
    # ActiveSupport overrides some core methods with different signatures
    # so we generate a typed: false RBI for it to suppress errors
    "activesupport" => "false",
  }.freeze, T::Hash[String, String])
end

require "tapioca/reflection"
require "tapioca/trackers"
require "tapioca/compilers/dsl/base"
require "tapioca/compilers/dynamic_mixin_compiler"
require "tapioca/helpers/active_record_column_type_helper"
require "tapioca/version"
