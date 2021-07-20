# typed: true
# frozen_string_literal: true

module Foo
  class Generator < Tapioca::Compilers::Dsl::Base
    extend T::Sig

    sig do
      override
        .params(root: Tapioca::RBI::Tree, constant: T.class_of(::ActionController::Base))
        .void
    end
    def decorate(root, constant)
    end

    sig { override.returns(T::Enumerable[Module]) }
    def gather_constants
      []
    end
  end
end
