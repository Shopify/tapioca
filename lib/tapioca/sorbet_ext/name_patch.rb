# typed: true
# frozen_string_literal: true

module T
  module Types
    class Simple
      module NamePatch
        def name
          @name ||= ::Tapioca::Reflection.name_of(@raw_type).freeze
        end
      end

      prepend NamePatch
    end
  end
end
