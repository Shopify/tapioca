# typed: true
# frozen_string_literal: true

module Tapioca
  module EnvHelper
    extend T::Sig
    extend T::Helpers

    requires_ancestor { Thor }

    sig { void }
    def set_environment
      ENV["RAILS_ENV"] = ENV["RACK_ENV"] = options[:environment]
    end
  end
end
