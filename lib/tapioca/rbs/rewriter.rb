# typed: strict
# frozen_string_literal: true

require "ruby-next/language/runtime"

# This module rewrites RBS comments back into Sorbet's signatures as the files are being loaded.
# This will allow `sorbet-runtime` to wrap the methods as if they were originally written with the `sig{}` blocks.
# This will in turn allow Tapioca to use this signatures to generate typed RBI files.

# We need to include `T::Sig` very early to make sure that the `sig` method is available since gems using RBS comments
# are unlikely to include `T::Sig` in their own classes.
Module.include(T::Sig)

module Tapioca
  module RBS
    # Transpiles RBS comments back into Sorbet's `sig{}` blocks
    class Rewriter < RubyNext::Language::Rewriters::Text
      NAME = "rbs_rewriter"

      #: (String source) -> String
      def rewrite(source)
        # Do not try to parse files that don't have RBS comments
        return source unless source =~ /^\s*#\s*typed: (ignore|false|true|strict|strong|__STDLIB_INTERNAL)/

        context.track!(self)
        Spoom::Sorbet::Sigs.rbs_to_rbi(source)
      end
    end
  end
end

RubyNext::Language.include_patterns.clear
RubyNext::Language.include_patterns << "**/*.rb"
RubyNext::Language.rewriters = [Tapioca::RBS::Rewriter]
