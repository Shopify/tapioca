# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class CheckShimsTest < SpecWithProject
    describe "cli::check-shims" do
      after do
        @project.remove!("sorbet/rbi")
      end

      before(:all) do
        @project.require_default_gems
        @project.bundle_install!
      end

      it "does nothing when there is no shims to check" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write!("sorbet/rbi/dsl/foo.rbi", <<~RBI)
          class Foo
            attr_reader :bar
          end
        RBI

        result = @project.tapioca("check-shims --no-payload")

        assert_stdout_equals(<<~OUT, result)
          No shim RBIs to check
        OUT

        assert_success_status(result)
      end

      it "does nothing when there is no duplicates" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo

            class Baz; end
          end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            attr_reader :bar

            class Baz
              def baz; end
            end
          end
        RBI

        result = @project.tapioca("check-shims --no-payload")

        assert_equal(<<~OUT, strip_timer(result.out))
          Loading shim RBIs from sorbet/rbi/shims...  Done
          Loading gem RBIs from sorbet/rbi/gems...  Done
          Looking for duplicates...  Done

          No duplicates found in shim RBIs
        OUT

        assert_success_status(result)
      end

      it "detects duplicated definitions between shim and generated RBIs" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write!("sorbet/rbi/dsl/bar.rbi", <<~RBI)
          module Bar
            def bar; end
          end
        RBI

        @project.write!("sorbet/rbi/dsl/baz.rbi", <<~RBI)
          module Baz; end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write!("sorbet/rbi/shims/bar.rbi", <<~RBI)
          module Bar
            def bar; end
          end
        RBI

        @project.write!("sorbet/rbi/shims/baz.rbi", <<~RBI)
          module Baz
            def baz; end
          end
        RBI

        result = @project.tapioca("check-shims --no-payload")

        assert_stderr_equals(<<~ERR, result)

          Duplicated RBI for ::Bar#bar:
           * sorbet/rbi/shims/bar.rbi:2:2-2:14
           * sorbet/rbi/dsl/bar.rbi:2:2-2:14

          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/shims/foo.rbi:2:2-2:18
           * sorbet/rbi/gems/foo@1.0.0.rbi:2:2-2:18

          Please remove the duplicated definitions from sorbet/rbi/shims and sorbet/rbi/todo.rbi
        ERR

        refute_success_status(result)
      end

      it "ignores duplicates that have a signature" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            def foo; end
          end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            sig { void }
            def foo; end
          end
        RBI

        result = @project.tapioca("check-shims --no-payload")
        assert_success_status(result)
      end

      it "ignores duplicates that have a different signature" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            sig { void }
            def foo; end
          end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            sig { returns(Integer) }
            def foo; end
          end
        RBI

        result = @project.tapioca("check-shims --no-payload")
        assert_success_status(result)
      end

      it "detects duplicates that have the same signature" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            sig { params(x: Integer, y: String).returns(String) }
            def foo(x, y); end

            sig { params(x: Integer, y: Integer).returns(String) }
            def bar(x, y); end

            sig { params(x: Integer, y: Integer).returns(Integer) }
            def baz(x, y); end
          end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            sig { params(x: Integer, y: String).returns(String) }
            def foo(x, y); end

            sig { params(x: String, y: Integer).returns(String) }
            def bar(x, y); end

            sig { params(x: Integer, y: Integer).returns(String) }
            def baz(x, y); end
          end
        RBI

        result = @project.tapioca("check-shims --no-payload")

        assert_stderr_equals(<<~ERR, result)

          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/shims/foo.rbi:3:2-3:20
           * sorbet/rbi/gems/foo@1.0.0.rbi:3:2-3:20

          Please remove the duplicated definitions from sorbet/rbi/shims and sorbet/rbi/todo.rbi
        ERR

        refute_includes(result.err, "Duplicated RBI for ::Foo#bar")
        refute_includes(result.err, "Duplicated RBI for ::Foo#baz")

        refute_success_status(result)
      end

      it "detects duplicates from nodes with multiple definitions" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            attr_reader :foo, :bar
          end
        RBI

        result = @project.tapioca("check-shims --no-payload")

        assert_stderr_equals(<<~ERR, result)

          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/shims/foo.rbi:2:2-2:24
           * sorbet/rbi/gems/foo@1.0.0.rbi:2:2-2:18

          Please remove the duplicated definitions from sorbet/rbi/shims and sorbet/rbi/todo.rbi
        ERR

        refute_success_status(result)
      end

      it "detects duplicated includes and extends" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          module Bar; end

          class Foo
            include Bar
            extend Bar
            mixes_in_class_methods Bar
            requires_ancestor { Bar }
          end

          module Baz; end

          class Qux
            # RBI does not attempt to resolve constants used in the mixins, so if the constant duplicated in the shim
            # does not use the same namespace, Tapioca won't catch it. The following lines won't raise duplication
            # errors.
            include Baz
            extend Baz
            mixes_in_class_methods Baz
            requires_ancestor { Baz }
          end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            include Bar
            extend Bar
            mixes_in_class_methods Bar
            requires_ancestor { Bar }
          end

          class Qux
            include ::Baz
            extend ::Baz
            mixes_in_class_methods ::Baz
            requires_ancestor { ::Baz }
          end
        RBI

        result = @project.tapioca("check-shims --no-payload")

        assert_stderr_equals(<<~ERR, result)

          Duplicated RBI for ::Foo.include(Bar):
           * sorbet/rbi/shims/foo.rbi:2:2-2:13
           * sorbet/rbi/gems/foo@1.0.0.rbi:4:2-4:13

          Duplicated RBI for ::Foo.extend(Bar):
           * sorbet/rbi/shims/foo.rbi:3:2-3:12
           * sorbet/rbi/gems/foo@1.0.0.rbi:5:2-5:12

          Duplicated RBI for ::Foo.mixes_in_class_method(Bar):
           * sorbet/rbi/shims/foo.rbi:4:2-4:28
           * sorbet/rbi/gems/foo@1.0.0.rbi:6:2-6:28

          Duplicated RBI for ::Foo.requires_ancestor(Bar):
           * sorbet/rbi/shims/foo.rbi:5:2-5:27
           * sorbet/rbi/gems/foo@1.0.0.rbi:7:2-7:27

          Please remove the duplicated definitions from sorbet/rbi/shims and sorbet/rbi/todo.rbi
        ERR

        refute_success_status(result)
      end

      it "ignores duplicates that have a parent class" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
          end
          class Bar < Foo
          end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo < Baz
          end
          class Bar < Baz
          end
        RBI

        result = @project.tapioca("check-shims --no-payload")
        assert_success_status(result)
      end

      it "detects duplicates that have a parent class" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
          end
          class Bar < Foo
          end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
          end
          class Bar < Foo
          end
        RBI

        result = @project.tapioca("check-shims --no-payload")

        assert_stderr_equals(<<~ERR, result)

          Duplicated RBI for ::Foo:
           * sorbet/rbi/shims/foo.rbi:1:0-2:3
           * sorbet/rbi/gems/foo@1.0.0.rbi:1:0-2:3

          Duplicated RBI for ::Bar:
           * sorbet/rbi/shims/foo.rbi:3:0-4:3
           * sorbet/rbi/gems/foo@1.0.0.rbi:3:0-4:3

          Please remove the duplicated definitions from sorbet/rbi/shims and sorbet/rbi/todo.rbi
        ERR

        refute_success_status(result)
      end

      it "detects duplicates from same shim file" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo

            class Baz; end
          end

          class Bar; end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            attr_reader :foo, :bar
            def foo; end

            class Baz; end
          end

          class Bar; end
          class Bar; end
        RBI

        result = @project.tapioca("check-shims --no-payload")

        assert_stderr_equals(<<~ERR, result)

          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/shims/foo.rbi:2:2-2:24
           * sorbet/rbi/shims/foo.rbi:3:2-3:14
           * sorbet/rbi/gems/foo@1.0.0.rbi:2:2-2:18

          Duplicated RBI for ::Foo::Baz:
           * sorbet/rbi/shims/foo.rbi:5:2-5:16
           * sorbet/rbi/gems/foo@1.0.0.rbi:4:2-4:16

          Duplicated RBI for ::Bar:
           * sorbet/rbi/shims/foo.rbi:8:0-8:14
           * sorbet/rbi/shims/foo.rbi:9:0-9:14
           * sorbet/rbi/gems/foo@1.0.0.rbi:7:0-7:14

          Please remove the duplicated definitions from sorbet/rbi/shims and sorbet/rbi/todo.rbi
        ERR

        refute_success_status(result)
      end

      it "detects duplicates from Sorbet's payload" do
        @project.write!("sorbet/rbi/shims/core/object.rbi", <<~RBI)
          class Object; end
        RBI

        @project.write!("sorbet/rbi/shims/core/string.rbi", <<~RBI)
          class String
            sig { returns(String) }
            def capitalize(); end

            def some_method_that_is_not_defined_in_the_payload; end
          end
        RBI

        @project.write!("sorbet/rbi/shims/stdlib/base64.rbi", <<~RBI)
          module Base64
            sig { params(str: String).returns(String) }
            def self.decode64(str); end

            def self.some_method_that_is_not_defined_in_the_payload; end
          end
        RBI

        result = @project.tapioca("check-shims")

        assert_equal(<<~OUT, strip_timer(result.out))
          Loading Sorbet payload...  Done
          Loading shim RBIs from sorbet/rbi/shims...  Done
          Looking for duplicates...  Done
        OUT

        assert_stderr_equals(<<~ERR, result)

          Duplicated RBI for ::Object:
           * https://github.com/sorbet/sorbet/tree/master/rbi/core/object.rbi#L27
           * https://github.com/sorbet/sorbet/tree/master/rbi/stdlib/json.rbi#L1060
           * sorbet/rbi/shims/core/object.rbi:1:0-1:17

          Duplicated RBI for ::String#capitalize:
           * https://github.com/sorbet/sorbet/tree/master/rbi/core/string.rbi#L572
           * sorbet/rbi/shims/core/string.rbi:3:2-3:23

          Duplicated RBI for ::Base64::decode64:
           * https://github.com/sorbet/sorbet/tree/master/rbi/stdlib/base64.rbi#L37
           * sorbet/rbi/shims/stdlib/base64.rbi:3:2-3:29

          Please remove the duplicated definitions from sorbet/rbi/shims and sorbet/rbi/todo.rbi
        ERR

        refute_success_status(result)
      end

      it "checks shims with custom rbi dirs" do
        @project.write!("rbi/gem/foo@1.0.0.rbi", <<~RBI)
          class Foo
            def foo; end
          end
        RBI

        @project.write!("rbi/dsl/foo.rbi", <<~RBI)
          class Foo
            def bar; end
          end
        RBI

        @project.write!("rbi/shim/foo.rbi", <<~RBI)
          class Foo
            def foo; end
            def bar; end
          end

          module Baz
            def baz; end
          end
        RBI

        @project.write!("rbi/todo.rbi", <<~RBI)
          module Baz
            def baz; end
          end
        RBI

        result = @project.tapioca(
          "check-shims --gem-rbi-dir=rbi/gem --dsl-rbi-dir=rbi/dsl --shim-rbi-dir=rbi/shim " \
            "--todo-rbi-file=rbi/todo.rbi --no-payload",
        )

        assert_stderr_equals(<<~ERR, result)

          Duplicated RBI for ::Baz#baz:
           * rbi/todo.rbi:2:2-2:14
           * rbi/shim/foo.rbi:7:2-7:14

          Duplicated RBI for ::Foo#foo:
           * rbi/shim/foo.rbi:2:2-2:14
           * rbi/gem/foo@1.0.0.rbi:2:2-2:14

          Duplicated RBI for ::Foo#bar:
           * rbi/shim/foo.rbi:3:2-3:14
           * rbi/dsl/foo.rbi:2:2-2:14

          Please remove the duplicated definitions from rbi/shim and rbi/todo.rbi
        ERR

        refute_success_status(result)
      end

      it "skips files with parse errors" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
        RBI

        @project.write!("sorbet/rbi/shims/bar.rbi", <<~RBI)
          module Foo
            def foo; end
          end
        RBI

        result = @project.tapioca("check-shims --no-payload")

        assert_stderr_equals(<<~ERR, result)

          Warning: unexpected end-of-input, assuming it is closing the parent top level context. expected an `end` to close the `class` statement. (sorbet/rbi/shims/foo.rbi:2:0)

          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/shims/bar.rbi:2:2-2:14
           * sorbet/rbi/gems/foo@1.0.0.rbi:2:2-2:18

          Please remove the duplicated definitions from sorbet/rbi/shims and sorbet/rbi/todo.rbi
        ERR

        refute_success_status(result)
      end

      it "detects duplicated definitions between shim and annotations" do
        @project.write!("sorbet/rbi/annotations/foo.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write!("sorbet/rbi/annotations/bar.rbi", <<~RBI)
          module Bar
            def bar; end
          end
        RBI

        @project.write!("sorbet/rbi/annotations/baz.rbi", <<~RBI)
          module Baz; end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write!("sorbet/rbi/shims/bar.rbi", <<~RBI)
          module Bar
            def bar; end
          end
        RBI

        @project.write!("sorbet/rbi/shims/baz.rbi", <<~RBI)
          module Baz; end
        RBI

        result = @project.tapioca("check-shims --no-payload")

        assert_stderr_equals(<<~ERR, result)

          Duplicated RBI for ::Bar#bar:
           * sorbet/rbi/shims/bar.rbi:2:2-2:14
           * sorbet/rbi/annotations/bar.rbi:2:2-2:14

          Duplicated RBI for ::Baz:
           * sorbet/rbi/shims/baz.rbi:1:0-1:15
           * sorbet/rbi/annotations/baz.rbi:1:0-1:15

          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/shims/foo.rbi:2:2-2:18
           * sorbet/rbi/annotations/foo.rbi:2:2-2:18

          Please remove the duplicated definitions from sorbet/rbi/shims and sorbet/rbi/todo.rbi
        ERR

        refute_success_status(result)
      end

      it "detects duplicated definitions between the TODO file and generated RBIs" do
        @project.write!("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo

            class Baz; end
          end
        RBI

        @project.write!("sorbet/rbi/dsl/bar.rbi", <<~RBI)
          module Bar
            def bar; end
          end
        RBI

        @project.write!("sorbet/rbi/todo.rbi", <<~RBI)
          class Foo
            attr_reader :foo

            class Baz; end
          end

          module Bar
            def bar; end
          end
        RBI

        result = @project.tapioca("check-shims --no-payload")

        assert_stderr_equals(<<~ERR, result)

          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/todo.rbi:2:2-2:18
           * sorbet/rbi/gems/foo@1.0.0.rbi:2:2-2:18

          Duplicated RBI for ::Foo::Baz:
           * sorbet/rbi/todo.rbi:4:2-4:16
           * sorbet/rbi/gems/foo@1.0.0.rbi:4:2-4:16

          Duplicated RBI for ::Bar#bar:
           * sorbet/rbi/todo.rbi:8:2-8:14
           * sorbet/rbi/dsl/bar.rbi:2:2-2:14

          Please remove the duplicated definitions from sorbet/rbi/shims and sorbet/rbi/todo.rbi
        ERR

        refute_success_status(result)
      end

      it "detects duplicated definitions between the TODO file and shims" do
        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write!("sorbet/rbi/shims/bar.rbi", <<~RBI)
          module Bar
            def bar; end
          end
        RBI

        @project.write!("sorbet/rbi/shims/baz.rbi", <<~RBI)
          module Baz; end
        RBI

        @project.write!("sorbet/rbi/todo.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end

          module Bar
            def bar; end
          end

          module Baz; end
        RBI

        result = @project.tapioca("check-shims --no-payload")

        assert_stderr_equals(<<~ERR, result)

          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/todo.rbi:2:2-2:18
           * sorbet/rbi/shims/foo.rbi:2:2-2:18

          Duplicated RBI for ::Bar#bar:
           * sorbet/rbi/todo.rbi:6:2-6:14
           * sorbet/rbi/shims/bar.rbi:2:2-2:14

          Duplicated RBI for ::Baz:
           * sorbet/rbi/todo.rbi:9:0-9:15
           * sorbet/rbi/shims/baz.rbi:1:0-1:15

          Please remove the duplicated definitions from sorbet/rbi/shims and sorbet/rbi/todo.rbi
        ERR

        refute_success_status(result)
      end

      it "ignores files typed: ignore" do
        @project.write!("sorbet/rbi/annotations/foo.rbi", <<~RBI)
          # typed: ignore

          class Foo; end
        RBI

        @project.write!("sorbet/rbi/gems/foo.rbi", <<~RBI)
          # typed: ignore

          class Foo; end
        RBI

        @project.write!("sorbet/rbi/shims/foo.rbi", <<~RBI)
          # typed: ignore

          class Foo; end
        RBI

        @project.write!("sorbet/rbi/todo.rbi", <<~RBI)
          # typed: ignore

          class Foo; end
        RBI

        result = @project.tapioca("check-shims --no-payload")
        assert_success_status(result)
      end

      sig { params(string: String).returns(String) }
      def strip_timer(string)
        string.gsub(/ \(\d+\.\d+s\)/, "")
      end
    end
  end
end
