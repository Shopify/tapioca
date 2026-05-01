# typed: strict
# frozen_string_literal: true

require "spec_helper"

module Tapioca
  module RBS
    class RewriterSpec < Minitest::Spec
      def described_class
        Tapioca::RBS::Rewriter
      end

      describe Tapioca::RBS::Rewriter do
        it "rewrites typed files with RBS signature comments" do
          source = <<~RUBY
            # typed: strict

            #: (String) -> Integer
            def parse(value)
              value.to_i
            end
          RUBY

          assert(described_class.rewrite?(source))
        end

        it "rewrites typed files with multiline RBS comments" do
          source = <<~RUBY
            # typed: strict

            #| (String,
            #|  Integer) -> String
            def format(value, count)
              value * count
            end
          RUBY

          assert(described_class.rewrite?(source))
        end

        it "skips typed files without RBS comments" do
          source = <<~RUBY
            # typed: strict

            def parse(value)
              value.to_i
            end
          RUBY

          refute(described_class.rewrite?(source))
        end

        it "skips files with RBS-looking comments but without a typed sigil" do
          source = <<~RUBY
            # frozen_string_literal: true

            #: (String) -> Integer
            def parse(value)
              value.to_i
            end
          RUBY

          refute(described_class.rewrite?(source))
        end
      end
    end
  end
end
