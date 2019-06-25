# typed: true
# frozen_string_literal: true

require "zeitwerk"
require_relative "./t"

loader = Zeitwerk::Loader.for_gem
loader.setup
loader.eager_load

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
