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
end
