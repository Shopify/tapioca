# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      # @abstract
      module Tracker
        extend T::Sig
        class << self
          extend T::Sig

          #: ((Tracker & Module) base) -> void
          def extended(base)
            Trackers.register_tracker(base)
            base.instance_exec do
              @enabled = true
            end
          end
        end

        #: -> void
        def disable!
          @enabled = false
        end

        def enabled?
          @enabled
        end

        def with_disabled_tracker(&block)
          original_state = @enabled
          @enabled = false

          block.call
        ensure
          @enabled = original_state
        end
      end
    end
  end
end
