# typed: true
# frozen_string_literal: true

module T
  module Class
    class << self
      def [](type)
        if type.is_a?(T::Types::Untyped)
          T::Types::TypedClass::Untyped::Private::INSTANCE
        elsif type.is_a?(T::Types::Anything)
          T::Types::TypedClass::Anything::Private::INSTANCE
        else
          T::Types::TypedClass::Private::Pool.type_for_module(type)
        end
      end
    end
  end
end
