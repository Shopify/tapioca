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

# Minitest::Reporters currently lacks support for Minitest 6
# https://github.com/minitest-reporters/minitest-reporters/issues/368
if Gem::Version.new(Minitest::VERSION) < Gem::Version.new("6.0")
  require "minitest/reporters"
  require "spec_reporter"

  backtrace_filter = Minitest::ExtensibleBacktraceFilter.default_filter
  backtrace_filter.add_filter(%r{gems/sorbet-runtime})
  backtrace_filter.add_filter(%r{gems/railties})
  backtrace_filter.add_filter(%r{tapioca/helpers/test/})

  Minitest::Reporters.use!(SpecReporter.new(color: true), ENV, backtrace_filter)
end

# Minitest 6 split Minitest::Mock out into its own gem
if Gem::Version.new(Minitest::VERSION) >= Gem::Version.new("6.0")
  require "minitest/mock"
end

module Minitest
  class Test
    extend Rails::LineFiltering
  end
end
