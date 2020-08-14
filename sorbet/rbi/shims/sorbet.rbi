# typed: strict

module T::Private
  module Abstract
    class Data
      def self.get(mod, key); end
    end
  end

  class Final
    def self.final_module?(mod); end
  end

  class Sealed
    def self.sealed_module?(mod); end
  end

  module Types
    class NotTyped < T::Types::Base
    end
  end
end
