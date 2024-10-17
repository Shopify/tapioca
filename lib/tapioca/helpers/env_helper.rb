# typed: true
# frozen_string_literal: true

module Tapioca
  module EnvHelper
    extend T::Sig
    extend T::Helpers

    requires_ancestor { Thor }

    private

    sig { params(options: T::Hash[Symbol, T.untyped]).void }
    def set_environment(options) # rubocop:disable Naming/AccessorMethodName
      set_all_environment_variables(options[:env])
      ENV["RAILS_ENV"] = ENV["RACK_ENV"] = options[:environment] if options[:environment]
      ENV["RUBY_DEBUG_LAZY"] = "1"
    end

    sig { params(options: T.nilable(T::Hash[String, String])).void }
    def set_all_environment_variables(options) # rubocop:disable Naming/AccessorMethodName
      (options || {}).each do |key, value|
        ENV[key] = value
      end
    end
  end
end
