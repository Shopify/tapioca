# typed: strict
# frozen_string_literal: true

# NOTE: Temporary measure to get pairity with existing behaviour. Thor should be abstracted out so Generators
# do NOT need to know about the CLI interface.
require "thor"

module Tapioca
  module Generators
    class Base
      extend T::Sig

      include Thor::Base # TODO: Remove me when logging logic has been abstracted.

      sig { returns(Tapioca::Config) }
      attr_reader :config

      sig { params(config: Tapioca::Config).void }
      def initialize(config)
        @config = config
      end
    end
  end
end
