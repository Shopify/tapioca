# typed: strict
# frozen_string_literal: true

require "spec_helper"

require "tapioca/generators/todo_generator"

module Tapioca
  module Generators
    class TodoGeneratorSpec < Minitest::Spec
      private

      sig { returns(TodoGenerator) }
      def generator
        Tapioca::Generators::TodoGenerator.new(
          ConfigBuilder.from_options(:init, {})
        )
      end
    end
  end
end
