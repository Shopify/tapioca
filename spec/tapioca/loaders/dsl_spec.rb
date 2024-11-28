# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Loaders
    class DslSpec < SpecWithProject
      describe "#load_application" do
        it "loads the application if `lsp_addon` is false" do
          outputs = capture_io do
            Loaders::Dsl.load_application(
              tapioca_path: @project.absolute_path,
              app_root: @project.absolute_path,
              lsp_addon: false,
            )
          end

          output = outputs.first # TODO: why are there two outputs?

          assert_match(/Loading DSL extension classes.../, output)
          assert_match(/Loading Rails application/, output)
          assert_match(/Loading DSL compiler classes.../, output)
        end

        it "does not load the application if `lsp_addon` is true" do
          outputs = capture_io do
            Loaders::Dsl.load_application(
              tapioca_path: @project.absolute_path,
              app_root: @project.absolute_path,
              lsp_addon: true,
            )
          end

          output = outputs.first # TODO: why are there two outputs?

          assert_match(/Loading DSL extension classes.../, output)
          refute_match(/Loading Rails application/, output)
          assert_match(/Loading DSL compiler classes.../, output)
        end
      end
    end
  end
end
