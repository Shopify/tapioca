# typed: strict
# frozen_string_literal: true

require "spec_helper"

class Tapioca::RBIHelperSpec < Minitest::Spec
  include Tapioca::RBIHelper

  describe Tapioca::RBIHelper do
    specify "as_non_nilable_type removes T.nilable() and ::T.nilable() if it's the outermost part of the string" do
      T.bind(self, T.untyped)

      assert_equal(as_non_nilable_type("T.nilable(String)"), "String")
      assert_equal(as_non_nilable_type("::T.nilable(String)"), "String")
      assert_equal(as_non_nilable_type("String"), "String")
      assert_equal(as_non_nilable_type("T.any(T.nilable(String), Integer)"), "T.any(T.nilable(String), Integer)")
    end

    it "accepts valid method names" do
      [
        "f",
        "foo",
        "_foo",
        "foo_",
        "fOO",
        "f00",
        "foo!",
        "foo=",
        "foo?",
        "Foo",
        "éxéctôr",
        "❨╯°□°❩╯︵┻━┻",
        "!",
        "~",
        "+@",
        "**",
        "-@",
        "*",
        "/",
        "%",
        "+",
        "-",
        "<<",
        ">>",
        "&",
        "|",
        "^",
        "<",
        "<=",
        ">",
        ">=",
        "==",
        "===",
        "!=",
        "=~",
        "!~",
        "<=>",
        "[]",
        "[]=",
        "`",
      ].each do |name|
        assert(valid_method_name?(name), "Expected `#{name}` to be a valid method name")
      end
    end

    it "rejects invalid method names" do
      ["", "42", "42foo", "42foo=", "!foo", "-@foo", "foo-", "foo-bar", "foo.bar", "=>"].each do |name|
        refute(valid_method_name?(name), "Expected `#{name}` to be an invalid method name")
      end
    end

    it "accepts valid parameter names" do
      ["f", "foo", "_foo", "foo_", "fOO", "f00", "éxéctôr", "❨╯°□°❩╯︵┻━┻"].each do |name|
        assert(valid_parameter_name?(name), "Expected `#{name}` to be a valid parameter name")
      end
    end

    it "rejects invalid parameter names" do
      [
        "",
        "42",
        "42foo",
        "foo!",
        "foo=",
        "foo?",
        "Foo",
        "!foo",
        "-@foo",
        "foo-",
        "foo-bar",
        "foo.bar",
        "!",
        "~",
        "+@",
        "**",
        "-@",
        "*",
        "/",
        "%",
        "+",
        "-",
        "<<",
        ">>",
        "&",
        "|",
        "^",
        "<",
        "<=",
        "=>",
        ">",
        ">=",
        "==",
        "===",
        "!=",
        "=~",
        "!~",
        "<=>",
        "[]",
        "[]=",
        "`",
      ].each do |name|
        refute(valid_parameter_name?(name), "Expected `#{name}` to be an invalid parameter name")
      end
    end
  end
end
