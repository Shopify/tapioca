# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Tapioca
  def self.silence_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    yield
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

require_relative "tapioca/loader"
require_relative "tapioca/constant_locator"
require_relative "tapioca/generator"
require_relative "tapioca/cli"
require_relative "tapioca/gemfile"
require_relative "tapioca/compilers/symbol_table_compiler"
require_relative "tapioca/compilers/symbol_table/symbol_generator"
require_relative "tapioca/compilers/symbol_table/symbol_loader"
require_relative "tapioca/version"
