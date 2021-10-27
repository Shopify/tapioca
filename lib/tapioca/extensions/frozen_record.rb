# typed: true
# frozen_string_literal: true

begin
  require "frozen_record"
rescue LoadError
  return
end

module ScopePatch
  attr_reader :scope_names

  def scope(name, body)
    @scope_names ||= []
    @scope_names << name

    super
  end

  FrozenRecord::Base.singleton_class.prepend(self)
end
