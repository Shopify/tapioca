# typed: true
# frozen_string_literal: true

module T
  module Types
    class Simple
      module NamePatch
        def name
          @qualified_name ||= qualified_name_of(@raw_type).freeze
        end

        private

        NAME_METHOD = Module.instance_method(:name)

        def qualified_name_of(constant)
          name = NAME_METHOD.bind(constant).call
          return if name.nil?

          if name.start_with?("::")
            name
          else
            "::#{name}"
          end
        end
      end

      prepend NamePatch
    end
  end
end
