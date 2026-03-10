# typed: strict
# frozen_string_literal: true

require "tapioca/internal"
require "minitest/autorun"
require "minitest/spec"
require "minitest/hooks"  # Changed from default to avoid unnecessary hook registration
require "rails/test_unit/line_filtering"

require "tapioca/helpers/test/content"
require "tapioca/helpers/test/template"
require "tapioca/helpers/test/isolation"
require "dsl_spec_helper"
require "spec_with_project"
require "rails_spec_helper"

# Use default minitest reporter (faster than SpecReporter)

require "minitest/mock"

module Minitest
  class Test
    extend Rails::LineFiltering
  end
end
