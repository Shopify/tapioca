# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "tapioca/generators/dsl_generator"

module Tapioca
  module Generators
    class DslGeneratorSpec < Minitest::Spec
      private

      sig { returns(DslGenerator) }
      def generator
        Tapioca::Generators::DslGenerator.new(
          ConfigBuilder.from_options(:init, {})
        )
      end
    end
  end
end
