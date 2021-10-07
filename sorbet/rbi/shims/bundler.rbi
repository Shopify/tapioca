# typed: true

class Bundler::StubSpecification
  sig { returns(T::Boolean) }
  def default_gem?; end

  sig { returns(T::Array[String]) }
  def files; end
end
