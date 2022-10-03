# typed: true

class Dry::Types::Maybe; end

class Dry::Struct
  sig { returns(::T::Enumerable[::T.untyped]) }
  def self.schema; end
end
