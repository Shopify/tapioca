# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/spec"
require "content_helper"
require "template_helper"
require "isolation_helper"

class DslSpec < Minitest::Spec
  extend T::Sig
  include Kernel
  include ContentHelper
  include TemplateHelper
  include IsolationHelper

  sig { void }
  def after_setup
    # Require the file that the target class should be loaded from
    require(T.unsafe(self).target_class_file)
  end

  subject do
    # Get the class under test and initialize a new instance of it
    # as the "subject"
    class_name = T.unsafe(self).target_class_name
    Object.const_get(class_name).new
  end

  sig { returns(Class) }
  def spec_test_class
    # Find the spec test class
    klass = T.unsafe(self).class
    # It should be the one that directly inherits from DslSpec
    klass = klass.superclass while klass.superclass != DslSpec
    klass
  end

  sig { returns(String) }
  def target_class_name
    # Get the name of the class under test from the name of the
    # test class
    T.must(spec_test_class.name).gsub(/Spec$/, '')
  end

  sig { returns(String) }
  def target_class_file
    underscore(target_class_name)
  end

  sig { params(camel_cased_word: String).returns(String) }
  def underscore(camel_cased_word)
    return camel_cased_word unless /[A-Z-]|::/.match?(camel_cased_word)
    word = camel_cased_word.to_s.gsub("::", "/")
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
    word.tr!("-", "_")
    word.downcase!
    word
  end

  sig { params(str: String, indent: Integer).returns(String) }
  def indented(str, indent)
    str.lines.map! do |line|
      next line if line.chomp.empty?
      " " * indent + line
    end.join
  end

  sig { returns(T::Array[String]) }
  def gathered_constants
    T.unsafe(self).subject.processable_constants.map(&:to_s).sort
  end

  sig do
    params(
      constant_name: T.any(Symbol, String)
    ).returns(String)
  end
  def rbi_for(constant_name)
    parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
    T.unsafe(self).subject.decorate(parlour.root, Object.const_get(constant_name))
    parlour.rbi
  end
end
