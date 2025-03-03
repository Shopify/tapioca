# typed: strict
# frozen_string_literal: true

module Tapioca
  module RBS
    class Rewriter < RubyNext::Language::Rewriters::Text
      # NAME = "RBS rewriter"
      # MIN_SUPPORTED_VERSION = Gem::Version.new(RubyNext::NEXT_VERSION)

      def rewrite(source)
        safe_rewrite(source).tap do |rewritten|
          context.track!(self) if rewritten != source
        end
      end

      def safe_rewrite(source)
        puts source

        source = source.gsub("#: -> Bar", "def qux; end; sig { returns(Bar) }")
        puts source
        # res
        source
      end
    end
  end
end

RubyNext::Language.include_patterns.clear
RubyNext::Language.include_patterns << "**/foo.rb"
RubyNext::Language.rewriters = [Tapioca::RBS::Rewriter]
puts "INITIALIZED REWRITER"
