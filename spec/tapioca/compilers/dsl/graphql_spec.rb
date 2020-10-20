# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::GraphqlSpec < DslSpec
  describe("#initialize") do
    it("gathers no constants if there are no Graphql classes") do
      assert_empty(constants_from(""))
    end

    it("gathers only Graphql classes") do
      content = <<~RUBY
        class Money < ::GraphQL::Schema::InputObject
          argument :value, Int, required: true, description: "Decimal money amount."
          argument :currency, String, required: true, description: "Currency code of the money."
        end

        class Random
        end
      RUBY

      assert_equal(["Money"], constants_from(content))
    end
  end
end
