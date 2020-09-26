# typed: strict
# frozen_string_literal: true

require "tapioca"
require "minitest/autorun"
require "minitest/spec"
require "minitest/hooks/default"
require "minitest/fork_executor"
require "minitest/reporters"

require "content_helper"
require "template_helper"

Minitest::Reporters.use!(Minitest::Reporters::DefaultReporter.new(color: true))
Minitest.parallel_executor = Minitest::ForkExecutor.new

module Minitest
  class Test
    extend T::Sig
    include ContentHelper
    include TemplateHelper

    Minitest::Test.make_my_diffs_pretty!
  end
end

class DslSpec < Minitest::Spec
  before(:all) do
    extra_require = T.unsafe(self).target_class.instance_variable_get(:@require_before)
    extra_require.call if extra_require
    Kernel.require(T.unsafe(self).underscore(T.unsafe(self).target_class_name))
  end

  subject do
    class_name = T.unsafe(self).target_class_name
    Object.const_get(class_name).new # rubocop:disable Sorbet/ConstantsFromStrings
  end

  sig { params(blk: T.proc.void).void }
  def self.require_before(&blk)
    @require_before = blk
  end
  @require_before = T.let(nil, T.nilable(T.proc.void))

  sig { returns(Class) }
  def target_class
    klass = T.unsafe(self).class
    while klass.superclass != DslSpec
      klass = klass.superclass
    end
    klass
  end

  sig { returns(String) }
  def target_class_name
    T.must(target_class.name).gsub(/Spec$/, '')
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

  sig do
    params(
      content: String
    ).void
  end
  def constants_from(content)
    with_contents({ "file.rb" => content }) do
      T.unsafe(self).subject.processable_constants.map(&:to_s).sort
    end
  end

  sig do
    params(
      constant_name: T.any(Symbol, String),
      contents: T.any(String, T::Hash[String, String])
    ).returns(String)
  end
  def rbi_for(constant_name, contents)
    contents = { "file.rb" => contents } if String === contents

    with_contents(contents) do
      parlour = Parlour::RbiGenerator.new(sort_namespaces: true)
      T.unsafe(self).subject.decorate(parlour.root, Object.const_get(constant_name))
      parlour.rbi
    end
  end
end
