# typed: strict

# TODO: Remove this shim once Sorbet understands spec hooks
class Tapioca::SpecWithProject
  sig { params(type: T.nilable(Symbol), block: T.proc.bind(Tapioca::SpecWithProject).void).void }
  def self.after(type = nil, &block); end

  sig { params(type: T.nilable(Symbol), block: T.proc.bind(Tapioca::SpecWithProject).void).void }
  def self.around(type = nil, &block); end

  sig { params(type: T.nilable(Symbol), block: T.proc.bind(Tapioca::SpecWithProject).void).void }
  def self.before(type = nil, &block); end
end
