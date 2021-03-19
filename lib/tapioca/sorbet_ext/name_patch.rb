# typed: true
# frozen_string_literal: true

module T
  module Types
    class Simple
      module NamePatch
        def name
          @name ||= Module.instance_method(:name).bind(@raw_type).call.freeze
        end
      end

      prepend NamePatch
    end
  end
end
