# typed: false
# frozen_string_literal: true

require 'spec_helper'
require "tapioca/compilers/dsl/frozen_record"

RSpec.describe(Tapioca::Compilers::Dsl::FrozenRecord) do
  describe("#initialize") do
    def constants_from(content)
      with_content(content) do
        subject.processable_constants.map(&:to_s).sort
      end
    end

    it("gathers no constants if there are no FrozenRecord classes") do
      expect(subject.processable_constants).to(be_empty)
    end

    it("gathers only FrozenRecord classes") do
      content = <<~RUBY
        class Student < FrozenRecord::Base
        end

        class Teacher
        end
      RUBY

      expect(constants_from(content)).to(eq(["Student"]))
    end
  end

  describe("#decorate") do
    def rbi_for(contents)
      with_contents(contents) do |dir|
        FrozenRecord::Base.base_path = dir + "lib"
        parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
        subject.decorate(parlour.root, Student)
        parlour.rbi
      end
    end

    it("generates empty RBI file if there are no frozen records") do
      files = {
        "file.rb" => <<~RUBY,
          class Student < FrozenRecord::Base
          end
        RUBY

        "students.yml" => <<~YAML,
        YAML
      }

      expected = <<~RUBY
        # typed: strong

      RUBY

      expect(rbi_for(files)).to(eq(expected))
    end

    it("generates an RBI file for frozen records") do
      files = {
        "file.rb" => <<~RUBY,
          class Student < FrozenRecord::Base
          end
        RUBY

        "students.yml" => <<~YAML,
          - id: 1
            first_name: John
            last_name: Smith
          - id: 2
            first_name: Dan
            last_name:  Lord
        YAML
      }

      expected = <<~RUBY
        # typed: strong
        class Student
          include Student::FrozenRecordAttributeMethods
        end

        module Student::FrozenRecordAttributeMethods
          sig { returns(T.untyped) }
          def first_name; end

          sig { returns(T::Boolean) }
          def first_name?; end

          sig { returns(T.untyped) }
          def id; end

          sig { returns(T::Boolean) }
          def id?; end

          sig { returns(T.untyped) }
          def last_name; end

          sig { returns(T::Boolean) }
          def last_name?; end
        end
      RUBY

      expect(rbi_for(files)).to(eq(expected))
    end
  end
end
