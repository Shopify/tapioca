# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::Compilers::Dsl::MixedInClassAttributesSpec < DslSpec
  before do
    require "active_support/core_ext/class/attribute"
    require "active_support/concern"
  end

  describe "#gather_constants" do
    after do
      T.unsafe(self).assert_no_generated_errors
    end

    it "gathers modules that respond to class_attribute" do
      add_ruby_file("file.rb", <<~RUBY)
        module ManualIncluded
          def self.included(base); end
        end

        module Concern
          extend ActiveSupport::Concern
        end

        module SomeOtherModule
        end
      RUBY

      assert_includes(gathered_constants, "ManualIncluded")
      assert_includes(gathered_constants, "Concern")
      refute_includes(gathered_constants, "SomeOtherModule")
    end

    it "gathers modules with private included hooks" do
      add_ruby_file("file.rb", <<~RUBY)
        module PrivateIncluded
          def self.included(base); end
          private_class_method :included
        end
      RUBY

      assert_includes(gathered_constants, "PrivateIncluded")
    end
  end

  describe "#decorate" do
    after do
      T.unsafe(self).assert_no_generated_errors
    end

    it "does nothing if the module doesn't use class_attribute" do
      add_ruby_file("empty.rb", <<~RUBY)
        module Empty
          def self.included(base)
          end
        end
      RUBY

      expected = <<~RBI
        # typed: strong
      RBI

      assert_equal(expected, rbi_for(:Empty))
    end

    it "generates class attribute RBIs when using manual included hooks" do
      add_ruby_file("manual.rb", <<~RUBY)
        module Manual
          def self.included(base)
            base.class_attribute :tag
          end
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        module Manual
          include GeneratedInstanceMethods

          mixes_in_class_methods GeneratedClassMethods

          module GeneratedClassMethods
            def tag; end
            def tag=(value); end
            def tag?; end
          end

          module GeneratedInstanceMethods
            def tag; end
            def tag=(value); end
            def tag?; end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Manual))
    end

    it "generates class attribute RBIs when using concerns" do
      add_ruby_file("taggeable.rb", <<~RUBY)
        module Taggeable
          extend ActiveSupport::Concern

          included do
            class_attribute :tag
          end
        end
      RUBY

      expected = <<~RBI
        # typed: strong

        module Taggeable
          include GeneratedInstanceMethods

          mixes_in_class_methods GeneratedClassMethods

          module GeneratedClassMethods
            def tag; end
            def tag=(value); end
            def tag?; end
          end

          module GeneratedInstanceMethods
            def tag; end
            def tag=(value); end
            def tag?; end
          end
        end
      RBI

      assert_equal(expected, rbi_for(:Taggeable))
    end
  end
end
