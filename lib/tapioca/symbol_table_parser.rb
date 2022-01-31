# typed: strict
# frozen_string_literal: true

require "json"
require "tempfile"

module Tapioca
  class SymbolTableParser
    extend T::Sig

    sig { params(json_string: String).returns(T::Set[String]) }
    def self.parse_json(json_string)
      obj = JSON.parse(json_string)

      parser = SymbolTableParser.new
      parser.parse_object(obj)
      parser.symbols
    end

    sig { returns(T::Set[String]) }
    attr_reader :symbols

    sig { void }
    def initialize
      @symbols = T.let(Set.new, T::Set[String])
      @parents = T.let([], T::Array[String])
    end

    sig { params(object: T::Hash[String, T.untyped]).void }
    def parse_object(object)
      children = object.fetch("children", [])

      children.each do |child|
        kind = child.fetch("kind")
        name = child.fetch("name")
        name = name.fetch("name") if name.is_a?(Hash)

        next if kind.nil? || name.nil?

        # TODO: CLASS is removed since v0.4.4730 of Sorbet
        # but keeping here for backward compatibility. Remove
        # once the minimum version is moved past that.
        next unless ["CLASS", "CLASS_OR_MODULE", "STATIC_FIELD"].include?(kind)
        next if name =~ /[<>()$]/
        next if name =~ /^[0-9]+$/
        next if name == "T::Helpers"

        @symbols.add(fully_qualified_name(name))

        @parents << name
        parse_object(child)
        @parents.pop
      end
    end

    sig { params(name: String).returns(String) }
    def fully_qualified_name(name)
      [*@parents, name].join("::")
    end
  end
end
