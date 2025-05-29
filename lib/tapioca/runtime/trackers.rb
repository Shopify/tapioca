# typed: true
# frozen_string_literal: true

require "tapioca/runtime/trackers/tracker"

module Tapioca
  module Runtime
    module Trackers
      extend T::Sig

      @trackers = [] #: Array[Tracker]

      class << self
        extend T::Sig

        #: [Return] { -> Return } -> Return
        def with_trackers_enabled(&blk)
          # Currently this is a dirty hack to ensure disabling trackers
          # doesn't work while in the block passed to this method.
          disable_all_method = method(:disable_all!)
          define_singleton_method(:disable_all!) {}
          blk.call
        ensure
          if disable_all_method
            define_singleton_method(:disable_all!, disable_all_method)
          end
        end

        #: -> void
        def disable_all!
          @trackers.each(&:disable!)
        end

        #: (Tracker tracker) -> void
        def register_tracker(tracker)
          @trackers << tracker
        end
      end
    end
  end
end

# The load order below is important:
# ----------------------------------
# We want the mixin tracker to be the first thing that is
# loaded because other trackers might apply their own mixins
# into core types (like `Module` and `Kernel`). In order to
# catch and filter those mixins as coming from Tapioca, we need
# the mixin tracker to be in place, before any mixin operations
# are performed.
require "tapioca/runtime/trackers/mixin"
require "tapioca/runtime/trackers/constant_definition"
require "tapioca/runtime/trackers/autoload"
require "tapioca/runtime/trackers/required_ancestor"
require "tapioca/runtime/trackers/method_definition"
