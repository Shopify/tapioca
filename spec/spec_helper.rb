# typed: strict
# frozen_string_literal: true

require "tapioca"
require "minitest/autorun"
require "minitest/spec"
require "minitest/hooks/default"
require "minitest/reporters"

require "content_helper"
require "template_helper"
require "isolation_helper"
require "dsl_spec"

Minitest::Reporters.use!(Minitest::Reporters::SpecReporter.new(color: true))

module Minitest
  class Test
    extend T::Sig

    Minitest::Test.make_my_diffs_pretty!
  end
end
