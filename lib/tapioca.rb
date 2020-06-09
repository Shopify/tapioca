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
require "tapioca/compilers/dsl/base"
require "tapioca/compilers/dsl/smart_properties"
require "tapioca/compilers/dsl/frozen_record"
require "tapioca/compilers/dsl/action_mailer"
require "tapioca/compilers/dsl/state_machines"
require "tapioca/compilers/dsl/action_controller_helpers"
require "tapioca/compilers/dsl/active_support_current_attributes"
require "tapioca/compilers/dsl/active_record_typed_store"
require "tapioca/version"
