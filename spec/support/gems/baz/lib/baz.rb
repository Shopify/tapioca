# typed: true
# frozen_string_literal: true

require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.setup

module Baz
  class Test
    def fizz
      "abc" * 10
    end
  end

  class AbstractMethod
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { abstract.void }
    def foo; end

    sig { abstract.returns(String) }
    def bar; end
  end

  class AbstractSingletonMethod
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { abstract.void }
    def self.foo; end

    sig { abstract.returns(String) }
    def self.bar; end
  end

  class AbstractSingletonMethodNested
    extend T::Helpers

    abstract!

    class << self
      extend T::Sig

      sig { abstract.returns(String) }
      def bar; end

      sig { abstract.void }
      def foo; end
    end
  end

  class AbstractSingletonMethodAllNested
    class << self
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { abstract.returns(String) }
      def bar; end

      sig { abstract.void }
      def foo; end
    end
  end
end
