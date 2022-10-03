# typed: strict
# frozen_string_literal: true

require "tapioca/internal"
require "minitest/autorun"
require "minitest/spec"
require "minitest/hooks/default"
require "minitest/reporters"
require "rails/test_unit/line_filtering"
require "byebug"

require "tapioca/helpers/test/content"
require "tapioca/helpers/test/template"
require "tapioca/helpers/test/isolation"
require "spec_reporter"
require "dsl_spec_helper"
require "spec_with_project"

backtrace_filter = Minitest::ExtensibleBacktraceFilter.default_filter
backtrace_filter.add_filter(%r{gems/sorbet-runtime})
backtrace_filter.add_filter(%r{gems/railties})
backtrace_filter.add_filter(%r{tapioca/helpers/test/})

Minitest::Reporters.use!(SpecReporter.new(color: true), ENV, backtrace_filter)

module Minitest
  class Test
    extend T::Sig
    extend Rails::LineFiltering
  end
end
