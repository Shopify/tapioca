# typed: true
# frozen_string_literal: true

return unless defined?(FrozenRecord::Base)

module Tapioca
  module Dsl
    module Compilers
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
