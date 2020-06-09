# typed: strict
# frozen_string_literal: true

require "tapioca"
require "minitest/autorun"
require "minitest/spec"
require "minitest/hooks/default"
require "minitest/fork_executor"
require "minitest/reporters"

require "content_helper"
require "template_helper"

Minitest::Reporters.use!(Minitest::Reporters::DefaultReporter.new(color: true))
Minitest.parallel_executor = Minitest::ForkExecutor.new

module Minitest
  class Test
    include ContentHelper
    include TemplateHelper
  end
end
