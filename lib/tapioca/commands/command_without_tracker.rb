# typed: strict
# frozen_string_literal: true

module Tapioca
  module Commands
    # @abstract
    class CommandWithoutTracker < Command
      #: -> void
      def initialize
        Tapioca::Runtime::Trackers.disable_all!
        super
      end
    end
  end
end
