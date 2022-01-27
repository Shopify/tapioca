# typed: strict
# frozen_string_literal: true

require "spec_with_project"
require "tapioca/internal"

module Tapioca
  class GemfileSpec < SpecWithProject
    extend T::Sig

    describe("gem can export RBI files") do
      it "export_rbi_files? returns false if the gem does not export RBI files" do
        foo_gem = mock_gem("foo", "0.0.1")
        foo_spec = make_spec(foo_gem)
        refute(foo_spec.export_rbi_files?)
      end

      it "export_rbi_files? returns true if the gem exports at least one RBI file" do
        bar_gem = mock_gem("bar", "1.0.0")
        bar_gem.write("rbi/foo.rbi")
        bar_spec = make_spec(bar_gem)
        assert(bar_spec.export_rbi_files?)
      end

      it "exported_rbi_files returns an empty array if the gem does not export RBI files" do
        foo_gem = mock_gem("foo", "0.0.1")
        foo_spec = make_spec(foo_gem)
        assert_empty(foo_spec.exported_rbi_files)
      end

      it "exported_rbi_files returns the list of RBI files exported by the gem" do
        bar_gem = mock_gem("bar", "1.0.0")
        bar_gem.write("rbi/foo.rbi")
        bar_gem.write("rbi/bar.rbi")
        bar_spec = make_spec(bar_gem)
        bar_rbis = bar_spec.exported_rbi_files.map { |path| File.basename(path) }
        assert_equal(["bar.rbi", "foo.rbi"], bar_rbis)
      end

      it "creates an empty tree if the gem does not export RBI files" do
        foo_gem = mock_gem("foo", "0.0.1")
        foo_spec = make_spec(foo_gem)
        foo_tree = foo_spec.exported_rbi_tree
        assert_empty(foo_tree.conflicts)
        assert_empty(foo_tree)
      end

      it "creates a tree by merging all the RBI files exported by te gem" do
        foo_gem = mock_gem("foo", "0.0.1")

        foo_gem.write("rbi/foo.rbi", <<~RBI)
          # typed: true

          module Foo
            sig { void }
            def bar; end

            def foo(a = T.unsafe(nil), b = T.unsafe(nil)); end
          end
        RBI

        foo_gem.write("rbi/bar.rbi", <<~RBI)
          # typed: true

          module Foo
            def bar; end

            sig { params(a: T.nilable(Integer), b: T.nilable(Integer)).void }
            def foo(a = T.unsafe(nil), b = T.unsafe(nil)); end
          end
        RBI

        foo_spec = make_spec(foo_gem)
        foo_tree = foo_spec.exported_rbi_tree
        assert_empty(foo_tree.conflicts)
        assert_equal(<<~RBI, foo_tree.string)
          # typed: true

          module Foo
            sig { void }
            def bar; end

            sig { params(a: T.nilable(Integer), b: T.nilable(Integer)).void }
            def foo(a = T.unsafe(nil), b = T.unsafe(nil)); end
          end
        RBI
      end

      it "creates a tree with conflicts if the gem export RBI files with conflicting definitions" do
        foo_gem = mock_gem("foo", "0.0.1")

        foo_gem.write("rbi/foo.rbi", <<~RBI)
          # typed: true

          module Foo
            sig { params(a: T.nilable(Integer), b: T.nilable(Integer)).void }
            def foo(a = T.unsafe(nil), b = T.unsafe(nil)); end
          end
        RBI

        foo_gem.write("rbi/bar.rbi", <<~RBI)
          # typed: true

          module Foo
            sig { params(x: T.nilable(Integer)).void }
            def foo(x = T.unsafe(nil)); end
          end
        RBI

        foo_spec = make_spec(foo_gem)
        foo_tree = foo_spec.exported_rbi_tree
        assert_equal(["Conflicting definitions for `::Foo#foo(x)`"], foo_tree.conflicts.map(&:to_s))
        assert_equal(<<~RBI, foo_tree.string)
          # typed: true

          module Foo
            <<<<<<< left
            sig { params(x: T.nilable(Integer)).void }
            def foo(x = T.unsafe(nil)); end
            =======
            sig { params(a: T.nilable(Integer), b: T.nilable(Integer)).void }
            def foo(a = T.unsafe(nil), b = T.unsafe(nil)); end
            >>>>>>> right
          end
        RBI
      end
    end

    private

    sig { params(gem: MockGem).returns(Gemfile::GemSpec) }
    def make_spec(gem)
      mock = MockGemSpecification.new(gem.path)
      Gemfile::GemSpec.new(mock)
    end
  end

  class MockGemSpecification < ::Gem::Specification
    extend T::Sig
    extend T::Generic

    Elem = type_template

    sig { params(rel_path: String).void }
    def initialize(rel_path) # rubocop:disable Lint/MissingSuper
      @rel_path = rel_path
    end

    sig { returns(String) }
    def full_gem_path
      @rel_path
    end

    sig { returns(T::Array[String]) }
    def full_require_paths
      []
    end
  end
end
