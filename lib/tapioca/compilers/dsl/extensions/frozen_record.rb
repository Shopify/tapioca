# typed: true
# frozen_string_literal: true

begin
  require "frozen_record"
rescue LoadError
  return
end

module Tapioca
  module Compilers
    module Dsl
      module Extensions
        module FrozenRecord
          attr_reader :__tapioca_scope_names

          def scope(name, body)
            @__tapioca_scope_names ||= []
            @__tapioca_scope_names << name

            super
          end

          ::FrozenRecord::Base.singleton_class.prepend(self)
        end
      end
    end
  end
end
