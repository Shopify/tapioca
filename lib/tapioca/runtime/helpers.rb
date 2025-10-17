# typed: strict
# frozen_string_literal: true

module Tapioca
  module Runtime
    NOOP_METHOD = ->(*_args, **_kwargs, &_block) {} #: ^() -> void
    private_constant :NOOP_METHOD

    class << self
      #: [Result] { -> Result } -> Result
      def silence_warnings(&blk)
        original_verbosity = $VERBOSE
        $VERBOSE = nil
        ::Gem::DefaultUserInteraction.use_ui(::Gem::SilentUI.new) do
          blk.call
        end
      ensure
        $VERBOSE = original_verbosity
      end

      #: [Result] { -> Result } -> Result
      def with_disabled_exits(&block)
        original_abort = Kernel.instance_method(:abort)
        original_exit = Kernel.instance_method(:exit)

        begin
          Kernel.define_method(:abort, NOOP_METHOD)
          Kernel.define_method(:exit, NOOP_METHOD)

          silence_warnings do
            block.call
          end
        ensure
          Kernel.define_method(:exit, original_exit)
          Kernel.define_method(:abort, original_abort)
        end
      end
    end
  end
end
