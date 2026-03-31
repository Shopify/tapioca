# typed: strict
# frozen_string_literal: true

module Tapioca
  module Helpers
    module Test
      # Include this module in test classes that are safe to run in parallel threads.
      #
      # A class is safe when it does NOT use minitest-hooks' `before(:all)` / `after(:all)`,
      # since `parallelize_me!` dispatches individual test methods to the thread pool and
      # bypasses the `with_info_handler` lifecycle that minitest-hooks relies on.
      #
      # Thread count is controlled by the `MT_CPU` environment variable
      # (defaults to `Etc.nprocessors`).
      module Parallel
        class << self
          #: (T::Module[top] base) -> void
          def included(base)
            T.cast(base, T.class_of(Minitest::Test)).parallelize_me!
          end
        end
      end
    end
  end
end
