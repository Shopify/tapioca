# typed: strict
# frozen_string_literal: true

require "ruby-next/language/runtime"

module Tapioca
  module RBS
    class Rewriter < RubyNext::Language::Rewriters::Text
      NAME = "rbs_rewriter"

      def rewrite(source)
        puts source

        rewritten = source.gsub("#: -> Bar") do |_match|
          context.track!(self)
          "extend T::Sig; sig { returns(Bar) }"
        end

        puts rewritten

        rewritten
      end
    end
  end
end

RubyNext::Language.include_patterns.clear
RubyNext::Language.include_patterns << "**/foo.rb"
RubyNext::Language.rewriters = [Tapioca::RBS::Rewriter]
puts "INITIALIZED REWRITER"
