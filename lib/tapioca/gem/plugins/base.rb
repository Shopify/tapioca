# typed: strict
# frozen_string_literal: true

require "pathname"

module Tapioca
  module Gem
    module Plugins
      class Base
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { params(cls: RBI::Class).void }
        def decorate_class(cls)
        end

        sig { params(mod: RBI::Module).void }
        def decorate_module(mod)
        end

        sig { params(const: RBI::Const).void }
        def decorate_const(const)
        end

        sig { params(meth: RBI::Method).void }
        def decorate_method(meth)
        end
      end
    end
  end
end
