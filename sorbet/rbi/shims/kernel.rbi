# typed: strict

# ActiveRecord::TestFixtures can't be loaded outside of a Rails application

module Kernel
  sig do
    type_parameters(:Type)
      .params(type: T::Class[T.type_parameter(:Type)])
      .returns(T.type_parameter(:Type))
  end
  def as!(type); end

  sig do
    type_parameters(:Type)
      .params(type: T::Class[T.type_parameter(:Type)])
      .returns(T.type_parameter(:Type))
  end
  def as?(type); end

  sig { returns(T.self_type) }
  def non_nil!; end
end
