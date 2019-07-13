# typed: true
# frozen_string_literal: true
require "sorbet-runtime"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.setup

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

T::Configuration.default_checked_level = :never
# Suppresses errors caused by T.cast, T.let, T.must, etc.
T::Configuration.inline_type_error_handler = ->(*) {}
# Suppresses errors caused by incorrect parameter ordering
T::Configuration.sig_validation_error_handler = ->(*) {}

loader.eager_load
