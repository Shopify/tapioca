# typed: true
# frozen_string_literal: true

module Tapioca
  module Runtime
    module Trackers
      module RequiredAncestor
        @required_ancestors_map = {}.compare_by_identity

        class << self
          extend T::Sig

          sig { params(requiring: T::Helpers, block: T.proc.returns(Module)).void }
          def register(requiring, block)
            ancestors = @required_ancestors_map[requiring] ||= []
            ancestors << block
          end

          sig { params(mod: Module).returns(T::Array[T.proc.returns(Module)]) }
          def required_ancestors_blocks_by(mod)
            @required_ancestors_map[mod] || []
          end

          sig { params(mod: Module).returns(T::Array[T.nilable(Module)]) }
          def required_ancestors_by(mod)
            blocks = required_ancestors_blocks_by(mod)
            blocks.map do |block|
              block.call
            rescue NameError
              # The ancestor required doesn't exist, let's return nil and let the compiler decide what to do.
              nil
            end
          end
        end
      end
    end
  end
end

module T
  module Helpers
    prepend(Module.new do
      def requires_ancestor(&block)
        # We can't directly call the block since the ancestor might not be loaded yet.
        # We save the block in the map and will resolve it later.
        Tapioca::Runtime::Trackers::RequiredAncestor.register(self, block)

        super
      end
    end)
  end
end
