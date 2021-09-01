# typed: true
# frozen_string_literal: true

class GeneratorThatIncludesFooModuleInPost < Tapioca::Compilers::Dsl::Base
  extend T::Sig

  sig do
    override
      .params(root: RBI::Tree, constant: T.class_of(Post))
      .void
  end
  def decorate(root, constant)
    root.create_path(constant) do |klass|
      klass.create_module("GeneratedBar")
      klass.create_include("GeneratedBar")
    end
  end

  sig { override.returns(T::Enumerable[Module]) }
  def gather_constants
    [Post]
  end
end
