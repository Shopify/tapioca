# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::FrozenRecordSpec < DslSpec
  before(:each) do
    require "rails/railtie"
  end

  describe("#initialize") do
    it("gathers no constants if there are no FrozenRecord classes") do
      assert_empty(gathered_constants)
    end

    it("gathers only FrozenRecord classes") do
      add_ruby_file("content.rb", <<~RUBY)
        class Student < FrozenRecord::Base
        end

        class Teacher
        end
      RUBY

      assert_equal(["Student"], gathered_constants)
    end
  end

  describe("#decorate") do
    it("generates empty RBI file if there are no frozen records") do
      add_ruby_file("student.rb", <<~RUBY)
        class Student < FrozenRecord::Base
          self.base_path = __dir__
        end
      RUBY

      add_content_file("students.yml", <<~YAML)
      YAML

      expected = <<~RBI
        # typed: strong
      RBI

      assert_equal(expected, rbi_for(:Student))
    end

    it("generates an RBI file for frozen records") do
      add_ruby_file("student.rb", <<~RUBY)
        class Student < FrozenRecord::Base
          self.base_path = __dir__
        end
      RUBY

      add_content_file("students.yml", <<~YAML)
        - id: 1
          first_name: John
          last_name: Smith
        - id: 2
          first_name: Dan
          last_name:  Lord
      YAML

      expected = <<~RBI
        # typed: strong

        class Student
          include FrozenRecordAttributeMethods

          module FrozenRecordAttributeMethods
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
        end
      RBI

      assert_equal(expected, rbi_for(:Student))
    end
  end
end
