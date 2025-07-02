# typed: true
# frozen_string_literal: true

module Tapioca
  module BundlerExt
    # This is a module that gets prepended to `Bundler::Dependency` and
    # makes sure even gems marked as `require: false` are required during
    # `Bundler.require`.
    # @requires_ancestor: ::Bundler::Dependency
    module AutoRequireHook
      extend T::Sig
      @exclude = [] #: Array[String]
      @enabled = false #: bool

      class << self
        extend T::Sig

        #: (untyped name) -> bool
        def excluded?(name)
          @exclude.include?(name)
        end

        def enabled?
          @enabled
        end

        #: [Result] (exclude: Array[String]) { -> Result } -> Result
        def override_require_false(exclude:, &blk)
          @enabled = true
          @exclude = exclude
          blk.call
        ensure
          @enabled = false
        end
      end

      #: -> untyped
      def autorequire
        value = super

        # If autorequire is not enabled, we don't want to force require gems
        return value unless AutoRequireHook.enabled?

        # If the gem is excluded, we don't want to force require it, in case
        # it has side-effects users don't want. For example, `fakefs` gem, if
        # loaded, takes over filesystem operations.
        return value if AutoRequireHook.excluded?(name)

        # If a gem is marked as `require: false`, then its `autorequire`
        # value will be `[]`. But, we want those gems to be loaded for our
        # purposes as well, so we return `nil` in those cases, instead, which
        # means `require: true`.
        return if value == []

        value
      end

      ::Bundler::Dependency.prepend(self)
    end
  end
end
