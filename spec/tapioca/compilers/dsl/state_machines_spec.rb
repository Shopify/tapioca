# typed: false
# frozen_string_literal: true

require "spec_helper"
RSpec.describe(Tapioca::Compilers::Dsl::StateMachines) do
  describe("#initialize") do
    it("gathers no constants if there are no StateMachines classes") do
      expect(subject.processable_constants).to(be_empty)
    end
  end
end
