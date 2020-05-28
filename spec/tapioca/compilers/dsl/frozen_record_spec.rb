# typed: false
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe("Tapioca::Compilers::Dsl::FrozenRecord") do
  before(:each) do |example|
    require "tapioca/compilers/dsl/frozen_record"
  end

  describe("#initialize") do
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

      with_contents({"file.rb" => content}) do
        expect(subject.processable_constants).to(eq(Set.new([Student])))
      end
    end
  end

  describe("#decorate") do
    let(:output) do
      parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
      subject.decorate(parlour.root, Student)
      parlour.rbi
    end

    it("genereates empty RBI file if there are no frozen records") do
      files = {
        "file.rb" => <<~RUBY,
          class Student < FrozenRecord::Base
          end
        RUBY

        "students.yml" => <<~YAML
        YAML
      }

      expected = <<~RUBY
        # typed: strong

      RUBY

      with_contents(files) do |dir|
        FrozenRecord::Base.base_path = dir + "lib"
        expect(output).to(eq(expected))
      end
    end

    it("genereates an RBI file for frozen records") do
      files = {
        "file.rb" => <<~RUBY,
          class Student < FrozenRecord::Base
          end
        RUBY

        "students.yml" => <<~YAML
          - id: 1
            first_name: John
            last_name: Smith
          - id: 2
            first_name: Dan
            last_name:  Lord
        YAML
      }
      # TODO: Output from documentation. Delete
      # expected = <<~RUBY
      #   # typed: true
      #   class Student
      #     sig { returns(T::Boolean) }
      #     def first_name?; end

      #     sig { returns(T.untyped) }
      #     def first_name; end

      #     sig { returns(T::Boolean) }
      #     def last_name?; end

      #     sig { returns(T.untyped) }
      #     def last_name; end
      #  end
      # RUBY

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

      with_contents(files) do |dir|
        FrozenRecord::Base.base_path = dir + "lib"
        expect(output).to(eq(expected))
      end
    end
  end
end
