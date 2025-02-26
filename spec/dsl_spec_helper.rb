# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/spec"
require "tapioca/helpers/test/dsl_compiler"

class DslSpec < Minitest::Spec
  extend T::Sig
  include Tapioca::Helpers::Test::DslCompiler

  class << self
    extend T::Sig

    #: -> singleton(DslSpec)
    def spec_test_class
      # It should be the one that directly inherits from DslSpec
      class_ancestors = ancestors.grep(Class) #: Array[singleton(DslSpec)]

      klass = class_ancestors
        .take_while { |ancestor| ancestor != DslSpec }
        .last

      T.must(klass)
    end

    #: -> String
    def target_class_name
      # Get the name of the class under test from the name of the
      # test class
      spec_test_class.name.gsub(/Spec$/, "")
    end

    #: -> singleton(Tapioca::Dsl::Compiler)
    def target_class
      Object.const_get(target_class_name)
    end

    #: -> String
    def target_class_file
      underscore(target_class_name)
    end

    #: (String class_name) -> String
    def underscore(class_name)
      return class_name unless /[A-Z-]|::/.match?(class_name)

      word = class_name.to_s.gsub("::", "/")
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end
  end

  before do
    # Require the file that the target class should be loaded from
    require(self.class.target_class_file)
    use_dsl_compiler(self.class.target_class)
    @expecting_errors = false
  end

  after do
    assert_empty(generated_errors) unless @expecting_errors
    generated_errors.clear
  end

  #: -> bool?
  def expect_dsl_compiler_errors!
    @expecting_errors = true #: bool?
  end
end
