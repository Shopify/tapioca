# typed: strict
# frozen_string_literal: true

require "tapioca/internal"
require "minitest/autorun"
require "minitest/spec"
require "minitest/hooks/default"
require "rails/test_unit/line_filtering"

require "tapioca/helpers/test/content"
require "tapioca/helpers/test/template"
require "tapioca/helpers/test/isolation"
require "dsl_spec_helper"
require "spec_with_project"
require "rails_spec_helper"

require "minitest/reporters"
require "spec_reporter"

# Minitest::Reporters currently lacks support for Minitest 6 out of the box
# but we can register the plugin to use it.
# Ref: https://github.com/minitest-reporters/minitest-reporters/pull/366#issuecomment-3731951673
require "minitest/minitest_reporter_plugin"
Minitest.register_plugin(:minitest_reporter)

backtrace_filter = Minitest::ExtensibleBacktraceFilter.default_filter
backtrace_filter.add_filter(%r{gems/sorbet-runtime})
backtrace_filter.add_filter(%r{gems/railties})
backtrace_filter.add_filter(%r{tapioca/helpers/test/})

Minitest::Reporters.use!(SpecReporter.new(color: true), ENV, backtrace_filter)

require "minitest/mock"

module Minitest
  class Test
    extend Rails::LineFiltering
  end
end
