# frozen_string_literal: true
# typed: false

require 'thor'

module Tapioca
  class Cli < Thor
    class_option :prerequire
    class_option :postrequire
    class_option :outdir, default: "sorbet/rbi/gems"

    desc "generate [gem...]", "generate RBIs from gems"
    def generate(*gems)
      generator.build_gem_rbis(gems)
    end

    desc "bundle", "sync RBIs to Gemfile"
    def bundle
      generator.sync_rbis_with_gemfile
    end

    no_commands do
      def generator
        @generator ||= Generator.new(
          outdir: options[:outdir],
          prerequire: options[:prerequire],
          postrequire: options[:postrequire],
        )
      end
    end
  end
end
