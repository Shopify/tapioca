# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/spec"
require "content_helper"
require "template_helper"
require "isolation_helper"
require "tapioca/core_ext/string"

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
    T.must(spec_test_class.name).gsub(/Spec$/, "")
  end

  sig { returns(String) }
  def target_class_file
    target_class_name.underscore
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
    T.unsafe(self).subject.processable_constants.map(&:name).sort
  end

  sig do
    params(
      constant_name: T.any(Symbol, String)
    ).returns(String)
  end
  def rbi_for(constant_name)
    # Sometimes gather_constants registers temp constants, so
    # let's call it once to ensure all constants are in place.
    T.unsafe(self).subject.processable_constants

    file = Tapioca::RBI::File.new(strictness: "strong")

    constant = Object.const_get(constant_name)
    T.unsafe(self).subject.decorate(file.root, constant)

    file.root.nest_non_public_methods!
    file.root.group_nodes!
    file.root.sort_nodes!
    file.string
  end
end
