# typed: strict
# frozen_string_literal: true

begin
  require "frozen_record"
rescue LoadError
  return
end

module ScopePatch
  extend T::Sig

  sig { returns(T.nilable(T::Array[T.any(String, Symbol)])) }
  attr_reader :scope_names

  sig { params(name: T.untyped, body: T.untyped).void }
  def scope(name, body)
    @scope_names ||= T.let([], T.nilable(T::Array[T.any(String, Symbol)]))
    T.must(@scope_names) << name

    super
  end
end

FrozenRecord::Base.singleton_class.prepend(ScopePatch)
