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

    Minitest::Test.make_my_diffs_pretty!
    def indented(str, indent)
      str.lines.map! do |line|
        next line if line.chomp.empty?
        " " * indent + line
      end.join
    end
  end
end
