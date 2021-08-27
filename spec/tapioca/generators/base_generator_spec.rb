# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "tapioca/generators/base_generator"

module Tapioca
  module Generators
    class BaseGeneratorSpec < Minitest::Spec
      it "will always pass" do
        assert true
      end

      private

      sig { returns(BaseGenerator) }
      def generator
        Tapioca::Generators::BaseGenerator.new(
          ConfigBuilder.from_options(:init, {})
        )
      end
    end
  end
end
