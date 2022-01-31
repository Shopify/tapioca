# typed: true
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  class CleanShimsTest < SpecWithProject
    describe "cli::clean-shims" do
      before(:all) do
        @project.bundle_install
      end

      after do
        @project.remove("sorbet/rbi")
      end

      it "does nothing when there is no shims to check" do
        @project.write("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write("sorbet/rbi/dsl/foo.rbi", <<~RBI)
          class Foo
            attr_reader :bar
          end
        RBI

        result = @project.tapioca("check-shims")

        assert_equal(<<~OUT, result.out)
          No shim RBIs to check
        OUT

        assert_success_status(result)
      end

      it "does nothing when there is no duplicates" do
        @project.write("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            attr_reader :bar
          end
        RBI

        result = @project.tapioca("check-shims")

        assert_equal(<<~OUT, result.out)
          Loading shim RBIs from sorbet/rbi/shims...  Done
          Loading gem RBIs from sorbet/rbi/gems...  Done
          Looking for duplicates...  Done

          No duplicates found in shim RBIs
        OUT

        assert_success_status(result)
      end

      it "detects duplicated definitions between shim and generated RBIs" do
        @project.write("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write("sorbet/rbi/dsl/bar.rbi", <<~RBI)
          module Bar
            def bar; end
          end
        RBI

        @project.write("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write("sorbet/rbi/shims/bar.rbi", <<~RBI)
          module Bar
            def bar; end
          end
        RBI

        result = @project.tapioca("check-shims")

        assert_includes(result.err, <<~ERR)
          Duplicated RBI for ::Bar#bar:
           * sorbet/rbi/shims/bar.rbi:2:2-2:14
           * sorbet/rbi/dsl/bar.rbi:2:2-2:14
        ERR

        assert_includes(result.err, <<~ERR)
          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/shims/foo.rbi:2:2-2:18
           * sorbet/rbi/gems/foo@1.0.0.rbi:2:2-2:18
        ERR

        assert_includes(result.err, <<~ERR)
          Please remove the duplicated definitions from the sorbet/rbi/shims directory.
        ERR

        refute_success_status(result)
      end

      it "ignores duplicates that have a signature" do
        @project.write("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            def foo; end
          end
        RBI

        @project.write("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            sig { void }
            def foo; end
          end
        RBI

        result = @project.tapioca("check-shims")
        assert_success_status(result)
      end

      it "ignores duplicates that have a different signature" do
        @project.write("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            sig { void }
            def foo; end
          end
        RBI

        @project.write("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            sig { returns(Integer) }
            def foo; end
          end
        RBI

        result = @project.tapioca("check-shims")
        assert_success_status(result)
      end

      it "detects duplicates that have the same signature" do
        @project.write("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            sig { params(x: Integer, y: String).returns(String) }
            def foo(x, y); end

            sig { params(x: Integer, y: Integer).returns(String) }
            def bar(x, y); end

            sig { params(x: Integer, y: Integer).returns(Integer) }
            def baz(x, y); end
          end
        RBI

        @project.write("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            sig { params(x: Integer, y: String).returns(String) }
            def foo(x, y); end

            sig { params(x: String, y: Integer).returns(String) }
            def bar(x, y); end

            sig { params(x: Integer, y: Integer).returns(String) }
            def baz(x, y); end
          end
        RBI

        result = @project.tapioca("check-shims")

        assert_includes(result.err, <<~ERR)
          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/shims/foo.rbi:3:2-3:20
           * sorbet/rbi/gems/foo@1.0.0.rbi:3:2-3:20
        ERR

        assert_includes(result.err, <<~ERR)
          Please remove the duplicated definitions from the sorbet/rbi/shims directory.
        ERR

        refute_includes(result.err, "Duplicated RBI for ::Foo#bar")
        refute_includes(result.err, "Duplicated RBI for ::Foo#baz")

        refute_success_status(result)
      end

      it "detects duplicates from nodes with multiple definitions" do
        @project.write("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            attr_reader :foo, :bar
          end
        RBI

        result = @project.tapioca("check-shims")

        assert_includes(result.err, <<~ERR)
          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/shims/foo.rbi:2:2-2:24
           * sorbet/rbi/gems/foo@1.0.0.rbi:2:2-2:18
        ERR

        assert_includes(result.err, <<~ERR)
          Please remove the duplicated definitions from the sorbet/rbi/shims directory.
        ERR

        refute_success_status(result)
      end

      it "detects duplicates from the same shim file" do
        @project.write("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            attr_reader :foo, :bar
            def foo; end
          end
        RBI

        result = @project.tapioca("check-shims")

        assert_includes(result.err, <<~ERR)
          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/shims/foo.rbi:2:2-2:24
           * sorbet/rbi/shims/foo.rbi:3:2-3:14
           * sorbet/rbi/gems/foo@1.0.0.rbi:2:2-2:18
        ERR

        assert_includes(result.err, <<~ERR)
          Please remove the duplicated definitions from the sorbet/rbi/shims directory.
        ERR

        refute_success_status(result)
      end

      it "checks shims with custom rbi dirs" do
        @project.write("rbi/gem/foo@1.0.0.rbi", <<~RBI)
          class Foo
            def foo; end
          end
        RBI

        @project.write("rbi/dsl/foo.rbi", <<~RBI)
          class Foo
            def bar; end
          end
        RBI

        @project.write("rbi/shim/foo.rbi", <<~RBI)
          class Foo
            def foo; end
            def bar; end
          end
        RBI

        result = @project.tapioca(
          "check-shims --gem-rbi-dir=rbi/gem --dsl-rbi-dir=rbi/dsl --shim-rbi-dir=rbi/shim"
        )

        assert_includes(result.err, <<~ERR)
          Duplicated RBI for ::Foo#bar:
           * rbi/shim/foo.rbi:3:2-3:14
           * rbi/dsl/foo.rbi:2:2-2:14
        ERR

        assert_includes(result.err, <<~ERR)
          Duplicated RBI for ::Foo#foo:
           * rbi/shim/foo.rbi:2:2-2:14
           * rbi/gem/foo@1.0.0.rbi:2:2-2:14
        ERR

        assert_includes(result.err, <<~ERR)
          Please remove the duplicated definitions from the rbi/shim directory.
        ERR

        refute_success_status(result)
      end

      it "skips files with parse errors" do
        @project.write("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            foo { bar }
          end
        RBI

        @project.write("sorbet/rbi/shims/bar.rbi", <<~RBI)
          module Foo
            def foo; end
          end
        RBI

        result = @project.tapioca("check-shims")

        assert_includes(result.err, <<~ERR)
          Warning: Unsupported block node type `foo` (sorbet/rbi/shims/foo.rbi:2:2-2:13)
        ERR

        assert_includes(result.err, <<~ERR)
          Duplicated RBI for ::Foo#foo:
           * sorbet/rbi/shims/bar.rbi:2:2-2:14
           * sorbet/rbi/gems/foo@1.0.0.rbi:2:2-2:18
        ERR

        assert_includes(result.err, <<~ERR)
          Please remove the duplicated definitions from the sorbet/rbi/shims directory.
        ERR

        refute_success_status(result)
      end
    end
  end
end
