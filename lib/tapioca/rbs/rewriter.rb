# typed: strict
# frozen_string_literal: true

require "ruby-next/language/runtime"

module Tapioca
  module RBS
    # Transpiles RBS comments to sig blocks
    # These sig blocks are then used by the SorbetSignatures listener to generate RBI files with the correct format
    class Rewriter < RubyNext::Language::Rewriters::Text
      NAME = "rbs_rewriter"

      #: (String source) -> String
      def rewrite(source)
        rewritten = source.gsub("#: -> Bar") do |_match|
          context.track!(self)
          "extend T::Sig; sig { returns(Bar) }"
        end

        rewritten
      end
    end
  end
end

RubyNext::Language.include_patterns.clear # Includes tapioca's app/, lib/, spec/ folders
RubyNext::Language.include_patterns << "**/*.rb"
RubyNext::Language.rewriters = [Tapioca::RBS::Rewriter]
