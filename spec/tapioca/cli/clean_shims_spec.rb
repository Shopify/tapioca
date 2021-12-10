# typed: true
# frozen_string_literal: true

require "spec_with_project"

module Tapioca
  class CleanShimsTest < SpecWithProject
    describe "tapioca clean-shims" do
      before(:all) do
        @project.bundle_install
      end

      after do
        @project.remove("sorbet/rbi")
      end

      it "does nothing when there is no duplicate to clean" do
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

        out, _, status = @project.tapioca("clean-shims")

        assert_equal(<<~OUT, out)
          Loading gem RBIs from sorbet/rbi/gems...  Done
          Loading dsl RBIs from sorbet/rbi/dsl...  Done
          Cleaning shim RBIs from sorbet/rbi/shims... Done (nothing to do)
        OUT

        assert(status)

        assert_project_file_equal("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            attr_reader :bar
          end
        RBI
      end

      it "cleans unecessary shims" do
        @project.write("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            attr_reader :foo
          end
        RBI

        @project.write("sorbet/rbi/gems/bar@2.0.0.rbi", <<~RBI)
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
            def foo; end
            def bar; end
          end
        RBI

        @project.write("sorbet/rbi/shims/baz.rbi", <<~RBI)
          BAZ = 42
        RBI

        out, _, status = @project.tapioca("clean-shims")

        assert_equal(<<~OUT, out)
          Loading gem RBIs from sorbet/rbi/gems...  Done
          Loading dsl RBIs from sorbet/rbi/dsl...  Done
          Cleaning shim RBIs from sorbet/rbi/shims...
            Deleted ::Bar#bar() at sorbet/rbi/shims/bar.rbi:3:2-3:14 (duplicate from sorbet/rbi/gems/bar@2.0.0.rbi:2:2-2:14)
            Deleted ::Foo.attr_reader(:foo) at sorbet/rbi/shims/foo.rbi:2:2-2:18 (duplicate from sorbet/rbi/gems/foo@1.0.0.rbi:2:2-2:18)
            Deleted ::Foo at sorbet/rbi/shims/foo.rbi:1:0-3:3 (duplicate from sorbet/rbi/gems/foo@1.0.0.rbi:1:0-3:3)
            Deleted empty file sorbet/rbi/shims/foo.rbi
          Done
        OUT

        assert(status)

        refute_project_file_exist("sorbet/rbi/shims/foo.rbi")

        assert_project_file_equal("sorbet/rbi/shims/bar.rbi", <<~RBI)
          module Bar
            def foo; end
          end
        RBI

        assert_project_file_equal("sorbet/rbi/shims/baz.rbi", <<~RBI)
          BAZ = 42
        RBI
      end

      it "preserves missing sigs" do
        @project.write("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            def foo; end
            def bar; end
          end
        RBI

        @project.write("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            sig { void }
            def foo; end

            def bar; end
          end
        RBI

        out, _, status = @project.tapioca("clean-shims")

        assert_equal(<<~OUT, out)
          Loading gem RBIs from sorbet/rbi/gems...  Done
          Loading dsl RBIs from sorbet/rbi/dsl...  Done
          Cleaning shim RBIs from sorbet/rbi/shims...
            Deleted ::Foo#bar() at sorbet/rbi/shims/foo.rbi:5:2-5:14 (duplicate from sorbet/rbi/gems/foo@1.0.0.rbi:3:2-3:14)
          Done
        OUT

        assert(status)

        assert_project_file_equal("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            sig { void }
            def foo; end
          end
        RBI
      end

      it "preserves nodes with multiple definitions" do
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

        out, _, status = @project.tapioca("clean-shims")

        assert_equal(<<~OUT, out)
          Loading gem RBIs from sorbet/rbi/gems...  Done
          Loading dsl RBIs from sorbet/rbi/dsl...  Done
          Cleaning shim RBIs from sorbet/rbi/shims... Done (nothing to do)
        OUT

        assert(status)

        assert_project_file_equal("sorbet/rbi/shims/foo.rbi", <<~RBI)
          class Foo
            attr_reader :foo, :bar
          end
        RBI
      end

      it "cleans shims with custom rbi dirs" do
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

        out, _, status = @project.tapioca(
          "clean-shims --gem-rbi-dir=rbi/gem --dsl-rbi-dir=rbi/dsl --shim-rbi-dir=rbi/shim"
        )

        assert_equal(<<~OUT, out)
          Loading gem RBIs from rbi/gem...  Done
          Loading dsl RBIs from rbi/dsl...  Done
          Cleaning shim RBIs from rbi/shim...
            Deleted ::Foo#foo() at rbi/shim/foo.rbi:2:2-2:14 (duplicate from rbi/gem/foo@1.0.0.rbi:2:2-2:14)
            Deleted ::Foo#bar() at rbi/shim/foo.rbi:3:2-3:14 (duplicate from rbi/dsl/foo.rbi:2:2-2:14)
            Deleted ::Foo at rbi/shim/foo.rbi:1:0-4:3 (duplicate from rbi/gem/foo@1.0.0.rbi:1:0-3:3)
            Deleted empty file rbi/shim/foo.rbi
          Done
        OUT

        assert(status)
        refute_project_file_exist("custom/shims/foo.rbi")
        @project.remove("rbi")
      end

      it "cleans only specified shims" do
        @project.write("sorbet/rbi/gems/foo@1.0.0.rbi", <<~RBI)
          class Foo
            def foo; end
            def bar; end
            def baz; end
          end
        RBI

        @project.write("sorbet/rbi/shims/a.rbi", <<~RBI)
          class Foo
            def foo; end
          end
        RBI

        @project.write("sorbet/rbi/shims/b.rbi", <<~RBI)
          class Foo
            def bar; end
          end
        RBI

        @project.write("sorbet/rbi/shims/c.rbi", <<~RBI)
          class Foo
            def baz; end
          end
        RBI

        out, _, status = @project.tapioca("clean-shims sorbet/rbi/shims/a.rbi sorbet/rbi/shims/b.rbi")

        assert_equal(<<~OUT, out)
          Loading gem RBIs from sorbet/rbi/gems...  Done
          Loading dsl RBIs from sorbet/rbi/dsl...  Done
          Cleaning shim RBIs...
            Deleted ::Foo#foo() at sorbet/rbi/shims/a.rbi:2:2-2:14 (duplicate from sorbet/rbi/gems/foo@1.0.0.rbi:2:2-2:14)
            Deleted ::Foo at sorbet/rbi/shims/a.rbi:1:0-3:3 (duplicate from sorbet/rbi/gems/foo@1.0.0.rbi:1:0-5:3)
            Deleted empty file sorbet/rbi/shims/a.rbi
            Deleted ::Foo#bar() at sorbet/rbi/shims/b.rbi:2:2-2:14 (duplicate from sorbet/rbi/gems/foo@1.0.0.rbi:3:2-3:14)
            Deleted ::Foo at sorbet/rbi/shims/b.rbi:1:0-3:3 (duplicate from sorbet/rbi/gems/foo@1.0.0.rbi:1:0-5:3)
            Deleted empty file sorbet/rbi/shims/b.rbi
          Done
        OUT

        assert(status)
        refute_project_file_exist("sorbet/rbi/shims/a.rbi")
        refute_project_file_exist("sorbet/rbi/shims/b.rbi")

        assert_project_file_equal("sorbet/rbi/shims/c.rbi", <<~RBI)
          class Foo
            def baz; end
          end
        RBI
      end
    end
  end
end
