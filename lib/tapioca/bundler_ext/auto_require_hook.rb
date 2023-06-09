# typed: true
# frozen_string_literal: true

module Tapioca
  module BundlerExt
    # This is a module that gets prepended to `Bundler::Dependency` and
    # makes sure even gems marked as `require: false` are required during
    # `Bundler.require`.
    module AutoRequireHook
      extend T::Sig
      extend T::Helpers

      requires_ancestor { ::Bundler::Dependency }

      @exclude = T.let([], T::Array[String])

      class << self
        extend T::Sig

        sig { params(exclude: T::Array[String]).returns(T::Array[String]) }
        attr_writer :exclude

        sig { params(name: T.untyped).returns(T::Boolean) }
        def excluded?(name)
          @exclude.include?(name)
        end
      end

      sig { returns(T.untyped).checked(:never) }
      def autorequire
        value = super

        # If the gem is excluded, we don't want to force require it, in case
        # it has side-effects users don't want. For example, `fakefs` gem, if
        # loaded, takes over filesystem operations.
        return value if AutoRequireHook.excluded?(name)

        # If a gem is marked as `require: false`, then its `autorequire`
        # value will be `[]`. But, we want those gems to be loaded for our
        # purposes as well, so we return `nil` in those cases, instead, which
        # means `require: true`.
        return nil if value == []

        value
      end

      ::Bundler::Dependency.prepend(self)
    end
  end
end
