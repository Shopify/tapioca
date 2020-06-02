# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe(Tapioca::Compilers::Dsl::ActionMailer) do
  describe("#initialize") do
    it("gathers no constants if there are no ActionMailer subclasses") do
      expect(subject.processable_constants).to(be_empty)
    end

    it("gathers only ActionMailer subclasses") do
      content = <<~RUBY
        class NotifierMailer < ActionMailer::Base
        end

        class User
        end
      RUBY

      with_contents(content) do
        expect(subject.processable_constants).to(eq(Set.new([NotifierMailer])))
      end
    end
    it("ignores abstract subclasses") do
      content = <<~RUBY
        class NotifierMailer < ActionMailer::Base
        end

        class SecondayMailer < ActionMailer::Base
          abstract!
        end
      RUBY

      with_contents(content) do
        expect(subject.processable_constants).to(eq(Set.new([NotifierMailer])))
      end
    end
  end

  describe("#decorate") do
    let(:output) do
      parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
      subject.decorate(parlour.root, NotifierMailer)
      parlour.rbi
    end

    it("generates empty RBI file if there are no methods") do
      content = <<~RUBY
        class NotifierMailer < ActionMailer::Base
        end
      RUBY

      expected = <<~RUBY
        # typed: strong
        class NotifierMailier
        end
      RUBY

      with_contents(content) do
        expect(output).to(eq(expected))
      end
    end
  end
end
