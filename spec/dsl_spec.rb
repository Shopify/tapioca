# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/spec"
require "tapioca/test_helper"

class DslSpec < Minitest::Spec
  extend T::Sig
  include Tapioca::TestHelper::Dsl

  sig { params(test_class: T.class_of(DslSpec)).void }
  def self.inherited(test_class)
    super
    test_class_name = test_class.name
    return unless test_class_name
    generator_class_name = test_class_name.gsub(/Spec$/, '')
    generator_file_name = underscore(generator_class_name)

    # We want to perform requires etc delayed to ensure namespace is not polluted
    # so we register an `after_setup` method to perform those operations
    test_class.define_method(:after_setup) do
      # Allow other `after_setup` methods to run
      super()
      # Require the file that the target class should be loaded from
      Kernel.require(generator_file_name)
      # Set the class under test (generator class) as the class instance
      T.unsafe(self).generator_class = Object.const_get(generator_class_name)
    end
  end

  class << self
    extend T::Sig

    sig { params(camel_cased_word: String).returns(String) }
    private def underscore(camel_cased_word)
      return camel_cased_word unless /[A-Z-]|::/.match?(camel_cased_word)
      word = camel_cased_word.to_s.gsub("::", "/")
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end
  end
end
