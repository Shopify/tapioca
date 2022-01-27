# typed: strict

module T::Private
  class Abstract::Data
    def self.get(mod, key); end
    def self.set_default(mod, key, value); end
  end

  class Final
    def self.final_module?(mod); end
  end

  class Sealed
    def self.sealed_module?(mod); end
  end

  class Types::NotTyped < T::Types::Base; end
end

class T::Enum
  def values; end
end
