# typed: true
# frozen_string_literal: true

require "spec_helper"
require "tapioca/helpers/test/template"

module Tapioca
  class BackwardsCompatibilitySpec < SpecWithProject
    before do
      @project = mock_project(sorbet_dependency: false)
    end

    after do
      @project.destroy!
    end

    # Add backcompat tests here
  end
end
