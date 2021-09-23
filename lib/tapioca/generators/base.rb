# typed: strict
# frozen_string_literal: true

module Tapioca
  module Generators
    class Base
      extend T::Sig
      extend T::Helpers

      include Thor::Base # TODO: Remove me when logging logic has been abstracted

      abstract!

      sig { params(default_command: String).void }
      def initialize(default_command:)
        @default_command = default_command
      end

      sig { abstract.void }
      def generate; end
    end
  end
end
