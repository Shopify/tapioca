# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module Dsl
    module Compilers
      class ActiveSupportConcernSpec < ::DslSpec
        describe "Tapioca::Dsl::Compilers::ActiveSupportConcern" do
          sig { void }
          def before_setup
            require "active_support"
          end

          describe "gather_constants" do
            it "does not gather anonymous constants" do
              add_ruby_file("test_case.rb", <<~RUBY)
                module TestCase
                  module Foo
                    extend ActiveSupport::Concern
                  end

                  class Baz
                    constant = Module.new do
                      extend ActiveSupport::Concern
                      include Foo

                      def self.name
                        "TestName"
                      end
                    end

                    include constant
                  end
                end
              RUBY

              assert_equal([], gathered_constants_in_namespace(:TestCase))
            end

            it "does not gather constants that don't extend ActiveSupport::Concern" do
              add_ruby_file("test_case.rb", <<~RUBY)
                module TestCase
                  module Foo
                    extend ActiveSupport::Concern
                  end

                  module Bar
                    include Foo
                  end

                  class Baz
                    include Bar
                  end
                end
              RUBY

              assert_equal([], gathered_constants_in_namespace(:TestCase))
            end

            it "does not gather constants when its mixins don't extend ActiveSupport::Concern" do
              add_ruby_file("test_case.rb", <<~RUBY)
                module TestCase
                  module Foo
                  end

                  module Bar
                    extend ActiveSupport::Concern
                    include Foo
                  end

                  class Baz
                    include Bar
                  end
                end
              RUBY

              assert_equal([], gathered_constants_in_namespace(:TestCase))
            end

            it "does not gather constants for directly mixed in modules" do
              add_ruby_file("test_case.rb", <<~RUBY)
                module TestCase
                  module Foo
                    extend ActiveSupport::Concern

                    module ClassMethods
                    end
                  end

                  class Bar
                    include Foo
                  end
                end
              RUBY

              assert_equal([], gathered_constants_in_namespace(:TestCase))
            end

            it "does not gather constants that inherit from a class that extend ActiveSupport::Concern" do
              add_ruby_file("test_case.rb", <<~RUBY)
                module TestCase
                  module Foo
                    extend ActiveSupport::Concern
                  end

                  class Bar
                    extend ActiveSupport::Concern
                    include Foo
                  end

                  class Baz < Bar
                    include Foo
                  end
                end
              RUBY

              assert_equal(["TestCase::Bar"], gathered_constants_in_namespace(:TestCase))
            end

            it "gathers constants for nested AS::Concern" do
              add_ruby_file("test_case.rb", <<~RUBY)
                module TestCase
                  module Foo
                    extend ActiveSupport::Concern
                  end

                  module Bar
                    extend ActiveSupport::Concern
                    include Foo
                  end

                  class Baz
                    include Bar
                  end
                end
              RUBY

              assert_equal(["TestCase::Bar"], gathered_constants_in_namespace(:TestCase))
            end

            it "gathers constants for many nested mixins" do
              add_ruby_file("test_case.rb", <<~RUBY)
                module TestCase
                  module Foo
                    extend ActiveSupport::Concern
                  end

                  module Bar
                    extend ActiveSupport::Concern
                    include Foo
                  end

                  module Baz
                    extend ActiveSupport::Concern
                    include Bar
                  end

                  module Qux
                    extend ActiveSupport::Concern
                    include Baz
                  end

                  class Quux
                    include Qux
                  end
                end
              RUBY

              assert_equal(
                ["TestCase::Bar", "TestCase::Baz", "TestCase::Qux"],
                gathered_constants_in_namespace(:TestCase),
              )
            end
          end

          describe "decorate" do
            it "does not generate RBI when constant does not define a ClassMethods module" do
              add_ruby_file("test_case.rb", <<~RUBY)
                module Foo
                  extend ActiveSupport::Concern
                end

                module Bar
                  extend ActiveSupport::Concern
                  include Foo
                end

                class Baz
                  include Bar
                end
              RUBY

              expected = <<~RUBY
                # typed: strong
              RUBY

              assert_equal(expected, rbi_for(:Bar))
            end

            it "generates RBI for nested AS::Concern" do
              add_ruby_file("test_case.rb", <<~RUBY)
                module Foo
                  extend ActiveSupport::Concern

                  module ClassMethods
                  end
                end

                module Bar
                  extend ActiveSupport::Concern
                  include Foo

                  module ClassMethods
                  end
                end

                class Baz
                  include Bar
                end
              RUBY

              expected = <<~RUBY
                # typed: strong

                module Bar
                  mixes_in_class_methods ::Foo::ClassMethods
                end
              RUBY

              assert_equal(expected, rbi_for(:Bar))
              assert_equal(
                class_method_ancestors_for(:Baz),
                arguments_to_micm_in_effective_order(rbi_for(:Bar)),
              )
            end

            it "generates RBI for many nested mixins" do
              add_ruby_file("test_case.rb", <<~RUBY)
                module Foo
                  extend ActiveSupport::Concern

                  module ClassMethods
                  end
                end

                module Bar
                  extend ActiveSupport::Concern
                  include Foo

                  module ClassMethods
                  end
                end

                module Baz
                  extend ActiveSupport::Concern

                  module ClassMethods
                  end
                end

                module Qux
                  extend ActiveSupport::Concern
                  include Baz
                  include Bar

                  module ClassMethods
                  end
                end

                class Quux
                  include Qux
                end
              RUBY

              expected_bar = <<~RUBY
                # typed: strong

                module Bar
                  mixes_in_class_methods ::Foo::ClassMethods
                end
              RUBY
              assert_equal(expected_bar, rbi_for(:Bar))

              expected_qux = <<~RUBY
                # typed: strong

                module Qux
                  mixes_in_class_methods ::Baz::ClassMethods
                  mixes_in_class_methods ::Foo::ClassMethods
                  mixes_in_class_methods ::Bar::ClassMethods
                end
              RUBY

              assert_equal(expected_qux, rbi_for(:Qux))
              assert_equal(
                class_method_ancestors_for(:Quux),
                arguments_to_micm_in_effective_order(rbi_for(:Qux)),
              )
            end
          end
        end

        private

        def gathered_constants_in_namespace(namespace)
          gathered_constants.select { |const| const.start_with?("#{namespace}::") }
        end

        def class_method_ancestors_for(constant_name)
          constant = Object.const_get(constant_name)
          constant.singleton_class.ancestors.map(&:to_s).select do |name|
            name.end_with?("::ClassMethods")
          end.drop(1)
        end

        def arguments_to_micm_in_effective_order(rbi)
          rbi.scan(/mixes_in_class_methods (.*)$/)
            .flatten
            .reverse
            .map { |i| i.sub("::", "") }
        end
      end
    end
  end
end
