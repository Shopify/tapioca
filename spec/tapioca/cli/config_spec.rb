# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class ConfigTest < SpecWithProject
    describe "cli::configuration" do
      before(:all) do
        @project.bundle_install
      end

      after do
        @project.remove("sorbet/rbi")
      end

      it "validates unknown configuration keys" do
        @project.write("sorbet/tapioca/config.yml", <<~YAML)
          foo: true
          bar:
          - 1
          - 2
          gem:
            doc: true
          dsl:
          typed_overrides:
            foo: "true"
        YAML

        result = @project.tapioca("gem")

        assert_equal(<<~ERR, result.err)

          Configuration file sorbet/tapioca/config.yml has the following errors:

          - unknown key foo
          - unknown key bar
          - unknown key typed_overrides
        ERR

        assert_empty_stdout(result)
        refute_success_status(result)
      end

      it "validates unknown configuration key options" do
        @project.write("sorbet/tapioca/config.yml", <<~YAML)
          gem:
            doc: true
            foo: 1
          dsl:
            bar: []
        YAML

        result = @project.tapioca("gem")

        assert_equal(<<~ERR, result.err)

          Configuration file sorbet/tapioca/config.yml has the following errors:

          - unknown option foo for key gem
          - unknown option bar for key dsl
        ERR

        assert_empty_stdout(result)
        refute_success_status(result)
      end

      it "validates invalid configuration option values" do
        @project.write("sorbet/tapioca/config.yml", <<~YAML)
          gem:
            doc: "true"
            typed_overrides:
            - "true"
            - "false"
            workers: "foo"
          dsl:
            exclude: true
        YAML

        result = @project.tapioca("gem")

        assert_equal(<<~ERR, result.err)

          Configuration file sorbet/tapioca/config.yml has the following errors:

          - invalid value for option doc for key gem - expected Boolean but found String
          - invalid value for option typed_overrides for key gem - expected Hash but found Array
          - invalid value for option workers for key gem - expected Numeric but found String
          - invalid value for option exclude for key dsl - expected Array but found Boolean
        ERR

        assert_empty_stdout(result)
        refute_success_status(result)
      end

      it "validates unknown configuration keys, options, and invalid values" do
        @project.write("sorbet/tapioca/config.yml", <<~YAML)
          gem:
            doc: true
            foo: 1
            typed_overrides: []
          dsl:
            bar: []
            exclude: true
          typed_overrides:
        YAML

        result = @project.tapioca("gem")

        assert_equal(<<~ERR, result.err)

          Configuration file sorbet/tapioca/config.yml has the following errors:

          - unknown option foo for key gem
          - invalid value for option typed_overrides for key gem - expected Hash but found Array
          - unknown option bar for key dsl
          - invalid value for option exclude for key dsl - expected Array but found Boolean
          - unknown key typed_overrides
        ERR

        assert_empty_stdout(result)
        refute_success_status(result)
      end
    end
  end
end
