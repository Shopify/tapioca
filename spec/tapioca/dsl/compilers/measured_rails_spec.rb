# typed: strict
# frozen_string_literal: true

require "spec_helper"
require "measured"

module Tapioca
  module Dsl
    module Compilers
      class MeasuredRailsSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::MeasuredRails" do
          describe "initialize" do
            it "gathers no constants if there are no ActiveRecord subclasses" do
              assert_empty(gathered_constants)
            end

            it "gathers only ActiveRecord subclasses" do
              add_ruby_file("content.rb", <<~RUBY)
                class Post < ActiveRecord::Base
                end

                class Current
                end
              RUBY

              assert_equal(["Post"], gathered_constants)
            end
          end

          describe "decorate" do
            before do
              require "active_record"

              ::ActiveRecord::Base.establish_connection(
                adapter: "sqlite3",
                database: ":memory:"
              )
            end

            describe "with relations enabled" do
              before do
                require "tapioca/dsl/compilers/measured_rails"
              end

              describe "without errors" do
                it "generates empty RBI file if there are no measured fields" do
                  add_ruby_file("package.rb", <<~RUBY)
                    class Package < ActiveRecord::Base
                    end
                  RUBY

                  expected = <<~RBI
                    # typed: strong
                  RBI

                  assert_equal(expected, rbi_for(:Package))
                end

                it "generates RBI file for measured method" do
                  add_ruby_file("schema.rb", <<~RUBY)
                    ActiveRecord::Migration.suppress_messages do
                      ActiveRecord::Schema.define do
                        create_table :packages do |t|
                          t.decimal :minimum_weight_value, precision: 10, scale: 2
                          t.string :minimum_weight_unit, limit: 12

                          t.decimal :total_length_value, precision: 10, scale: 2, default: 0
                          t.string :total_length_unit, limit: 12, default: "cm"

                          t.decimal :total_volume_value, precision: 10, scale: 2, default: 0
                          t.string :total_volume_unit, limit: 12, default: "l"
                        end
                      end
                    end
                  RUBY

                  add_ruby_file("package.rb", <<~RUBY)
                    class Package < ActiveRecord::Base
                      measured Measured::Weight, :minimum_weight
                      measured Measured::Length, :total_length
                      measured Measured::Volume, :total_volume
                    end
                  RUBY

                  expected = <<~RBI
                    # typed: strong

                    class Package
                      include GeneratedMeasuredRailsMethods

                      module GeneratedMeasuredRailsMethods
                        sig { returns(T.nilable(Measured::Weight)) }
                        def minimum_weight; end

                        sig { params(value: T.nilable(Measured::Weight)).void }
                        def minimum_weight=(value); end

                        sig { returns(T.nilable(Measured::Length)) }
                        def total_length; end

                        sig { params(value: T.nilable(Measured::Length)).void }
                        def total_length=(value); end

                        sig { returns(T.nilable(Measured::Volume)) }
                        def total_volume; end

                        sig { params(value: T.nilable(Measured::Volume)).void }
                        def total_volume=(value); end
                      end
                    end
                  RBI

                  assert_equal(expected, rbi_for(:Package))
                end

                it "generates RBI file for measured_weight method" do
                  add_ruby_file("schema.rb", <<~RUBY)
                    ActiveRecord::Migration.suppress_messages do
                      ActiveRecord::Schema.define do
                        create_table :packages do |t|
                          t.decimal :minimum_weight_value, precision: 10, scale: 2
                          t.string :minimum_weight_unit, limit: 12

                          t.decimal :total_length_value, precision: 10, scale: 2, default: 0
                          t.string :total_length_unit, limit: 12, default: "cm"

                          t.decimal :total_volume_value, precision: 10, scale: 2, default: 0
                          t.string :total_volume_unit, limit: 12, default: "l"
                        end
                      end
                    end
                  RUBY

                  add_ruby_file("package.rb", <<~RUBY)
                    class Package < ActiveRecord::Base
                      measured_weight :minimum_weight
                    end
                  RUBY

                  expected = <<~RBI
                    # typed: strong

                    class Package
                      include GeneratedMeasuredRailsMethods

                      module GeneratedMeasuredRailsMethods
                        sig { returns(T.nilable(Measured::Weight)) }
                        def minimum_weight; end

                        sig { params(value: T.nilable(Measured::Weight)).void }
                        def minimum_weight=(value); end
                      end
                    end
                  RBI

                  assert_equal(expected, rbi_for(:Package))
                end

                it "generates RBI file for measured_length method" do
                  add_ruby_file("schema.rb", <<~RUBY)
                    ActiveRecord::Migration.suppress_messages do
                      ActiveRecord::Schema.define do
                        create_table :packages do |t|
                          t.decimal :minimum_weight_value, precision: 10, scale: 2
                          t.string :minimum_weight_unit, limit: 12

                          t.decimal :total_length_value, precision: 10, scale: 2, default: 0
                          t.string :total_length_unit, limit: 12, default: "cm"

                          t.decimal :total_volume_value, precision: 10, scale: 2, default: 0
                          t.string :total_volume_unit, limit: 12, default: "l"
                        end
                      end
                    end
                  RUBY

                  add_ruby_file("package.rb", <<~RUBY)
                    class Package < ActiveRecord::Base
                      measured_length :total_length
                    end
                  RUBY

                  expected = <<~RBI
                    # typed: strong

                    class Package
                      include GeneratedMeasuredRailsMethods

                      module GeneratedMeasuredRailsMethods
                        sig { returns(T.nilable(Measured::Length)) }
                        def total_length; end

                        sig { params(value: T.nilable(Measured::Length)).void }
                        def total_length=(value); end
                      end
                    end
                  RBI

                  assert_equal(expected, rbi_for(:Package))
                end

                it "generates RBI file for measured_volume method" do
                  add_ruby_file("schema.rb", <<~RUBY)
                    ActiveRecord::Migration.suppress_messages do
                      ActiveRecord::Schema.define do
                        create_table :packages do |t|
                          t.decimal :total_volume_value, precision: 10, scale: 2, default: 0
                          t.string :total_volume_unit, limit: 12, default: "l"
                        end
                      end
                    end
                  RUBY

                  add_ruby_file("package.rb", <<~RUBY)
                    class Package < ActiveRecord::Base
                      measured_volume :total_volume
                    end
                  RUBY

                  expected = <<~RBI
                    # typed: strong

                    class Package
                      include GeneratedMeasuredRailsMethods

                      module GeneratedMeasuredRailsMethods
                        sig { returns(T.nilable(Measured::Volume)) }
                        def total_volume; end

                        sig { params(value: T.nilable(Measured::Volume)).void }
                        def total_volume=(value); end
                      end
                    end
                  RBI

                  assert_equal(expected, rbi_for(:Package))
                end
              end
            end
          end
        end
      end
    end
  end
end
