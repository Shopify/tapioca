# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    class CommandWithoutTracker < Command
      extend T::Helpers

      abstract!

      sig { params(default_command_override: T.nilable(String)).void }
      def initialize(default_command_override: nil)
        Tapioca::Runtime::Trackers.disable_all!
        super(default_command_override: default_command_override)
      end
    end
  end
end
