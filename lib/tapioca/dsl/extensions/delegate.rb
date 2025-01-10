# typed: true
# frozen_string_literal: true

begin
  require "active_support"
rescue LoadError
  return
end

module Tapioca
  module Dsl
    module Compilers
      module Extensions
        module Module
          def __tapioca_delegated_methods
            @__tapioca_delegated_methods ||= []
          rescue FrozenError
            # Some classes are frozen - so we can't define instance variables on them
            # In that case, we'll just give up
            []
          end

          def delegate(*methods, to:, prefix: nil, allow_nil: nil, private: false)
            __tapioca_delegated_methods << {
              methods: methods,
              to: to,
              prefix: prefix,
              allow_nil: allow_nil,
              private: private,
            }

            super
          end

          ::Module.prepend(self)
        end
      end
    end
  end
end
