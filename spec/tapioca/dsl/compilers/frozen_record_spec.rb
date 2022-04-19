# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class FrozenRecordSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::FrozenRecord" do
          sig { void }
          def before_setup
            require "rails/railtie"
            require "tapioca/dsl/extensions/frozen_record"
          end

          describe "initialize" do
            it "gathers no constants if there are no FrozenRecord classes" do
              assert_empty(gathered_constants)
            end

            it "gathers only FrozenRecord classes" do
              add_ruby_file("content.rb", <<~RUBY)
                class Student < FrozenRecord::Base
                end

                class Teacher
                end
              RUBY

              assert_equal(["Student"], gathered_constants)
            end
          end

          describe "decorate" do
            it "generates empty RBI file if there are no frozen records" do
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

            it "generates an RBI file for frozen records" do
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

            it "can handle annotated fields" do
              add_ruby_file("student.rb", <<~RUBY)
                # typed: strong

                class ArrayOfType < ActiveModel::Type::Value
                  attr_reader :element_type

                  def initialize(element_type:)
                    super()
                    @element_type = element_type
                  end

                  def type
                    :array
                  end
                end

                class HashOfType < ActiveModel::Type::Value
                  attr_reader :key_type
                  attr_reader :value_type

                  def initialize(key_type:, value_type:)
                    super()
                    @key_type = key_type
                    @value_type = value_type
                  end

                  def type
                    :hash
                  end
                end

                class SymbolType < ActiveModel::Type::Value
                  def type
                    :symbol
                  end
                end

                ActiveModel::Type.register(:array_of_type, ArrayOfType)
                ActiveModel::Type.register(:hash_of_type, HashOfType)
                ActiveModel::Type.register(:symbol, SymbolType)

                class Student < FrozenRecord::Base
                  extend T::Sig
                  include ActiveModel::Attributes

                  # specifically missing the id field, should be untyped
                  attribute :first_name, :string
                  attribute :last_name, :string
                  attribute :age, :integer
                  attribute :location, :string
                  attribute :is_cool_person, :boolean
                  attribute :birth_date, :date
                  attribute :updated_at, :time
                  # custom attribute types
                  attribute :favourite_foods, :array_of_type, element_type: :string
                  attribute :skills, :hash_of_type, key_type: :symbol, value_type: :string
                  # attribute with a default, shouldn't be nilable
                  attribute :shirt_size, :symbol

                  self.base_path = __dir__
                  self.default_attributes = { shirt_size: :large }

                  # Explicit method, shouldn't be in the RBI output
                  sig { params(grain: Symbol).returns(String) }
                  def area(grain:)
                    parts = location.split(',').map(&:strip)
                    case grain
                    when :city
                      parts[0]
                    when :province
                      parts[1]
                    when :country
                      parts[2]
                    else
                      location
                    end
                  end
                end
              RUBY

              add_content_file("students.yml", <<~YAML)
                - id: 1
                  first_name: John
                  last_name: Smith
                  age: 19
                  location: Ottawa, Ontario, Canada
                  is_cool_person: no
                  birth_date: 1867-07-01
                  updated_at: 2014-02-24T19:08:06-05:00
                  favourite_foods:
                    - Pizza
                  skills:
                    backend: Ruby
                    frontend: HTML
                - id: 2
                  first_name: Dan
                  last_name:  Lord
                  age: 20
                  location: Toronto, Ontario, Canada
                  is_cool_person: yes
                  birth_date: 1967-07-01
                  updated_at: 2015-02-24T19:08:06-05:00
                  favourite_foods:
                    - Tacos
                  skills:
                    backend: Ruby
                    frontend: CSS
              YAML

              expected = <<~RBI
                # typed: strong

                class Student
                  include FrozenRecordAttributeMethods

                  module FrozenRecordAttributeMethods
                    sig { returns(T.nilable(::Integer)) }
                    def age; end

                    sig { returns(T::Boolean) }
                    def age?; end

                    sig { returns(T.nilable(::Date)) }
                    def birth_date; end

                    sig { returns(T::Boolean) }
                    def birth_date?; end

                    sig { returns(T.nilable(::Array)) }
                    def favourite_foods; end

                    sig { returns(T::Boolean) }
                    def favourite_foods?; end

                    sig { returns(T.nilable(::String)) }
                    def first_name; end

                    sig { returns(T::Boolean) }
                    def first_name?; end

                    sig { returns(T.untyped) }
                    def id; end

                    sig { returns(T::Boolean) }
                    def id?; end

                    sig { returns(T.nilable(T::Boolean)) }
                    def is_cool_person; end

                    sig { returns(T::Boolean) }
                    def is_cool_person?; end

                    sig { returns(T.nilable(::String)) }
                    def last_name; end

                    sig { returns(T::Boolean) }
                    def last_name?; end

                    sig { returns(T.nilable(::String)) }
                    def location; end

                    sig { returns(T::Boolean) }
                    def location?; end

                    sig { returns(::Symbol) }
                    def shirt_size; end

                    sig { returns(T::Boolean) }
                    def shirt_size?; end

                    sig { returns(T.nilable(::Hash)) }
                    def skills; end

                    sig { returns(T::Boolean) }
                    def skills?; end

                    sig { returns(T.nilable(::DateTime)) }
                    def updated_at; end

                    sig { returns(T::Boolean) }
                    def updated_at?; end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Student))
            end

            it "can handle frozen record scopes" do
              add_ruby_file("student.rb", <<~RUBY)
                class Student < FrozenRecord::Base
                  self.base_path = __dir__

                  scope :programmers, -> { where(course: "Programming") }
                end
              RUBY

              add_content_file("students.yml", <<~YAML)
                - id: 1
                  course: Programming
                - id: 2
                  course: Design
              YAML

              expected = <<~RBI
                # typed: strong

                class Student
                  include FrozenRecordAttributeMethods
                  extend GeneratedRelationMethods

                  module FrozenRecordAttributeMethods
                    sig { returns(T.untyped) }
                    def course; end

                    sig { returns(T::Boolean) }
                    def course?; end

                    sig { returns(T.untyped) }
                    def id; end

                    sig { returns(T::Boolean) }
                    def id?; end
                  end

                  module GeneratedRelationMethods
                    sig { params(args: T.untyped, blk: T.untyped).returns(T.untyped) }
                    def programmers(*args, &blk); end
                  end
                end
              RBI

              assert_equal(expected, rbi_for(:Student))
            end
          end
        end
      end
    end
  end
end
