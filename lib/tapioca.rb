# typed: true
# frozen_string_literal: true

require "zeitwerk"
require "sorbet-runtime"

loader = Zeitwerk::Loader.for_gem
loader.eager_load
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
