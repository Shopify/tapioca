# typed: strict

class Set
  sig { returns(T.self_type) }
  def compare_by_identity; end
end

module Set::SubclassCompatible; end
module Set::SubclassCompatible::ClassMethods; end
