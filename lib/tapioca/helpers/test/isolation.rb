# typed: true
# frozen_string_literal: true

require "tapioca/ruby_ext/forking_patch"
require "tapioca/ruby_ext/subprocess_patch"

module Tapioca
  module Helpers
    module Test
      # Copied from ActiveSupport::Testing::Isolation since we cannot require
      # constants from ActiveSupport without polluting the global namespace.
      module Isolation
        extend T::Sig
        require "thread"

        sig { returns(T::Boolean) }
        def self.forking_env?
          !ENV["NO_FORK"] && Process.respond_to?(:fork)
        end

        def run
          serialized = T.unsafe(self).run_in_isolation do
            super
          end

          Marshal.load(serialized)
        end

        if forking_env?
          include(Forking)
        else
          include(Subprocess)
        end
      end
    end
  end
end
