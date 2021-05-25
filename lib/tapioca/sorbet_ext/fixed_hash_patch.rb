# typed: true
# frozen_string_literal: true

module T
  module Types
    class FixedHash
      def name
        entries = @types.map do |(k, v)|
          if Symbol === k && ":#{k}" == k.inspect
            "#{k}: #{v}"
          else
            "#{k.inspect} => #{v}"
          end
        end

        "{#{entries.join(', ')}}"
      end
    end
  end
end
