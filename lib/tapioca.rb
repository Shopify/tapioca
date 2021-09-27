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

require "tapioca/reflection"
require "tapioca/constant_locator"
require "tapioca/compilers/dsl/base"
require "tapioca/compilers/dynamic_mixin_compiler"
require "tapioca/helpers/active_record_column_type_helper"
require "tapioca/version"
