# typed: true
# frozen_string_literal: true

unless defined?(T.anything)
  module T
    class << self
      def anything
        T.untyped
      end
    end
  end
end

unless defined?(T::Class)
  module T
    module Class
      class << self
        def [](type)
          T.untyped
        end
      end
    end
  end
end
