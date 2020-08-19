# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Tapioca
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
end

begin
  T::Configuration.default_checked_level = :never
  # Suppresses errors caused by T.cast, T.let, T.must, etc.
  T::Configuration.inline_type_error_handler = ->(*) {}
  # Suppresses errors caused by incorrect parameter ordering
  T::Configuration.sig_validation_error_handler = ->(*) {}
rescue
  # Need this rescue so that if another gem has
  # already set the checked level by the time we
  # get to it, we don't fail outright.
  nil
end

require "tapioca/loader"
require "tapioca/constant_locator"
require "tapioca/config"
require "tapioca/config_builder"
require "tapioca/generator"
require "tapioca/cli"
require "tapioca/gemfile"
require "tapioca/compilers/sorbet"
require "tapioca/compilers/requires_compiler"
require "tapioca/compilers/symbol_table_compiler"
require "tapioca/compilers/symbol_table/symbol_generator"
require "tapioca/compilers/symbol_table/symbol_loader"
require "tapioca/compilers/todos_compiler"
require "tapioca/compilers/dsl_compiler"
require "tapioca/version"
