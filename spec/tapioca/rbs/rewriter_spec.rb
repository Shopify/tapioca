# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module RBS
    class RewriterSpec < Minitest::Spec
      describe ".typed_file?" do
        it "returns true for supported typed sigils" do
          [
            "# typed: ignore",
            "# typed: false",
            "# typed: true",
            "# typed: strict",
            "# typed: strong",
            "# typed: __STDLIB_INTERNAL",
          ].each do |sigil|
            assert(Tapioca::RBS::Rewriter.typed_file?(sigil))
          end
        end

        it "returns false when the file is not typed" do
          refute(Tapioca::RBS::Rewriter.typed_file?("class Foo; end"))
        end
      end

      describe ".rewrite" do
        it "does not call the translator for typed files without RBS runtime rewrite syntax" do
          source = <<~RUBY
            # typed: true

            class Foo
              def foo; end
            end
          RUBY

          Spoom::Sorbet::Translate.stub(:rbs_comments_to_sorbet_sigs, ->(*) { flunk("translator should not run") }) do
            assert_equal(source, Tapioca::RBS::Rewriter.rewrite("foo.rb", source))
          end
        end

        it "returns nil for untyped files" do
          assert_nil(Tapioca::RBS::Rewriter.rewrite("foo.rb", "class Foo; end"))
        end

        it "calls the translator for typed files with RBS runtime rewrite syntax" do
          source = <<~RUBY
            # typed: true

            class Foo
              #: -> String
              def foo; end
            end
          RUBY

          Spoom::Sorbet::Translate.stub(:rbs_comments_to_sorbet_sigs, ->(rewritten_source, file:) {
            assert_equal(source, rewritten_source)
            assert_equal("foo.rb", file)
            "translated"
          }) do
            assert_equal("translated", Tapioca::RBS::Rewriter.rewrite("foo.rb", source))
          end
        end

        it "returns the original source when translation fails" do
          source = <<~RUBY
            # typed: true

            class Foo
              #: invalid
              def foo; end
            end
          RUBY

          Spoom::Sorbet::Translate.stub(:rbs_comments_to_sorbet_sigs, ->(*) {
            raise Spoom::Sorbet::Translate::Error, "invalid"
          }) do
            assert_equal(source, Tapioca::RBS::Rewriter.rewrite("foo.rb", source))
          end
        end
      end

      describe ".possible_rbs_runtime_rewrite_syntax?" do
        it "returns true for RBS signature comments" do
          assert(Tapioca::RBS::Rewriter.possible_rbs_runtime_rewrite_syntax?(<<~RUBY))
            # typed: true

            class Foo
              #: -> String
              def foo; end
            end
          RUBY
        end

        it "returns true for multiline RBS signature continuation comments" do
          assert(Tapioca::RBS::Rewriter.possible_rbs_runtime_rewrite_syntax?(<<~RUBY))
            # typed: true

            class Foo
              #: -> Array[
              #| String
              #| ]
              def foo; end
            end
          RUBY
        end

        it "returns true for supported RBS annotations" do
          Tapioca::RBS::Rewriter::RBS_ANNOTATION_MARKERS.each do |marker|
            assert(Tapioca::RBS::Rewriter.possible_rbs_runtime_rewrite_syntax?(<<~RUBY), marker)
              # typed: true

              #{marker}
              class Foo; end
            RUBY
          end
        end

        it "returns true for supported override annotations with options" do
          [
            "# @override(allow_incompatible: true)",
            "# @override(allow_incompatible: :visibility)",
          ].each do |marker|
            assert(Tapioca::RBS::Rewriter.possible_rbs_runtime_rewrite_syntax?(<<~RUBY), marker)
              # typed: true

              #{marker}
              def foo; end
            RUBY
          end
        end

        it "returns false for typed files without RBS runtime rewrite syntax" do
          refute(Tapioca::RBS::Rewriter.possible_rbs_runtime_rewrite_syntax?(<<~RUBY))
            # typed: true

            class Foo
              def foo; end
            end
          RUBY
        end

        it "returns false for unrelated YARD tags" do
          refute(Tapioca::RBS::Rewriter.possible_rbs_runtime_rewrite_syntax?(<<~RUBY))
            # typed: true

            # @param value [String]
            # @return [String]
            def foo(value); end
          RUBY
        end
      end
    end
  end
end
