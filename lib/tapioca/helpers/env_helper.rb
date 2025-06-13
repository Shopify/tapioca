# typed: true
# frozen_string_literal: true

module Tapioca
  # @requires_ancestor: Thor
  module EnvHelper
    extend T::Sig
    #: (Hash[Symbol, untyped] options) -> void
    def set_environment(options) # rubocop:disable Naming/AccessorMethodName
      ENV["RAILS_ENV"] = ENV["RACK_ENV"] = options[:environment]
      ENV["RUBY_DEBUG_LAZY"] = "1"
    end
  end
end
