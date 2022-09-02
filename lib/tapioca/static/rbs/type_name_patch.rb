# typed: true
# frozen_string_literal: true

module Tapioca
  module Static
    module Rbs
      module TypeNamePatch
        extend T::Helpers

        requires_ancestor { RBS::TypeName }

        def to_s
          case kind
          when :class
            super
          when :alias
            "::TypeAliases#{namespace.absolute!}TypeAlias_#{name}"
          when :interface
            "::Interfaces#{namespace.absolute!}Interface#{name}"
          end
        end

        ::RBS::TypeName.prepend(self)
      end
    end
  end
end
